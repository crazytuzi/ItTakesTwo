import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantProjectile;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantTags;
import Cake.Weapons.Sap.SapWeaponCrosshairWidget;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.Weapons.Recoil.RecoilComponent;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.SoilState;
import Cake.Weapons.RangedWeapon.RangedWeaponSettings;
import Cake.Weapons.RangedWeapon.RangedWeapon;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantCrosshairWidget;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilTurretPlant;

import void SetCanExitSoil(AHazePlayerCharacter, bool) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";
import ASubmersibleSoil GetActivatingSoil(AActor Owner) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";


#if !RELEASE
const FConsoleVariable CVar_TurretPlantDebugDraw("Garden.TurretPlantDebugDraw", 0);
#endif // !RELEASE

enum ETurretPlantState
{
	Emerging,
	Submerging,
	Active,
	None
}

struct FTurretPlantFireInfo
{
	UPROPERTY()
	FHitResult Hit;
	UPROPERTY()
	URangedWeaponComponent RangedWeaponComponent;
	UPROPERTY()
	FName ArmAttachSocketName;
}

settings TurretPlantRangedWeaponSettings for URangedWeaponSettings
{
	TurretPlantRangedWeaponSettings.AmmoClip = 50;
	TurretPlantRangedWeaponSettings.FireRate = 0.06f;
	TurretPlantRangedWeaponSettings.bInfiniteAmmoTotal = true;
}

