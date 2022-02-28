import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantTags;

class UTurretPlantShootSeedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ATurretPlant TurretPlant;
	UArrowComponent CurrentNozzle;

	bool bRightHandSpawnLocation = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
		CurrentNozzle = TurretPlant.LeftProjectileSpawnPoint;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TurretPlant.bIsShooting)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!TurretPlant.HasEnoughAmmoToShoot())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!IsActioning(TurretPlantTags::ShootSeed))
		{
			return EHazeNetworkActivation::DontActivate;
		}

        //return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.DisableTransformSynchronization();

		UArrowComponent PredictedNextNozzle = (CurrentNozzle == TurretPlant.LeftProjectileSpawnPoint ? TurretPlant.RightProjectileSpawnPoint : TurretPlant.LeftProjectileSpawnPoint);

		FVector TraceStartLoc = TurretPlant.Camera.ViewLocation;
		FVector TraceEndLoc = TurretPlant.Camera.ViewLocation + (TurretPlant.Camera.ViewRotation.GetForwardVector() * 100000.0f);

		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(TurretPlant);

		if(System::LineTraceSingle(TraceStartLoc, TraceEndLoc, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false))
		{
			TraceEndLoc = Hit.Location;
		}

		const FVector DirectionToLook = (TraceEndLoc - CurrentNozzle.WorldLocation).GetSafeNormal();
		ActivationParams.AddVector(n"FacingDirection", DirectionToLook);

		TraceStartLoc = TurretPlant.GetProjectileSpawnLocation(TurretPlant.CurrentSocketName) * (DirectionToLook * 200.0f);
		ActivationParams.AddVector(n"SpawnLocation", CurrentNozzle.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
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

		const FVector SpawnLocation = ActivationParams.GetVector(n"SpawnLocation");
		const FVector FacingDirection = ActivationParams.GetVector(n"FacingDirection");

		FHitResult Hit;
		TurretPlant.RangedWeapon.Fire(Hit, SpawnLocation, FacingDirection);
		TurretPlant.UpdateSpikeAnimation();

		Owner.SetCapabilityActionState(n"ShotSeed", EHazeActionState::ActiveForOneFrame);
		

		if(TurretPlant.BulletForceFeedback != nullptr)
		{
			TurretPlant.OwnerPlayer.PlayForceFeedback(TurretPlant.BulletForceFeedback, false, false, n"TurretPlantShoot");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}



#if !RELEASE

// Debug draw
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(CVar_TurretPlantDebugDraw.GetInt() == 1)
		{
			const FVector RightHandLocation = TurretPlant.GetProjectileSpawnLocation(n"RightHand");
			const FVector LeftHandLocation = TurretPlant.GetProjectileSpawnLocation(n"LeftHand");

			//System::DrawDebugSphere(RightHandLocation, 60.0f, 12, FLinearColor::Green, DeltaTime * 2.0f);
			//System::DrawDebugSphere(LeftHandLocation, 60.0f, 12, FLinearColor::Green, DeltaTime * 2.0f);
		}
	}
#endif // !RELEASE
}
