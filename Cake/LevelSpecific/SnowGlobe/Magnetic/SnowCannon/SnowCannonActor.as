import Vino.Trajectory.TrajectoryDrawer;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetSnowCanonComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.MagneticSnowProjectile;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Peanuts.Audio.AudioStatics;

import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnActivationEvent();
event void FOnThumperCockEvent();
event void FOnCooldownStartedEvent();
event void FOnCooldownCompletedEvent();
event void FOnShootEvent();
event void FOnReloadStartedEvent();
event void FOnReloadCompletedEvent();

USTRUCT()
struct FSnowCannonFloatRange
{
	UPROPERTY()
	float Min;

	UPROPERTY()
	float Max;

	float ClampValue(float Value)
	{
		return FMath::Clamp(Value, Min, Max);
	}

	bool IsInRange(float Value)
	{
		return Value > Min && Value < Max;
	}
}

UCLASS(Abstract)
class ASnowCannonActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent AimRail;

	UPROPERTY(DefaultComponent, Attach = AimRail)
	UStaticMeshComponent Thumper;

	UPROPERTY(DefaultComponent, Attach = AimRail)
	UPoseableMeshComponent LeftSpring;

	UPROPERTY(DefaultComponent, Attach = Thumper)
	USceneComponent LeftSpringAttach;

	UPROPERTY(DefaultComponent, Attach = Thumper)
	USceneComponent AmmoAttach;

	UPROPERTY(DefaultComponent, Attach = AimRail)
	UArrowComponent ShootLocation;


	// Holds transform info for start of reload animation
	UPROPERTY(DefaultComponent, Attach = Base)
	USceneComponent ReloadStart;
	default ReloadStart.SetRelativeLocation(FVector(0.f, 0.f, -545.f));


	UPROPERTY(DefaultComponent, Attach = Thumper)
	UMagnetSnowCanonComponent MagneticComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent Crosshair;
	default Crosshair.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Crosshair)
	UStaticMeshComponent CrosshairMesh;
	default CrosshairMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;	

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY()
	FSnowCannonFloatRange YawConstraints;
	default YawConstraints.Min = -112.f;
	default YawConstraints.Max = 82.f;

#if EDITOR
	private UArrowComponent MinYawArrowComponent;
	private UArrowComponent MaxYawArrowComponent;
#endif

	// Cody is owner since he shoots projectiles
	UPROPERTY(meta = (EditCondition = "false"))
	EHazePlayer OwningPlayer = EHazePlayer::Cody;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface RedMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CrosshairCooldownMaterial;

	UPROPERTY()
	bool bIsPositive;

	UPROPERTY()
	bool bActivated = false;
	
	UPROPERTY()
	float ProjectileSpeed = 12500.0f;

	UPROPERTY()
	float CooldownDuration = 0.95f;
	const float ThumperShootAccelerationDuration = 0.05f;
	const float ThumperChargeAccelerationDuration = 0.4f;

	bool bThumperCocked;

	UPROPERTY()
	float ProjectileGravity = 4000;

	float ThumperOriginalX;
	float AddedX = -160.f;


	UPROPERTY(Category = "Reload")
	private UStaticMesh FakeMagnetProjectileMesh;
	UStaticMeshComponent FakeMagnetProjectile;

	UPROPERTY(Category = "Reload")
	UMaterialInterface FakeMagnetProjectileOffMaterial;


	UPROPERTY(NotEditable)
	TArray<AMagneticSnowProjectile> ContainedProjectiles;

	UPROPERTY(NotEditable)
	TArray<AMagnetBasePad> ContainedBasePads;

	UPROPERTY()
	int NumberOfSpawnableBasePads = 20;

	UPROPERTY()
	int NumberOfContainedProjectiles = 10;

	UPROPERTY()
    TSubclassOf<AMagnetBasePad> BasePadClass;
	
	UPROPERTY()
    TSubclassOf<AMagneticSnowProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<UShotBySnowCannonComponent> ShotBySnowCannonComponentClass;

	UPROPERTY()
	TSubclassOf<UHazeCapability> MagnetSlideCapabilityClass;


	UPROPERTY(Category = "VFX")
	UNiagaraSystem CannonShotEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem IceWallAttachEffect;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem ProjectileExplosionEffect;


	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect ShootRumble;

	UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> PlayerDeathEffect;


	// Event stuff
	UPROPERTY()
	FOnActivationEvent OnActivated;

	UPROPERTY()
	FOnActivationEvent OnDeactivated;

	UPROPERTY()
	FOnThumperCockEvent OnThumperCockStarted;

	UPROPERTY()
	FOnThumperCockEvent OnThumperCocked;

	UPROPERTY()
	FOnShootEvent OnShoot;

	UPROPERTY()
	FOnCooldownStartedEvent OnCooldownStarted;

	UPROPERTY()
	FOnCooldownCompletedEvent OnCooldownCompleted;

	UPROPERTY()
	FOnReloadStartedEvent OnReloadStarted;

	UPROPERTY()
	FOnReloadCompletedEvent OnReloadCompleted;


	AHazePlayerCharacter ControllingPlayer;

	float CooldownTimer = 0.0f;
	bool bInCooldown = false;

	bool bValidAimTarget;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bIsPositive)
		{
			Thumper.SetMaterial(2, RedMaterial);
			MagneticComponent.Polarity = EMagnetPolarity::Plus_Red;
		}
		else
		{
			Thumper.SetMaterial(2, BlueMaterial);
			MagneticComponent.Polarity = EMagnetPolarity::Minus_Blue;
		}

		UpdateSpringLocation();