UCLASS(Abstract)
class ATurretPlant : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCharacterSkeletalMeshComponent TurretBase;
	default TurretBase.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	UPROPERTY(DefaultComponent, Attach = TurretBase, AttachSocket = LeftForeArmSocket)
	UArrowComponent LeftProjectileSpawnPoint;
	default LeftProjectileSpawnPoint.RelativeRotation = FRotator(90.0f, 0.0f, 0.0f);

	UPROPERTY(DefaultComponent, Attach = TurretBase, AttachSocket = RightForeArmSocket)
	UArrowComponent RightProjectileSpawnPoint;
	default RightProjectileSpawnPoint.RelativeRotation = FRotator(90.0f, 0.0f, 0.0f);

	// From the player
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent Capsule;
	default Capsule.CollisionProfileName = n"NoCollision";
	default Capsule.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;

	UPROPERTY(Category = "Turret")
	TSubclassOf<ATurretPlantProjectile> ProjectileClass;
	UPROPERTY(Category = "Turret")
	TSubclassOf<UTurretPlantCrosshairWidget> CrosshairClass;

	UPROPERTY(Category = Camera)
	TSubclassOf<UCameraShakeBase> ShootingCameraShake;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset AimingLocomotion;

	UPROPERTY(EditDefaultsOnly, Category = ForceFeedback)
	UForceFeedbackEffect BulletForceFeedback;

	UPROPERTY(Category = Audio)
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	UPROPERTY(Category = Animation)
	UAnimSequence ShootingAnimation;

	UPROPERTY(Category = Animation)
	UAnimSequence SpikeAmmoCountAnimation;

	UPROPERTY(Category = TutorialText)
	FText FirePrompt;
	UPROPERTY(Category = TutorialText)
	FText AimPrompt;
	UPROPERTY(Category = TutorialText)
	FText ReloadPrompt;
	UPROPERTY(Category = TutorialText)
	FText ExitPrompt;

	FVector StartLocation;
	FVector EndLocation;

	FVector2D CurrentPlayerInput;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ETurretPlantState TurretPlantState = ETurretPlantState::None;

	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComp.UpdateSettings.OptimalCount = 2;

	UPROPERTY(DefaultComponent, ShowOnActor)
	URangedWeaponComponent RangedWeapon;
	default RangedWeapon.RangedWeaponSettings = TurretPlantRangedWeaponSettings;

	UPROPERTY(DefaultComponent, ShowOnActor)
	URecoilComponent RecoilComponent;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent TargetProximityOffset;

	UTurretPlantCrosshairWidget CrosshairWidget;

	FVector StartScale = FVector(0.75f, 0.75f, 1.25f);
	FVector EndScale = FVector(0.75f, 1.f, 1.15f);

	// How much to zoom, multiplier based on the FOV value set in the TurretPlantCameraSettings asset.
	UPROPERTY(Category = Aim, meta = (ClampMin = 1.0))
	float ZoomMultiplier = 1.2f;

	// Reduce recoil amount when zooming.
	UPROPERTY(Category = Aim, meta = (ClampMin = 1.0, ClampMax = 2.0))
	float AimRecoilReduction = 1.6f;

	// Scale camera rotation speed when aiming.
	UPROPERTY(Category = Aim, meta = (ClampMin = 1.0, ClampMax = 2.0))
	float AimSensitivityFactor = 1.6f;

	// Time between each bullet.
	UPROPERTY(Category = Ammo)
	float FireRate = 0.05f;

	// Determines the scalar for FireRate if the fire button is not completely pressed. A higher value increases the fire rate the less the button is pressed.
	UPROPERTY(Category = Ammo)
	float FireRateFactor = 5.0f;

	float CurrentFireRate = 1.0f;

	default AppearTime = 1.0f;
	default ExitTime = 0.9f;

	UPROPERTY(Category = Ammo, meta = (ClampMin = 1))
	int AmmoTotal = 50;

	UPROPERTY(Category = Ammo, BlueprintReadOnly)
	float AmmoReloadTime = 0.85f;

	int AmmoCurrent = 0;

	float CurrentFireRateCooldown = 0.0f;

	float YawRotationDelta = 0.0f;
	float PitchRotationDelta = 0.0f;

	// How far off from the tip of the arm the projectile will spawn.
	UPROPERTY(Category = Projectile)
	float ProjectileSpawnOffset = 50.0f;

	// Input
	float TargetPitch = 0.0f;
	float TargetYaw = 0.0f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsExiting = false;

	FTimerHandle EmergeTimerHandle;

	bool bRightHandSpawnLocation = true;

	UPROPERTY(BlueprintReadOnly, Category = Animation)
	bool bSkipAppearAnimation = false;

	UPROPERTY(EditDefaultsOnly, Category = Effect)
	UNiagaraSystem AttackedByGardenEnemyEffect;

	UFUNCTION(BlueprintPure, Category = TurretPlant)
	float GetRotationYaw() const
	{
		return CurrentAimYaw;
	}

	UFUNCTION(BlueprintPure, Category = TurretPlant)
	float GetAimPitch() const
	{
		return CurrentAimPitch;
	}

	float CurrentAimPitch = 0.0f;
	float CurrentAimYaw = 0.0f;
	float ZoomFraction = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = TurretPlant)
	float AimAdjustX = 0.0f;
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = TurretPlant)
	float AimAdjustY = 0.0f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsShooting = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsReloading = false;

	bool bActive = false;

	bool bWantsToShoot = false;
	private bool bIsDisabled = false;

	UFUNCTION(BlueprintPure)
	float GetAmmoRemaining() const 
	{ 
		const int AmmoMaximum = RangedWeapon.GetAmmoClipMaximum();
		const int CurrentAmmo = RangedWeapon.AmmoClipCurrent;

		return float(CurrentAmmo) / float(AmmoMaximum);
	}

	void RestoreAmmo()
	{
		RangedWeapon.Reload();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RangedWeapon.OnRangedWeaponFire.AddUFunction(this, n"Handle_OnRangedWeaponFire");
		
		AddCapability(n"TurretPlantRotationCapability");
		AddCapability(n"TurretPlantShootingCapability");
		AddCapability(n"TurretPlantAmmoReloadCapability");
		AddCapability(n"TurretPlantRecoilCapability");
		AddCapability(n"RecoilCheckFireCapability");
		AddCapability(AudioCapabilityClass);

		bIsDisabled = DisableComp.bDisabledAtStart;
		Camera = UHazeCameraComponent::Get(OwnerPlayer);
	}

	void SetupSpikeAnimation()
	{
		if(SpikeAmmoCountAnimation != nullptr)
		{
			FHazePlayAdditiveAnimationParams AddativeParams;
			AddativeParams.Animation = SpikeAmmoCountAnimation;
			AddativeParams.PlayRate = 0.0f;

			TurretBase.PlayAdditiveAnimation(FHazeAnimationDelegate(), AddativeParams);
		}
	}

	void StopSpikeAnimation()
	{
		if(SpikeAmmoCountAnimation != nullptr)
		{
			FHazeStopAdditiveAnimationParams Params;
			Params.Animation = SpikeAmmoCountAnimation;
			Params.BlendTime = 0.0f;
			TurretBase.StopAdditiveAnimation(Params);
		}
	}

	UFUNCTION(BlueprintCallable)
	void UpdateSpikeAnimation()
	{
		if(SpikeAmmoCountAnimation != nullptr)
		{
			TurretBase.SetAdditiveAnimationPosition(SpikeAmmoCountAnimation, SpikeAmmoCountAnimation.PlayLength * ((GetAmmoRemaining() - 1.0f) * -1.0f) );
		}
	}

	void TriggerCameraTransitionToPlayer()
	{
		OwnerPlayer.ClearCameraSettingsByInstigator(this, 0.5f);
	}

	void TriggerCameraTransitionToPlant()
	{
		
	}
	
	// This is to check for the interval between shooting individual seeds.
	bool CanShootSeed() const
	{
		return RangedWeapon.CanFire();
	}

	// This is to check if we can start shooting at all.
	bool CanStartShooting() const
	{
		if(bIsExiting)
			return false;

		if(!bIsPlantActive)
			return false;

		if(TurretPlantState == ETurretPlantState::Submerging)
			return false;

		if(TurretPlantState == ETurretPlantState::Emerging)
			return false;

		return true;
	}

	UFUNCTION()
	void SetTurretPlantEnabled(bool bValue)
	{
		if(bIsDisabled && bValue)
		{
			EnableActor(nullptr);
			bIsDisabled = false;
		}
		else if(!bIsDisabled && !bValue)
		{
			DisableActor(nullptr);
			bIsDisabled = true;
		}
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		AddPlayerSheet();
		//DisableAndHidePlayer(InPlayerLocation, InPlayerRotation);

		SetTurretPlantEnabled(true);

		Capsule.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
		TurretPlantState = ETurretPlantState::Emerging;
		SetActorTickEnabled(true);
		//SetCanExitSoil(OwnerPlayer, false);
		bIsExiting = false;
		AmmoCurrent = AmmoTotal;
		
		ASubmersibleSoilTurretPlant SoilTurretPlant = Cast<ASubmersibleSoilTurretPlant>(GetActivatingSoil(OwnerPlayer));

		if(SoilTurretPlant != nullptr && !SoilTurretPlant.bUsePlayerRotation)
		{
			SetActorRotation(FRotator(0.0f, SoilTurretPlant.YawAngleStart, 0.0f));
		}
		else
		{
			SetActorRotation(FRotator(0.f, Game::GetCody().ViewRotation.Yaw, 0.f));
		}
		
		SetActorHiddenInGame(false);
		RestoreAmmo();

		bActive = true;
		SetupSpikeAnimation();

		if(bSkipAppearAnimation)
			OwnerPlayer.ApplyCameraSettings(SpringArmSettings, FHazeCameraBlendSettings(0.75f), this, EHazeCameraPriority::Medium);
	}

	void OnActivatePlant()
	{
		if(!bSkipAppearAnimation)
			OwnerPlayer.ApplyCameraSettings(SpringArmSettings, FHazeCameraBlendSettings(0.75f), this, EHazeCameraPriority::Medium);
		
		TurretPlantState = ETurretPlantState::Active;
		if(CrosshairClass.IsValid())
		{
			CrosshairWidget = Cast<UTurretPlantCrosshairWidget>(OwnerPlayer.AddWidget(CrosshairClass));
		}
	}

	void PreDeactivate() override
	{
		Capsule.SetCollisionProfileName(n"NoCollision");
		TurretPlantState = ETurretPlantState::Submerging;
		bIsExiting = true;
		if(CrosshairWidget != nullptr)
		{
			OwnerPlayer.RemoveWidget(CrosshairWidget);
			CrosshairWidget = nullptr;
		}

		if(SpikeAmmoCountAnimation != nullptr)
		{
			FHazeStopAdditiveAnimationParams Params;
			Params.Animation = SpikeAmmoCountAnimation;
			Params.BlendTime = 0.0f;
			TurretBase.StopAdditiveAnimation(Params);
		}

		OwnerPlayer.ClearCameraSettingsByInstigator(this, 1.25f);
	}

	void OnDeactivatePlant()
	{
		OnUnpossessPlant(ActorLocation, ActorRotation, EControllablePlantExitBehavior::ExitSoil);
		bActive = false;
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		TurretPlantState = ETurretPlantState::None;
		TurretBase.ResetAllAnimation();
		SetTurretPlantEnabled(false);
	}

	bool HasEnoughAmmoToShoot() const
	{
		return !RangedWeapon.IsClipOutOfAmmo();
	}

	bool CanReload() const
	{
		return !RangedWeapon.IsClipFull();
	}

	FVector GetProjectileSpawnLocation(FName SocketName) const
	{
		FTransform SpawnTransform = TurretBase.GetSocketTransform(SocketName);
		const FVector SpawnLocation = SpawnTransform.Location + (SpawnTransform.Rotation.UpVector * ProjectileSpawnOffset);
		return SpawnLocation;
	}

	void UpdatePlayerInput(FVector2D Input, float InFireRate, float InZoomAmount, bool bWantsToReload, bool bWantsToExit)
	{
		//if(TurretPlantState != ETurretPlantState::Active)
		{
		//	return;
		}

		CurrentPlayerInput = Input;
		
		const float CurrentFireRateFactor = FireRateFactor * ((InFireRate * -1.0f) + 1.0f);
		CurrentFireRate = 1.0f + CurrentFireRateFactor;
		RangedWeapon.FireRateMultiplier = CurrentFireRate;
		bWantsToShoot = InFireRate > 0.0f;

		RecoilComponent.Input = Input;
		RecoilComponent.RecoilDistanceMultiplier = 1.0f + ((1.0f - AimRecoilReduction) * InZoomAmount);

		if(bWantsToShoot && CanShootSeed())
		{
			SetCapabilityActionState(TurretPlantTags::ShootSeed, EHazeActionState::ActiveForOneFrame);
			CurrentFireRateCooldown = 0.0f;
		}
		else if(bWantsToReload)
		{
			SetCapabilityActionState(n"TurretPlantReload", EHazeActionState::ActiveForOneFrame);
		}

		// Prepare exit turret plant by resetting input etc
		if(bWantsToExit && !bIsExiting)
		{
			FHazeDelegateCrumbParams CrumbParams;
			//CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_HandleExitTurretPlant"), CrumbParams);
		}
	}

	UFUNCTION()
	private void Crumb_HandleExitTurretPlant(const FHazeDelegateCrumbData& CrumbData)
	{
		bIsExiting = true;
		System::SetTimer(this, n"Handle_SubmergeDone", 0.9f, false);
		//TurretPlantState = ETurretPlantState::Submerging;
		CurrentPlayerInput = FVector2D::ZeroVector;
		CurrentFireRate = 0.0f;
		bWantsToShoot = false;
		TriggerCameraTransitionToPlayer();
		System::ClearAndInvalidateTimerHandle(EmergeTimerHandle);
	}

	UFUNCTION()
	void Handle_SubmergeDone()
	{
		SetCanExitSoil(OwnerPlayer, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentFireRateCooldown += DeltaTime;

#if !RELEASE
		if(CVar_TurretPlantDebugDraw.GetInt() == 1)
		{
			System::DrawDebugSphere(RightArmTransform.Location, 100.0f, 12, FLinearColor::Green);
			System::DrawDebugSphere(LeftArmTransform.Location, 100.0f, 12, FLinearColor::Green);
			System::DrawDebugArrow(RightArmTransform.Location, RightArmTransform.Location + RightArmTransform.Rotation.UpVector * 2000.0f);
			System::DrawDebugArrow(LeftArmTransform.Location, LeftArmTransform.Location + LeftArmTransform.Rotation.UpVector * 2000.0f);
		}
#endif // !RELEASE
	}

	void ShootLeft()
	{
		if(ShootingAnimation != nullptr)
		{
			FHazePlayOverrideAnimationParams Params;
			Params.Animation = ShootingAnimation;
			Params.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_LeftArm;
			Params.BlendTime = 0.0f;
			TurretBase.PlayOverrideAnimation(FHazeAnimationDelegate(), Params);
		}
	}

	void ShootRight()
	{
		if(ShootingAnimation != nullptr)
		{
			FHazePlayOverrideAnimationParams Params;
			Params.Animation = ShootingAnimation;
			Params.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_RightArm;
			Params.BlendTime = 0.0f;
			TurretBase.PlayOverrideAnimation(FHazeAnimationDelegate(), Params);
		}
	}

	FName GetCurrentSocketName() const property
	{
		return bRightHandSpawnLocation ? n"RightHand" : n"LeftHand";
	}

	FName GetCurrentSocketAttachName() const property
	{
		return bRightHandSpawnLocation ? n"RightForeArmSocket" : n"LeftForeArmSocket";
	}

	FTransform GetRightArmTransform() const property
	{
		return TurretBase.GetSocketTransform(n"RightForeArmSocket");
	}

	FTransform GetLeftArmTransform() const property
	{
		return TurretBase.GetSocketTransform(n"LeftForeArmSocket");
	}

	UFUNCTION()
	private void Handle_OnRangedWeaponFire(FRangedWeaponFireInfo WeaponFireInfo)
	{
		FTurretPlantFireInfo PlantFireInfo;
		PlantFireInfo.Hit = WeaponFireInfo.Hit;
		PlantFireInfo.RangedWeaponComponent = WeaponFireInfo.RangedWeapon;
		PlantFireInfo.ArmAttachSocketName = CurrentSocketAttachName;
		BP_OnTurretPlantFire(PlantFireInfo);
		bRightHandSpawnLocation = !bRightHandSpawnLocation;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Turret Plant Fire"))
	void BP_OnTurretPlantFire(FTurretPlantFireInfo FireInfo) {}

	UFUNCTION(BlueprintPure)
	float GetWaterLevel() const property { return 0.0f; }

	bool CanExitPlant() const override
	{
		return TurretPlantState == ETurretPlantState::Active;
	}
}
