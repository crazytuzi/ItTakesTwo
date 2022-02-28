import Cake.LevelSpecific.Garden.WaterHose.WaterHose;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseFeature;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseChargeWidget;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseAimWidget;
import Peanuts.Crosshair.WorldSpaceConstantSizeCircleWidget;

import Cake.LevelSpecific.Garden.Greenhouse.PaintablePlaneContainer;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;


UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking ComponentReplication Variable Tags AssetUserData Collision")
class UWaterHoseComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Water")
	TSubclassOf<AWaterHose> WaterHoseClass;

	UPROPERTY(EditDefaultsOnly, Category = "Water")
	ULocomotionFeatureWaterHose WaterHoseFeature;

	UPROPERTY(EditDefaultsOnly, Category = "Water|Widget")
	TSubclassOf<UWaterHoseAimWidget> AimWidget;

	UPROPERTY(EditDefaultsOnly, Category = "Water|Widget")
	FLinearColor FoundWaterComponentColor = FLinearColor::Blue;

	UPROPERTY(EditDefaultsOnly, Category = "Water")
	FCollisionProfileName WaterTraceCollisionProfile;

	// How big the the collision is where the water hits
	UPROPERTY(EditDefaultsOnly, Category = "Water")
	float SplashRadius = 150.f;

	// Offset direction to shoot in.
	UPROPERTY(EditDefaultsOnly, Category = "Water")
	FRotator ShootOffsetRotation = FRotator(10.f, 0.f, 0.f);

	// This is how fast the water will decend to the ground
	UPROPERTY(Category = "Water")
	float WaterGravityDefault = 4750.f;

	// This is how high the waterarc is going to be
	UPROPERTY(Category = "Water")
	FHazeMinMax WaterTrajectoryHeightDefault = FHazeMinMax(1.f, 400.f);

	UPROPERTY(Category = "Water")
	EHazeSimpleCustomLerpType WaterTrajectoryHeightLerpType = EHazeSimpleCustomLerpType::EaseIn;

	/* This is how far you can hit stuff in a straight line
	* If you dont find anything, the water till still travel longer.
	*/
	UPROPERTY(Category = "Water")
	float WaterShootLengthDefault = 6000.f;

	// The class the water projectile has
	UPROPERTY(EditDefaultsOnly, Category = "Water")
	TSubclassOf<AWaterHoseProjectile> WaterProjectileClass;

	// The class the water projectile has
	UPROPERTY(EditDefaultsOnly, Category = "Water|Effect")
	TSubclassOf<AWaterHoseProjectileImpactDecal> WaterImpactDecalClass;

	UPROPERTY(EditDefaultsOnly, Category = "Water")
	float DelayBetweenProjectiles = 1.f/15.f;

	// The amount of projectiles that the actor can have
	UPROPERTY(EditDefaultsOnly, Category = "Water")
	int MaxProjectiles = 60;

	UPROPERTY(Category = "Water")
	float MaxLifeTime = 1.f;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset AimCameraSettingsDefault;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bWaterHoseActive = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bShooting = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSickleIsEqipped = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector AimDirection = FVector::ZeroVector;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float AimValue = 0;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector WaterShootDirection = FVector::ZeroVector;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float WaterShootValue = 0;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AWaterHose WaterHose;

	AHazePlayerCharacter Player;
	FHitResult LastWaterHit;
	uint LastWaterImpactFrame;
	FVector WantedTargetLocation;
	FVector WaterVelocity;
	float WaterLifeTime = 0;

	UWorldSpaceConstantSizeCircleWidget CreatedWaterImpactWidget;
	UWaterHoseAimWidget CurrentWidget;
	FOnWaterHoseProjectileImpact OnWaterProjectileStealthZoneImpact;

	UPROPERTY(Transient, NotEditable)
	TArray<AWaterHoseProjectile> WaterProjectiles;
	TArray<AWaterHoseProjectile> ActiveWaterProjectiles;
	TArray<AWaterHoseProjectile> ProjectilesToImpactTest;
	TArray<AActor> WaterTraceIgnoreActors;

	int ActiveWaterProjectileIndex = 0;
	int LastWaterIndex = -1;
	private int CurrentActiveWaterProjectileCount = 0;
	bool bNextWaterIndexIsParent = false;
	int NoneParentActivation = 0;

	UPROPERTY(Transient, NotEditable)
 	TArray<AWaterHoseProjectileImpactDecal> AvailableWaterDecals;

	UPROPERTY(Transient, NotEditable)
 	TArray<AWaterHoseProjectileImpactDecal> WaterDecalsInUse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		
		WaterHose = Cast<AWaterHose>(SpawnPersistentActor(WaterHoseClass));
		WaterHose.MakeNetworked(this, n"MaysWaterHose");
		WaterHose.AttachToComponent(Player.RootComponent);
		WaterHose.WaterSpawnEffect.SetVisibility(false);

		Player.Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPlayerAnimationUpdate");
		Player.OnHiddenInGameStatusChanged.AddUFunction(this, n"OnHiddenInGameStatusChanged");

		// Initialize the water projectiles
		if(WaterProjectileClass.IsValid())
		{
			FOnWaterHoseProjectileImpact OnImpact;
			OnImpact.AddUFunction(this, n"OnWaterProjectileImpact");

			WaterProjectiles.Reserve(MaxProjectiles);

			// Create all the projectiles
			for(int i = 0; i < MaxProjectiles; ++i)
			{			
				auto Projectile = Cast<AWaterHoseProjectile>(SpawnPersistentActor(WaterProjectileClass));
				Projectile.OnWaterImpact = OnImpact;
				Projectile.DisableActor(nullptr);
				Projectile.ArrayIndex = i;
				WaterProjectiles.Add(Projectile);
				WaterTraceIgnoreActors.Add(Projectile);
			}
		}

		if(WaterImpactDecalClass.IsValid())
		{
			const int MaxDecals = 20;
			AvailableWaterDecals.Reserve(MaxDecals);
			for(int i = 0; i < MaxDecals; ++i)
			{
				auto Decal = Cast<AWaterHoseProjectileImpactDecal>(SpawnPersistentActor(WaterImpactDecalClass));
				Decal.DisableActor(nullptr);
				Decal.DecalComponent.OnFadedOut.AddUFunction(this, n"DeactivateDecal");
				AvailableWaterDecals.Add(Decal);
			}
		}

		// Setup Widget
		if(AimWidget.IsValid())
		{
			CurrentWidget = Cast<UWaterHoseAimWidget>(Player.AddWidget(AimWidget));	
			CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);
		}

		Player.AddLocomotionFeature(WaterHoseFeature);
		WaterTraceIgnoreActors.Add(Player);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Player.Mesh.OnPostAnimEvalComplete.UnbindObject(this);
		Player.RemoveLocomotionFeature(WaterHoseFeature);

		if(WaterHose != nullptr)
		{
			WaterHose.DetachFromActor();
			WaterHose.DestroyActor();
			WaterHose = nullptr;
		}

		if(CurrentWidget != nullptr)
		{
			CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);
			Player.RemoveWidget(CurrentWidget);
			CurrentWidget = nullptr;
		}


		for(auto Projectile : WaterProjectiles)
		{
			if(Projectile != nullptr)
				Projectile.DestroyActor();
		}
		WaterProjectiles.Empty();

		for(auto Decal : AvailableWaterDecals)
		{
			if(Decal != nullptr)
				Decal.DestroyActor();
		}
		AvailableWaterDecals.Empty();

		Player.OnHiddenInGameStatusChanged.UnbindObject(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerAnimationUpdate(UHazeSkeletalMeshComponentBase PlayerMesh)
	{
		if(WaterHose != nullptr)
		{
			FTransform AttachBoneTransform = PlayerMesh.GetSocketTransform(n"BackPack");
			WaterHose.GunMesh.SetWorldLocationAndRotation(AttachBoneTransform.Location, AttachBoneTransform.Rotation);
		}
	}

	// Called everytime a new projetile leaves the muzzle
	UFUNCTION(BlueprintEvent)
    void OnWaterProjectilesSpawned(AWaterHoseProjectile Projectile)
    {
    }

	FHazeTraceParams GetProjectileTrace()
	{
		FHazeTraceParams OutParams;
		OutParams.InitWithCollisionProfile(WaterTraceCollisionProfile);
		OutParams.SetToLineTrace();
		OutParams.IgnoreActor(Player);
		OutParams.IgnoreActors(WaterTraceIgnoreActors);
		AActor Parent = Player.GetAttachParentActor();
		if(Parent != nullptr)
		{
			OutParams.IgnoreActor(Parent);
		}
		return OutParams;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHiddenInGameStatusChanged(AHazeActor ThisPlayer, bool bHidden)
	{
		WaterHose.SetActorHiddenInGame(bHidden);
	}

	// This function needs to happen on both sides
	void ActivateNextProjectile(float CurrentDelayToNextShot, FVector WorldUp, FVector PlayerVelocity)
	{
		if(bNextWaterIndexIsParent || NoneParentActivation >= 10)
		{
			bNextWaterIndexIsParent = false;
			LastWaterIndex = -1;
			NoneParentActivation = 0;
		}
		else
		{
			LastWaterIndex = ActiveWaterProjectileIndex;
			NoneParentActivation++;
		}

		ActiveWaterProjectileIndex++;
		if(ActiveWaterProjectileIndex >= WaterProjectiles.Num())
			ActiveWaterProjectileIndex = 0;

		AWaterHoseProjectile Projectile = WaterProjectiles[ActiveWaterProjectileIndex];
		if(Projectile.bIsMoving)
		{
			DeactivateProjectile(Projectile);
		}

		// We move the actor with the amount that the frame has moved it
		FVector InitialLocation = GetNozzleExitPoint();
	
		Projectile.SetActorLocationAndRotation(InitialLocation, Player.ViewRotation);
		Projectile.WorldUp = WorldUp;
		Projectile.GravityMagnitude = FMath::Abs(WaterGravity);
		Projectile.bIsMoving = true;
		Projectile.CurrentLifeTimeLeft = WaterLifeTime;
		Projectile.EnableActor(nullptr);
		//Projectile.WaterEffect.ReinitializeSystem();
		Projectile.Velocity = WaterVelocity;
		Projectile.PlayerVelocity = PlayerVelocity;
		Projectile.ParentIndex = LastWaterIndex;
		if(Projectile.ParentIndex < 0)
			ProjectilesToImpactTest.Add(Projectile);
		ActiveWaterProjectiles.Add(Projectile);
		CurrentActiveWaterProjectileCount++;

		// we need to update the amount of the projectile that we missed in the delta time so they keep the same distance
		const float BonusTime = FMath::Abs(FMath::Min(CurrentDelayToNextShot, 0.f));
		Projectile.UpdateProjectile(BonusTime);
		Projectile.LastWorldPosition = InitialLocation;

		OnWaterProjectilesSpawned(Projectile);

		const float Alpha = FMath::Min(WaterVelocity.Size() / 9000.f, 1.f);
		const FVector NewSize = FMath::Lerp(Projectile.OriginalScale * 0.2f, Projectile.OriginalScale, Alpha);
		Projectile.Mesh.SetRelativeScale3D(FVector(Projectile.OriginalScale.X, Projectile.OriginalScale.Y, NewSize.Z));
	}

	void DeactivateProjectile(AWaterHoseProjectile Projectile)
	{
		if(Projectile != nullptr && Projectile.bIsMoving)
		{
			Projectile.bIsMoving = false;
			Projectile.DisableActor(nullptr);
			//Projectile.WaterEffect.Deactivate();
			CurrentActiveWaterProjectileCount--;
			ActiveWaterProjectiles.RemoveSwap(Projectile);
		}	
	}

	int GetActiveWaterProjectileAmount() const property
	{
		return CurrentActiveWaterProjectileCount;
	}

	void SetWaterHoseOutline(bool bShow)
	{
		if (bShow)
			WaterHose.GunMesh.AddMeshToPlayerOutline(Player, this);
		else
			RemoveMeshFromPlayerOutline(WaterHose.GunMesh, this);
	}

	UFUNCTION(BlueprintPure)
	FVector GetNozzleExitPoint() const property
	{
		return WaterHose.Muzzle.GetWorldLocation();
	}

	UFUNCTION()
	bool GetImpactLocation(FVector& Out) const property
	{
		if(!LastWaterHit.bBlockingHit)
			return false;

		Out = LastWaterHit.ImpactPoint;
		return true;
	}

	UFUNCTION()
	bool GetImpactActorLocation(AActor& OutActor, FVector& OutPosition) const
	{
		if(!LastWaterHit.bBlockingHit)
			return false;

		OutPosition = LastWaterHit.ImpactPoint;
		OutActor = LastWaterHit.Actor;
		return true;
	}

	bool GetImpactActorLocationWithFrame(AActor& OutActor, FVector& OutPosition, uint& OutLastFrameHit) const
	{
		if(!LastWaterHit.bBlockingHit)
			return false;

		OutPosition = LastWaterHit.ImpactPoint;
		OutActor = LastWaterHit.Actor;
		OutLastFrameHit = LastWaterImpactFrame;
		return true;
	}

	private float InternalCustomGravity = -1;
	UFUNCTION()
	void SetCustomGravity(float Amount) property
	{
		InternalCustomGravity = Amount;
	}

	float GetWaterGravity() const property
	{
		if(InternalCustomGravity >= 0)
			return InternalCustomGravity;

		return WaterGravityDefault;
	}

	private float InternalMaxHeight = -1;
	UFUNCTION()
	void SetCustomMaxHeight(float Amount) property
	{
		InternalMaxHeight = Amount;
	}

	FHazeMinMax GetWaterTrajectoryHeight() const property
	{
		if(InternalMaxHeight >= 0)
			return FHazeMinMax(WaterTrajectoryHeightDefault.Min, InternalMaxHeight);

		return WaterTrajectoryHeightDefault;
	}

	private float InternalShootLength = -1;
	UFUNCTION()
	void SetCustomShootLength(float Amount) property
	{
		InternalShootLength = Amount;
	}

	float GetWaterShootLength() const property
	{
		if(InternalShootLength >= 0)
			return InternalShootLength;

		return WaterShootLengthDefault;
	}


	private UHazeCameraSpringArmSettingsDataAsset CustomCameraDataAsset;
	UFUNCTION()
	void SetCustomAimCameraSettings(UHazeCameraSpringArmSettingsDataAsset SpingArmAsset)
	{
		CustomCameraDataAsset = SpingArmAsset;
	}

	UHazeCameraSpringArmSettingsDataAsset GetAimCameraSettings() const property
	{
		if(CustomCameraDataAsset != nullptr)
			return CustomCameraDataAsset;

		return AimCameraSettingsDefault;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnWaterProjectileImpact(AWaterHoseProjectile Projectile, FHitResult Impact)
	{
		LastWaterHit = Impact;
		LastWaterImpactFrame = Time::GetFrameNumber();
		OnWaterProjectileStealthZoneImpact.Broadcast(Projectile, Impact);
		Projectile.OnDestroyedFromImpact(Impact);

		Player.SetCapabilityActionState(n"AudioHandleWaterImpact", EHazeActionState::Active);
		
		if(Impact.bBlockingHit)
		{
			FRotator EffectRotation;

			FVector DirToPlayer = (Owner.GetActorLocation() - Projectile.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			const float ImpactDegree = FMath::RadiansToDegrees(Impact.ImpactNormal.DotProduct(FVector::ForwardVector));
			if(ImpactDegree > Projectile.ImpactNoRotationAngle)
				EffectRotation = Math::MakeRotFromZX(Impact.ImpactNormal, DirToPlayer);
			else
				EffectRotation = Math::MakeRotFromZX(FVector::UpVector, DirToPlayer);
			
			// Hacky way to get a different effect when painting on goop.
			bool UseLargeGoopSplashEffect = false;
			APaintablePlane GoopPlane;
			APaintablePlaneContainer PaintablePlaneContainer = Cast<APaintablePlaneContainer>(Impact.Actor);
			if(PaintablePlaneContainer != nullptr && PaintablePlaneContainer.PaintablePlane != nullptr)
			{
				GoopPlane = PaintablePlaneContainer.PaintablePlane;
				UseLargeGoopSplashEffect = PaintablePlaneContainer.UseLargeGoopSplashEffect;
			}
			ASubmersibleSoilPlantSprayer SeedSprayer = Cast<ASubmersibleSoilPlantSprayer>(Impact.Actor);
			if(SeedSprayer != nullptr && SeedSprayer.GoopPlane != nullptr)
			{
				GoopPlane = SeedSprayer.GoopPlane;
			}
			
			UNiagaraSystem ImpactEffect = Projectile.ImpactEffect;
			if(GoopPlane != nullptr && !GoopPlane.QueryData(Impact.ImpactPoint).bHasBeenPainted)
			{
				if(UseLargeGoopSplashEffect)
					ImpactEffect = Projectile.ImpactEffect_SapWall;
				else
					ImpactEffect = Projectile.ImpactEffect_Goop;
			}
			else
			{
			}

			if(ImpactEffect != nullptr)
				Niagara::SpawnSystemAtLocation(ImpactEffect, Impact.ImpactPoint, EffectRotation, ENCPoolMethod::AutoRelease);

			// Local impact handling
			if(Impact.Actor != nullptr)
			{
				FVector UpVector = Impact.Normal;
				if(!UpdateCurrentWaterDecalsFromImpact(Impact.Location))
				{
					if(AvailableWaterDecals.Num() > 0)
					{
						// we add a new decal on the ground
						EnableAvailableDecal(Impact.Location + UpVector, UpVector);
					}
					else
					{
						// we move the oldest decal to the new location
						ReEnableInUseArray(Impact.Location + UpVector, UpVector);
					}
				}
				
				UWaterHoseImpactComponent WaterHoseImpactComp = UWaterHoseImpactComponent::Get(Impact.Actor);
				if(WaterHoseImpactComp != nullptr)
				{
					if(WaterHoseImpactComp.ValidateImpact(Impact.Component))
						WaterHoseImpactComp.OnWaterProjectileImpact.Broadcast(Impact);
				}
			}

			if(HasControl())
			{
				TArray<FOverlapResult> FoundOverlaps;
				FHazeTraceParams OverlapTrace = GetProjectileTrace();
				OverlapTrace.SetToSphere(SplashRadius);
				Projectile.GetWaterOverlaps(OverlapTrace, Impact, FoundOverlaps);
				
				// Loop the collision and make them want to fill water
				for(FOverlapResult Overlap : FoundOverlaps)
				{
					if(Overlap.Actor == nullptr)
						continue;

					UWaterHoseImpactComponent OverlappingWaterHoseImpactComp = UWaterHoseImpactComponent::Get(Overlap.Actor);
					if(OverlappingWaterHoseImpactComp == nullptr)
						continue;

					if(!OverlappingWaterHoseImpactComp.ValidateImpact(Overlap.Component))
						continue;

					// A little bit of margin to the next possible impact
					OverlappingWaterHoseImpactComp.BeginHitByWater(DelayBetweenProjectiles * 20.f);	
				}
			}
		}

		DeactivateProjectile(Projectile);
	}

	bool UpdateCurrentWaterDecalsFromImpact(FVector ImpactLocation)
	{
		for(auto Decal : WaterDecalsInUse)
		{
			if(ImpactLocation.DistSquared(Decal.GetActorLocation()) > FMath::Square(Decal.RetriggerImpactRadius))
				continue;

			// Retrigger the effect
			Decal.OnStartAndShowEffect(true);
			return true;
		}

		return false;
	}

	void EnableAvailableDecal(FVector Location, FVector UpVector)
	{
		const int Index = AvailableWaterDecals.Num() - 1;
		auto Decal = AvailableWaterDecals[Index];
		AvailableWaterDecals.RemoveAtSwap(Index);
		Decal.SetActorLocationAndRotation(Location, FRotator::MakeFromZ(UpVector));
		Decal.DecalComponent.AddRelativeRotation(FRotator(0.f, 0.f, FMath::RandRange(0.f, 360.f)));
		Decal.EnableActor(nullptr);
		Decal.OnStartAndShowEffect(false);
		WaterDecalsInUse.Add(Decal);
	}

	void ReEnableInUseArray(FVector Location, FVector UpVector)
	{
		int BestIndex = -1;
		float BestGameTime = -1;

		// Find the oldest decal and re-use that
		for(int i = 0; i < WaterDecalsInUse.Num(); ++i)
		{
			const float ActiveDuration = Time::GetGameTimeSince(WaterDecalsInUse[i].ActivationGameTime);
			if(ActiveDuration < BestGameTime)
				continue;
				
			BestGameTime = ActiveDuration;
			BestIndex = i;
		}

		if(BestIndex < 0)
			return;

		auto Decal = WaterDecalsInUse[BestIndex];
		Decal.SetActorLocationAndRotation(Location, FRotator::MakeFromZ(UpVector));
		Decal.DecalComponent.AddRelativeRotation(FRotator(0.f, 0.f, FMath::RandRange(0.f, 360.f)));
		Decal.OnStartAndShowEffect(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void DeactivateDecal(UHazeDecalComponent DecalComp)
	{
		auto Decal = Cast<AWaterHoseProjectileImpactDecal>(DecalComp.Owner);
		if(Decal == nullptr)
			return;

		if(!Decal.bIsShowingEffect)
			return;

		Decal.OnEndAndHideEffect();
		WaterDecalsInUse.RemoveSwap(Decal);
		Decal.DisableActor(nullptr);
		AvailableWaterDecals.Add(Decal);
	}
}