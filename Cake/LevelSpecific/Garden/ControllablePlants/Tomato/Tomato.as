import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoSettings;
import Vino.Camera.Settings.FocusTargetSettings;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.VOBanks.GardenGreenhouseVOBank;

import AControllablePlant GetCurrentPlant() from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";

settings TomatoSettingsDefault for UTomatoSettings
{

}

settings TomatoCameraLazyChaseSettings for UCameraLazyChaseSettings
{
	TomatoCameraLazyChaseSettings.CameraInputDelay = 1.2f;
	TomatoCameraLazyChaseSettings.MovementInputDelay = 1.f;
	TomatoCameraLazyChaseSettings.AccelerationDuration = 20.f;
};

struct FTomatoBounceInfo
{
	FVector HitNormal = FVector::ZeroVector;
	float BounceMultiplier = 1.0f;
}

enum ETomatoType
{
	Tomato,
	Potato,
	Lime,
	None
}

UFUNCTION()
ATomato GetCurrentTomato()
{
	ATomato TomatoCurrent = Cast<ATomato>(GetCurrentPlant());
	return TomatoCurrent;
}

UCLASS(Abstract, hidecategories = "Capability Actor Tick Rendering Input Actor Replication")
class ATomato : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.CapsuleHalfHeight = 100.f;
	default CollisionComp.CapsuleRadius = 100.f;
	default CollisionComp.CollisionProfileName = n"NoCollision";	// This is set to PlayerCharacter profile name when cody starts controlling it.
	default CollisionComp.RelativeLocation = FVector(0.f, 0.f, 100.f);

	UPROPERTY(DefaultComponent, Attach = CollisionComp)
	USceneComponent TomatoRoot;

	UPROPERTY(DefaultComponent, Attach = TomatoRoot)
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	default SkeletalMesh.CollisionProfileName = n"NoCollision";

	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0f;

	default ExitTime = 2.5f;

	UPROPERTY(Category = Setup)
	UTomatoSettings TomatoSettings = TomatoSettingsDefault;

	UPROPERTY(Category = Setup)
	UTomatoSettings TomatoSettingsGoo = TomatoSettingsDefault;

	UPROPERTY(Category = Setup)
	UTomatoSettings TomatoDashSettings = TomatoSettingsDefault;

	UPROPERTY(Category = Setup)
	UTomatoSettings TomatoLockOnSettings = TomatoSettingsDefault;

	UTomatoSettings Settings;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	default CameraLazyChaseSettings = TomatoCameraLazyChaseSettings;

	UPROPERTY(EditDefaultsOnly, Category = VFX)
	UNiagaraSystem ExitTomatoVFX;
	default ExitTomatoVFX = Asset("/Game/Effects/Niagara/GardenBoss/GameplayCodyTomato_01.GameplayCodyTomato_01");

	UPROPERTY(EditDefaultsOnly, Category = VFX)
	UNiagaraSystem TomatoDeathVFX;
	default TomatoDeathVFX = Asset("/Game/Effects/Niagara/GardenBoss/GameplayCodyTomato_01.GameplayCodyTomato_01");

	UPROPERTY(EditDefaultsOnly, Category = VFX)
	UNiagaraSystem TomatoRespawnVFX;
	default TomatoRespawnVFX = Asset("/Game/Effects/Niagara/GardenBoss/GameplayCodyTomato_01.GameplayCodyTomato_01");

	UPROPERTY(Category = Feedback)
	UForceFeedbackEffect HitEnemyFeedback;

	UPROPERTY(Category = Feedback)
	UForceFeedbackEffect HitWallFeedback;

	UPROPERTY(Category = Feedback)
	TSubclassOf<UCameraShakeBase> HitEnemyCameraShake;

	UPROPERTY(Category = Feedback)
	TSubclassOf<UCameraShakeBase> HitWallCameraShake;

	UPROPERTY(Category = Animation)
	UAnimSequence ExitTomatoAnim;

	UPROPERTY(Category = Animation)
	UAnimSequence DashAnim;

	UPROPERTY(Category = Animation)
	UAnimSequence IdleAnim;
	default IdleAnim = Asset("/Game/Animations/Characters/Cody/Behaviour/Garden/CodyFruit_JoyBossFight/CodyTomato_Bhv_GreenHouse_MH.CodyTomato_Bhv_GreenHouse_MH");

	UPROPERTY()
	FHazeTimeLike SpawnCurve;

	UPROPERTY(Category = Audio)
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	UPROPERTY(Category = Audio)
	UGardenGreenhouseVOBank GreenhouseVOBank;

	bool bTomatoActive = false;
	bool bTriggerExposionOnExit = false;

	FVector CurrentPlayerInput;
	FVector Velocity;
	FVector SlopeVelocity;

	float HitWallForceFeedbackCooldown = 0.1f;
	float HitWallForceFeedbackCooldownElapsed = 0.0f;

	UPROPERTY()
	ETomatoType TomatoType = ETomatoType::Tomato;

	UPROPERTY()
	float ScaleSpeed = 0.3f;

	float StartScale = 1.0f;
	float CurrentScale = 1.0f;
	float TargetScale = 1.0f;
	float MaxScale = 2.5f;

	int BounceCounter = 0;
	int BounceTotal = 1;

	float AccelerationCurrent = 0.0f;
	float MaxSpeedCurrent = 0.0f;
	float FrictionCurrent = 0.0f;

	float CameraShakeCrumbElapsed = 0.0f;
	float CameraShakeCrumbLimit = 0.25f;

	bool bTomatoInitialized = false;
	bool bWantsToJump = false;
	bool bWantsToDash = false;
	bool bIsJumping = false;
	bool bWasDestroyed = true;
	bool bJumpButtonPressed = false;
	bool bIsLaunching = false;
	bool bIsBlockInput = false;
	bool bApplyRotation = true;
	bool bIsDashing = false;
	bool bFinishedSpawning = false;
	bool bWasDead = false;
	bool bDashDisabledByGoo = false;

	bool IsInputBlocked() const { return bIsBlockInput; }

	float LaunchImpulse;
	FVector LaunchDirection;

	TArray<FTomatoBounceInfo> BounceList;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CollisionComp);
		StartScale = GetTomatoScale();
		ApplyDefaultSettings(TomatoSettings);
		Settings = UTomatoSettings::GetSettings(this);
		Camera = UHazeCameraComponent::Get(OwnerPlayer);
		AddCapability(n"TomatoSpawnCapability");
		AddCapability(n"TomatoMovementCapability");
		AddCapability(n"TomatoPhysicsCapability");
		AddCapability(n"TomatoDashCapability");
		AddCapability(n"TomatoGooDamageDisableCapability");
		AddCapability(AudioCapabilityClass);
		AddDebugCapability(n"TomatoDebugCapability");

		SpawnCurve.BindUpdate(this, n"UpdateSpawnTomato");
		SpawnCurve.BindFinished(this, n"FinishSpawnTomato");
	}

	UFUNCTION()
	void UpdateSpawnTomato(float CurValue)
	{
		SkeletalMesh.SetWorldScale3D(CurValue);
	}

	UFUNCTION()
	void FinishSpawnTomato()
	{
		FHitResult Hit;
		OwnerPlayer.SetActorRelativeLocation(FVector::ZeroVector, false, Hit, true);
		bFinishedSpawning = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(OwnerPlayer == nullptr)
			return;

		const bool bIsDead = OwnerPlayer.IsPlayerDead();

		if(bIsDead && !bWasDead)
		{
			SetActorHiddenInGame(true);
			SetCapabilityActionState(n"TomatoDeath", EHazeActionState::Active);
			if(TomatoDeathVFX != nullptr)
				Niagara::SpawnSystemAtLocation(TomatoDeathVFX, ActorCenterLocation);

		}
		else if(!bIsDead && bWasDead)
		{
			SetActorHiddenInGame(false);
			OwnerPlayer.SetActorHiddenInGame(true);
			SpawnCurve.PlayFromStart();
			if(TomatoRespawnVFX != nullptr)
				Niagara::SpawnSystemAtLocation(TomatoRespawnVFX, ActorCenterLocation);
		}

		bWasDead = bIsDead;
		CameraShakeCrumbElapsed -= DeltaTime;
		HitWallForceFeedbackCooldownElapsed -= DeltaTime;
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		if(IsActorDisabled(this))
			EnableActor(this);
		
		AddPlayerSheet();
		bFinishedSpawning = false;
	}

	void OnActivatePlant() override
	{
		SpawnCurve.PlayFromStart();
		bTomatoInitialized = true;
		MoveComp.StopMovement();
		Velocity = FVector::ZeroVector;
		SetActorScale3D(StartScale);
		SkeletalMesh.SetWorldScale3D(StartScale);
		SetCapabilityActionState(TomatoTags::Activate, EHazeActionState::ActiveForOneFrame);

		
		if(CameraSettings != nullptr)
		{
			OwnerPlayer.ApplyCameraSettings(CameraSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::High);
		}
		
		CollisionComp.SetCollisionProfileName(n"PlayerCharacter");
		MoveComp.Activate();

	}

	void PreDeactivate() override
	{
		CurrentPlayerInput = FVector::ZeroVector;
		OwnerPlayer.ClearSettingsByInstigator(this); // Remove any composable settings, e.g. UFocusTargetSettings
		OwnerPlayer.ClearCameraSettingsByInstigator(this);
		SetActorHiddenInGame(true);
		bFinishedSpawning = false;
		CollisionComp.SetCollisionProfileName(n"NoCollision");
		MoveComp.StopMovement();
		MoveComp.Deactivate();
		bTomatoInitialized = false;

		if(ExitTomatoVFX != nullptr)
			Niagara::SpawnSystemAtLocation(ExitTomatoVFX, ActorCenterLocation);

		OwnerPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		if(ExitTomatoAnim != nullptr)
		{
			OwnerPlayer.SetActorHiddenInGame(false);
			FHazePlaySlotAnimationParams Params;
			Params.Animation = ExitTomatoAnim;
			Params.BlendTime = 0.f;
			OwnerPlayer.PlaySlotAnimation(Params);
		}

		DisableActor(this);
	}

	void OnDeactivatePlant() override
	{
		CleanupCurrentMovementTrail();
		OnUnpossessPlant(ActorLocation, ActorRotation, EControllablePlantExitBehavior::PlantLocation);
	}

	void TriggerCameraTransitionToPlayer()
	{
		TArray<AActor> ActorsToIgnore;
		FHitResult Hit;
		System::LineTraceSingle(OwnerPlayer.ViewLocation, OwnerPlayer.ActorLocation + FVector(0.f, 0.f, 500.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.bBlockingHit)
		{
			FadeOutPlayer(OwnerPlayer, 0.25f, 0.25f, 0.25f);
			System::SetTimer(this, n"SnapCamera", 0.3f, false);
			return;
		}
	}

	UFUNCTION()
	void SnapCamera()
	{
		//OwnerPlayer.DeactivateCamera(Camera, 0.f);
	}

	void TomatoFullySpawned()
	{
		
	}

	void UpdatePlayerInput(const FVector& PlayerInput, bool bInWantsToJump, bool bInJumpButtonPressed, bool bInWantsToDash)
	{
		CurrentPlayerInput = PlayerInput;
		bJumpButtonPressed = bInJumpButtonPressed;
		bWantsToDash = bInWantsToDash;

		if(bInWantsToJump)
		{
			SetCapabilityActionState(TomatoTags::Jump, EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION()
	void LaunchTomato(FVector Direction, float LaunchPower)
	{
		LaunchDirection = Direction;
		LaunchImpulse = LaunchPower;

		SetCapabilityActionState(TomatoTags::Launch, EHazeActionState::ActiveForOneFrame);
	}

	FRotator GetTargetRotation() const
	{
		return Velocity.ToOrientationRotator();
	}

	float GetCurrentMovementDirection() const
	{
		return Velocity.Size() > 0.1f ? 1.0f : 0.0f;
	}

	bool CanSpawnTomato(AHazePlayerCharacter Player) const
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Player);
		ActorsToIgnore.Add(this);

		const float TotalDistance = 300.0f;
		const float RequiredDistance = 280.0f;
		FVector StartLocation = Player.CapsuleComponent.GetWorldLocation(); // Get the middle of the player
		FVector EndLocation = StartLocation - FVector(0.0f, 0.0f, TotalDistance * 0.5f);

		FHitResult Hit;
		System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if(Hit.bBlockingHit)
		{
			ActorsToIgnore.Add(Hit.Actor);
			StartLocation = Hit.Location;
			EndLocation = StartLocation + FVector(0.0f, 0.0f, TotalDistance);

			Hit.Reset();
			System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

			if(Hit.bBlockingHit)
			{
				return Hit.Distance > RequiredDistance;
			}
		}

		return true;
	}

	void PlayHitEnemyForceFeedback()
	{
		if(HitEnemyFeedback == nullptr)
			return;

		if(OwnerPlayer == nullptr)
			return;

		OwnerPlayer.PlayForceFeedback(HitEnemyFeedback, false, false, n"TomatoDashHitEnemy");
	}

	void PlayHitEnemyCameraShake()
	{
		if(!HitEnemyCameraShake.IsValid())
			return;

		if(OwnerPlayer == nullptr)
			return;

		OwnerPlayer.PlayCameraShake(HitEnemyCameraShake);
	}

	void PlayHitWallForceFeedback()
	{
		if(HitWallFeedback == nullptr)
			return;

		if(OwnerPlayer == nullptr)
			return;

		if(HitWallForceFeedbackCooldownElapsed > 0.0f)
			return;

		const float IntensityFactor = FMath::Clamp(Velocity.SizeSquared() / FMath::Square(TomatoSettings.MaxSpeed), 0.0f, 1.0f);
		OwnerPlayer.PlayForceFeedback(HitWallFeedback, false, false, n"TomatoDashHitWall", IntensityFactor);
		HitWallForceFeedbackCooldownElapsed = HitWallForceFeedbackCooldown;
	}

	void PlayHitWallCameraShake()
	{
		if(!HitEnemyCameraShake.IsValid())
			return;

		OwnerPlayer.PlayCameraShake(HitWallCameraShake);
	}

	void StartIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = IdleAnim;
		Params.bLoop = true;
		SkeletalMesh.PlaySlotAnimation(Params);
	}

	void Bounce(FVector HitNormal, float BounceMultiplier)
	{
		if(!HasControl())
			return;

		if(BounceList.Num() > 0)
			return;
		
		FTomatoBounceInfo BounceInfo;
		BounceInfo.HitNormal = HitNormal;
		BounceInfo.BounceMultiplier = BounceMultiplier;
		BounceList.Add(BounceInfo);
	}

	void PlayWallHitCameraShakeWithCrumb()
	{
		if(CameraShakeCrumbElapsed <= 0.0f)
		{
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PlayWallHitCameraShake"), FHazeDelegateCrumbParams());
			CameraShakeCrumbElapsed = CameraShakeCrumbLimit;
		}
		else
		{
			PlayHitWallCameraShake();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_PlayWallHitCameraShake(FHazeDelegateCrumbData CrumbData)
	{
		PlayHitWallCameraShake();
	}

	// Use a point in world to calculate "hit normal"
	void BounceFromPoint(FVector HitLocation, float BounceMultiplier)
	{
		if(!HasControl())
			return;

		const FVector HitNormal = (HitLocation - ActorLocation).GetSafeNormal();
		FTomatoBounceInfo BounceInfo;
		BounceInfo.HitNormal = HitNormal;
		BounceInfo.BounceMultiplier = BounceMultiplier;
		BounceList.Add(BounceInfo);
	}

	UFUNCTION(BlueprintPure)
	bool IsTomato() const
	{
		return TomatoType == ETomatoType::Tomato;
	}

	UFUNCTION(BlueprintPure)
	bool IsPotato() const
	{
		return TomatoType == ETomatoType::Potato;
	}

	UFUNCTION(BlueprintPure)
	bool IsLime() const
	{
		return TomatoType == ETomatoType::Lime;
	}

	UFUNCTION()
	void HandleDamageTaken()
	{
		BP_OnDamaged();
	}

	float GetTomatoScale() const
	{
		return GetActorScale3D().Z;
	}

	void CalculateRotationFromVelocity(const FVector& InVelocity, float DeltaTime)
	{
		if(bApplyRotation)
		{
			TomatoRoot.AddWorldRotation(FRotator(-InVelocity.X, 0.0f, InVelocity.Y) * ((Settings.RotationSpeed / GetTomatoScale()) * DeltaTime));
		}
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Dash Enter"))
	void BP_OnDashEnter(){}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Dash Exit"))
	void BP_OnDashExit(){}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Damaged"))
	void BP_OnDamaged(){}
}
