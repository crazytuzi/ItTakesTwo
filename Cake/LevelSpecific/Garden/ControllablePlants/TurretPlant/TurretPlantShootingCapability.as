import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;
import Cake.Weapons.Recoil.RecoilComponent;
import Cake.Weapons.RangedWeapon.RangedWeapon;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

struct FTurretPlantBulletReplicationInfo
{
	FVector ImpactPoint;
	FVector ImpactNormal;
	UAkAudioEvent AudioEvent = nullptr;	// Maybe we can get this somehow from the component instead?
	UPrimitiveComponent HitComponent = nullptr;
}

class UTurretPlantShootingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 8;
	
	ATurretPlant TurretPlant;
	URangedWeaponComponent RangedWeapon;
	URecoilComponent Recoil;
	UHazeCrumbComponent CrumbComp;
	UArrowComponent CurrentNozzle;
	UCameraShakeBase CameraShakeHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
		RangedWeapon = URangedWeaponComponent::Get(Owner);
		Recoil = URecoilComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		CurrentNozzle = TurretPlant.LeftProjectileSpawnPoint;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TurretPlant.bIsReloading)
			return EHazeNetworkActivation::DontActivate;

		if(!TurretPlant.HasEnoughAmmoToShoot())
			return EHazeNetworkActivation::DontActivate;

		if(!TurretPlant.bWantsToShoot)
			return EHazeNetworkActivation::DontActivate;

		if(!TurretPlant.CanStartShooting())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TurretPlant.bIsShooting = true;
		RangedWeapon.bFireButtonDown = true;

		if(TurretPlant.ShootingCameraShake.IsValid())
		{
			CameraShakeHandle = TurretPlant.OwnerPlayer.PlayCameraShake(TurretPlant.ShootingCameraShake);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TurretPlant.bIsShooting = false;
		RangedWeapon.bFireButtonDown = false;

		if(CameraShakeHandle != nullptr)
		{
			TurretPlant.OwnerPlayer.StopCameraShake(CameraShakeHandle, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TurretPlant.bIsReloading)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!TurretPlant.HasEnoughAmmoToShoot())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!TurretPlant.bWantsToShoot)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!TurretPlant.CanStartShooting())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(RangedWeapon.CanFire())
		{
			Fire();
		}
	}

	private void Fire()
	{
		UArrowComponent PredictedNextNozzle = (CurrentNozzle == TurretPlant.LeftProjectileSpawnPoint ? TurretPlant.RightProjectileSpawnPoint : TurretPlant.LeftProjectileSpawnPoint);

		FVector TraceStartLoc = TurretPlant.Camera.ViewLocation;
		FVector TraceEndLoc = TurretPlant.Camera.ViewLocation + (TurretPlant.Camera.ViewRotation.GetForwardVector() * 25000.0f);

		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(TurretPlant);

		if(System::LineTraceSingle(TraceStartLoc, TraceEndLoc, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false))
		{
			TraceEndLoc = Hit.Location;
		}

		const FVector DirectionFromArm = (TraceEndLoc - CurrentNozzle.WorldLocation).GetSafeNormal();		
		FHazeDelegateCrumbParams CrumbParams;
		
		Hit.Reset();
		TurretPlant.RangedWeapon.Fire(Hit, CurrentNozzle.WorldLocation, DirectionFromArm);
		FTurretPlantBulletReplicationInfo BulletReplicationInfo;

		if(Hit.bBlockingHit)
		{
			if(Hit.PhysMaterial != nullptr && Hit.PhysMaterial.AudioAsset != nullptr)
			{
				UPhysicalMaterialAudio PhysMatAudio = Cast<UPhysicalMaterialAudio>(Hit.PhysMaterial.AudioAsset);
				if(PhysMatAudio != nullptr)
				{
					BulletReplicationInfo.AudioEvent = PhysMatAudio.GetImpactEvent(n"TurretPlantImpact");
				}
			}
				
			Owner.SetCapabilityAttributeVector(n"TurretPlantBulletImpact", Hit.ImpactPoint);
		}
		
		BulletReplicationInfo.HitComponent = Hit.Component;
		BulletReplicationInfo.ImpactPoint = TraceEndLoc;
		BulletReplicationInfo.ImpactNormal = Hit.ImpactNormal;

		CrumbParams.AddStruct(n"BulletReplicationInfo", BulletReplicationInfo);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_HandleFireWeapon"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_HandleFireWeapon(const FHazeDelegateCrumbData& CrumbData)
	{
		if(TurretPlant.CrosshairWidget != nullptr)
		{
			TurretPlant.CrosshairWidget.BP_OnFire();
		}

		const FVector StartLocation = CurrentNozzle.WorldLocation;

		FTurretPlantBulletReplicationInfo BulletReplicationInfo;
		CrumbData.GetStruct(n"BulletReplicationInfo", BulletReplicationInfo);

		if(!HasControl())
		{
			RangedWeapon.Fire_ReplicatedHit(StartLocation, BulletReplicationInfo.ImpactPoint, BulletReplicationInfo.ImpactNormal, BulletReplicationInfo.HitComponent);
		}
		
		if (TurretPlant.bRightHandSpawnLocation)
		{
			CurrentNozzle = TurretPlant.RightProjectileSpawnPoint;
			TurretPlant.ShootRight();
		}
		else
		{
			CurrentNozzle = TurretPlant.LeftProjectileSpawnPoint;
			TurretPlant.ShootLeft();
		}



		//const FVector StartLocation = CrumbData.GetVector(n"StartLocation");
		//const FVector EndLocation = CrumbData.GetVector(n"EndLocation");
		const FVector ForwardDirection = (BulletReplicationInfo.ImpactPoint - StartLocation).GetSafeNormal();
		//FHitResult Hit;
		//TurretPlant.RangedWeapon.Fire(Hit, StartLocation, ForwardDirection);
		const FVector MayLoc = Game::GetMay().ActorLocation;
		const FVector BulletWhizLoc = Math::ProjectPointOnInfiniteLine(StartLocation, ForwardDirection, MayLoc);

		// This is for audio
		Owner.SetCapabilityAttributeVector(n"TurretPlantWhizLocation", BulletWhizLoc);
		Owner.SetCapabilityAttributeVector(n"TurretPlantFireLocation", StartLocation);

		if(BulletReplicationInfo.HitComponent != nullptr)
		{
			Owner.SetCapabilityAttributeVector(n"TurretPlantBulletImpact", BulletReplicationInfo.ImpactPoint);

			if(BulletReplicationInfo.AudioEvent != nullptr)
				Owner.SetCapabilityAttributeObject(n"TurretPlantImpactEvent", BulletReplicationInfo.AudioEvent);
		}
/*
		if(Hit.bBlockingHit)
		{
			if(Hit.PhysMaterial != nullptr && Hit.PhysMaterial.AudioAsset != nullptr)
			{
				UPhysicalMaterialAudio PhysMatAudio = Cast<UPhysicalMaterialAudio>(Hit.PhysMaterial.AudioAsset);
				if(PhysMatAudio != nullptr)
				{
					UAkAudioEvent AudioEvent = PhysMatAudio.GetImpactEvent(n"TurretPlantImpact");

					if(AudioEvent != nullptr)
						Owner.SetCapabilityAttributeObject(n"TurretPlantImpactEvent", AudioEvent);
				}
			}
				
			Owner.SetCapabilityAttributeVector(n"TurretPlantBulletImpact", Hit.ImpactPoint);
		}*/

		//System::DrawDebugSphere(ProjLoc, 20.0f, 12, FLinearColor::Green, 1.0f);

		TurretPlant.UpdateSpikeAnimation();
	}
}