#if EDITOR
		MinYawArrowComponent = UArrowComponent::GetOrCreate(this, n"MinYawArrow");
		MinYawArrowComponent.SetRelativeLocation(FVector(0.f, 0.f, -500.f));
		MinYawArrowComponent.SetWorldScale3D(FVector(1.25f, 0.5f, 0.5f));
		MinYawArrowComponent.SetRelativeRotation(FRotator(0, YawConstraints.Min, 0.f));
		MinYawArrowComponent.ArrowSize = 15.f;

		MaxYawArrowComponent = UArrowComponent::GetOrCreate(this, n"MaxYawArrow");
		MaxYawArrowComponent.SetRelativeLocation(FVector(0.f, 0.f, -500.f));
		MaxYawArrowComponent.SetWorldScale3D(FVector(1.25f, 0.5f, 0.5f));
		MaxYawArrowComponent.SetRelativeRotation(FRotator(0, YawConstraints.Max, 0.f));
		MaxYawArrowComponent.ArrowSize = 15.f;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter OwningPlayerCharacter = Game::GetPlayer(OwningPlayer);

		SetControlSide(OwningPlayerCharacter);

		CrosshairMesh.SetRenderedForPlayer(OwningPlayerCharacter, true);
		CrosshairMesh.SetRenderedForPlayer(OwningPlayerCharacter.OtherPlayer, false);

		ThumperOriginalX = Thumper.RelativeLocation.X;

		FakeMagnetProjectile = UStaticMeshComponent::GetOrCreate(this, n"FakeMagnetProjectileMeshComponent");
		FakeMagnetProjectile.SetStaticMesh(FakeMagnetProjectileMesh);
		FakeMagnetProjectile.SetMaterial(0, FakeMagnetProjectileOffMaterial);
		FakeMagnetProjectile.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		FakeMagnetProjectile.AttachToComponent(ReloadStart);

		// Instantly load machine on begin play
		SetCapabilityActionState(n"SilentReload", EHazeActionState::ActiveForOneFrame);

		// Bind events
		OnShoot.AddUFunction(this, n"OnShoot_Delegate");
	}

	void ActivateSnowCannon(AHazePlayerCharacter InControllingPlayer)
	{
		bActivated = true;
		bThumperCocked = false;
		ControllingPlayer = InControllingPlayer;

		OnActivated.Broadcast();
		OnThumperCockStarted.Broadcast();
	}

	void DeactivateSnowCannon()
	{
		bActivated = false;

		OnDeactivated.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bPulled = false;
		if(bActivated)
		{
			TArray<AHazePlayerCharacter> Players;
			MagneticComponent.GetInfluencingPlayers(Players);
			if(Players.Num() <= 0)
				return;

			for(AHazePlayerCharacter Player : Players)
			{
				if(MagneticComponent.HasOppositePolarity(UMagneticComponent::Get(Player)))
					bPulled = true;
			}
		}

		if(bActivated && bPulled)
		{
			if(!FMath::IsNearlyEqual(Thumper.RelativeLocation.X, ThumperOriginalX + AddedX, 0.5f))
			{
				FHazeAcceleratedFloat AccFloat;
				AccFloat.Value = Thumper.RelativeLocation.X;
				AccFloat.AccelerateTo(ThumperOriginalX + AddedX, ThumperChargeAccelerationDuration, DeltaTime);

				Thumper.SetRelativeLocation(FVector(AccFloat.Value, Thumper.RelativeLocation.Y, Thumper.RelativeLocation.Z));
				UpdateSpringLocation();
			}

			if(!bThumperCocked && FMath::IsNearlyEqual(Thumper.RelativeLocation.X, ThumperOriginalX + AddedX, 15.f))
			{
				bThumperCocked = true;
				OnThumperCocked.Broadcast();
			}

			// Update blackboard variable read by audio capability
			SetCapabilityAttributeValue(n"ThumperCockProgress", Thumper.RelativeLocation.X / (ThumperOriginalX + AddedX));
		}
		else
		{
			if(!FMath::IsNearlyEqual(Thumper.RelativeLocation.X, ThumperOriginalX, 0.5f))
			{
				FHazeAcceleratedFloat AccFloat;
				AccFloat.Value = Thumper.RelativeLocation.X;
				AccFloat.AccelerateTo(ThumperOriginalX, ThumperShootAccelerationDuration, DeltaTime);

				Thumper.SetRelativeLocation(FVector(AccFloat.Value, Thumper.RelativeLocation.Y, Thumper.RelativeLocation.Z));
				UpdateSpringLocation();
			}
		}

		// Tick cooldown
		if(bInCooldown)
		{
			CooldownTimer += DeltaTime;
			if(CooldownTimer >= CooldownDuration)
			{
				CooldownTimer = 0.0f;
				StopCooldown();
			}
		}
	}

	private void StartCooldown()
	{
		if(ControllingPlayer != nullptr)
		{
			ControllingPlayer.PlayCameraShake(CamShake, 15.0f);
			ControllingPlayer.PlayForceFeedback(ShootRumble, false, true, n"SnowCannonShoot");
			ControllingPlayer = nullptr;
		}

		bInCooldown = true;
		CrosshairMesh.SetScalarParameterValueOnMaterialIndex(0, n"IsValidTarget", 0.f);

		// Fire event
		OnCooldownStarted.Broadcast();
	}

	private void StopCooldown()
	{
		bInCooldown = false;
		CrosshairMesh.SetScalarParameterValueOnMaterialIndex(0, n"IsValidTarget", 1.f);

		OnCooldownCompleted.Broadcast();
	}

	void UpdateSpringLocation()
	{
		LeftSpring.SetBoneLocationByName(n"Spring", LeftSpringAttach.WorldLocation, EBoneSpaces::WorldSpace);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnShoot_Delegate()
	{
		StartCooldown();
		bThumperCocked = false;
	}
}