import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdTags;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingSettings;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBombCrosshair;

event void FOnPlayerMountedClockworkBird(AHazePlayerCharacter Player);

settings ClockworkBirdMovementDefaultSettings for UMovementSettings
{
	ClockworkBirdMovementDefaultSettings.MoveSpeed = 1000.f;
	ClockworkBirdMovementDefaultSettings.GravityMultiplier = 3.f;
	ClockworkBirdMovementDefaultSettings.ActorMaxFallSpeed = 1800.f;
	ClockworkBirdMovementDefaultSettings.StepUpAmount = 40.f;
	ClockworkBirdMovementDefaultSettings.CeilingAngle = 30.f;
	ClockworkBirdMovementDefaultSettings.WalkableSlopeAngle = 55.f;
	ClockworkBirdMovementDefaultSettings.AirControlLerpSpeed = 2500.f;
	ClockworkBirdMovementDefaultSettings.GroundRotationSpeed = 20.f;
	ClockworkBirdMovementDefaultSettings.AirRotationSpeed = 10.f;
	ClockworkBirdMovementDefaultSettings.VerticalForceAirPushOffThreshold = 500.f;
}

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor LOD")
class AClockworkBird : AHazeCharacter
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	default CapsuleComponent.SetCollisionProfileName(n"PlayerCharacter");
	default Mesh.RelativeLocation = FVector(-40.f, 0.f, -80.f);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = Totem)
	USceneComponent AttachComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent DismountedPlayerCollision;
	default DismountedPlayerCollision.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, Attach = AttachComponent)
	USkeletalMeshComponent EditorSkelMesh;
	default EditorSkelMesh.bHiddenInGame = true;
	default EditorSkelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default EditorSkelMesh.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent StaticCamera;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraOffset;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	USceneComponent HeldBombRoot;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	USceneComponent DismountJumpOffPoint;

	UPROPERTY(DefaultComponent, Attach = CameraOffset)
	UCameraSpringArmComponent CameraSpringArm;

	UPROPERTY(DefaultComponent, Attach = CameraSpringArm)
	UHazeCameraComponent FlightCamera;
	default FlightCamera.BlendOutBehaviour = EHazeCameraBlendoutBehaviour::LockView;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.DefaultMovementSettings = ClockworkBirdMovementDefaultSettings;
	default MoveComp.ControlSideDefaultCollisionSolver = n"VehicleCollisionSolver";
	default MoveComp.RemoteSideDefaultCollisionSolver = n"VehicleRemoteCollisionSolver";

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	//Camera Settings DA
	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	// Camera settings used while having a bomb
	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings_HeldBomb;
	UPROPERTY(Category = "Camera")
	FHazeCameraBlendSettings CameraSettingsBlend_HeldBomb;

	// Camera settings used while gliding
	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings_Aiming;
	UPROPERTY(Category = "Camera")
	FHazeCameraBlendSettings CameraSettingsBlend_Aiming;

	AHazePlayerCharacter ActivePlayer = nullptr;
	bool bPlayerStartedAnimating = false;
	bool bActivePlayerWantsToUseBird = false;

	// Variables used to make the flight camera lag behind
	FVector LocalFlightCameraLocationLastTick;
	FQuat LocalFlightCameraRotationLastTick;

	FVector PlayerInput = FVector::ZeroVector;
	FVector PlayerRawInput = FVector::ZeroVector;
	FVector PlayerLerpedRawInput = FVector::ZeroVector;
	FVector PlayerLerpedRawTargetInput = FVector::ZeroVector;
	bool bUsingVehicleChaseCam = false;

	FOnPlayerMountedClockworkBird OnPlayerMounted;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> HighSpeedCamShake;
	
	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> CamShakeBird;

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet;

	UCameraShakeBase FlyingCamShake;

	// Animation variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsFlapping = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDidSecondJump = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FlightSpeed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsFlying = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsLanding = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsJumping = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsDashing = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsHoldingBomb = false;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	bool bDisableDismount = false;

	bool bCanLand = false;
	bool bIsLaunching = false;
	bool bIsDead = false;

	UPROPERTY()
	UHazeLocomotionAssetBase CodyLocomotionAssetBase;

	UPROPERTY()
	UHazeLocomotionAssetBase MayLocomotionAssetBase;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	// Crosshair widget for flying bomb
	UPROPERTY()
	TSubclassOf<UFlyingBombCrosshair> BombAimCrosshair;

	UClockworkBirdFlyingSettings FlyingSettings;
	UObject CurrentPerch;

	float CurrentBoostSpeed = 0.f;
	float BoostDuration = 0.f;
	float BoostTimer = 0.f;
	FVector AutoAimPoint;

	USceneComponent GetBirdRoot() property
	{
		return Mesh;
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CapsuleComponent);

		InteractionComp.OnActivated.AddUFunction(this, n"PlayerStartedUsingBird");
		CapsuleComponent.RemoveTag(ComponentTags::Walkable);

		AddCapability(n"ClockworkBirdGroundedCapability");
		AddCapability(n"ClockworkBirdMountedCapability");	
		AddCapability(n"ClockworkBirdFlyingCapability");

		//AddCapability(n"ClockworkBirdJumpCapability");		
		AddCapability(n"ClockworkBirdAirMoveCapability");		
		AddCapability(n"ClockworkBirdLaunchCapability");		
		AddCapability(n"ClockworkBirdDashCapability");		
		//AddCapability(n"ClockworkBirdLandCapability");		

		AddCapability(n"ClockworkBirdLandOnPerchCapability");		
		AddCapability(n"ClockworkBirdPerchedCapability");		

		AddCapability(n"ClockworkBirdFlyingCameraCapability");
		//AddCapability(n"ClockworkBirdStaticFlyingCameraCapability");

		FlyingSettings = UClockworkBirdFlyingSettings::GetSettings(this);

		UClass AudioClass = AudioCapabilityClass.Get();
		if(AudioClass != nullptr)
			AddCapability(AudioClass);

		// DEBUG
	#if TEST
		Debug::RegisterActorLogger(this, 300);
	#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (ActivePlayer != nullptr)
			ActivePlayer.RemoveCapabilitySheet(PlayerSheet, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PlayerLerpedRawInput = FMath::VInterpTo(PlayerLerpedRawInput, PlayerLerpedRawTargetInput, DeltaTime, 1.f);
		
		if (BoostDuration > 0.f)
		{
			BoostTimer += DeltaTime;
			if (BoostTimer >= BoostDuration)
			{
				CurrentBoostSpeed = 0.f;
				BoostDuration = 0.f;
				BoostTimer = 0.f;
			}
		}
	}

	UFUNCTION()
	void Boost(float BoostSpeed, float BoostDecayDuration)
	{
		if (!bIsFlying)
			return;

		BoostTimer = 0.f;
		BoostDuration = BoostDecayDuration;
		CurrentBoostSpeed = BoostSpeed;
	}

	void RemoveBoost()
	{
		BoostDuration = 0.f;
		CurrentBoostSpeed = 0.f;
		BoostTimer = 0.f;
	}

	UFUNCTION(DevFunction)
	void TestSpeedBoost()
	{
		Boost(10000.f, 5.f);
	}

	void SetIsFlying(bool bNewIsFlying)
	{
		bIsFlying = bNewIsFlying;
	}

	void SetNewFlightSpeed(float NewFlightSpeed)
	{
		FlightSpeed = NewFlightSpeed;
	}

	bool IsGrounded()const
	{
		if(HasControl())
		{
			return MoveComp.IsGrounded();
		}
		else
		{
			FHazeActorReplicationFinalized TargetParams;
			if(CrumbComponent.GetCurrentReplicatedData(TargetParams))
			{
				if(TargetParams.IsGrounded())
					return true;			
			}

			return false;
		}
	}

	UFUNCTION(Category = "Clockwork Bird")
	void ForceMountPlayer(AHazePlayerCharacter Player)
	{
		devEnsure(ActivePlayer == nullptr);
		PlayerStartedUsingBird(InteractionComp, Player);
	}

	UFUNCTION(Category = "Clockwork Bird")
	void ForceDismountPlayer()
	{
		if (ActivePlayer == nullptr)
			return;
		ActivePlayer.SetCapabilityAttributeObject(ClockworkBirdTags::ClockworkBird, nullptr);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerStartedUsingBird(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{		
		devEnsure(ActivePlayer == nullptr);

		if (HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
			CrumbParams.AddObject(n"Player", Player);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PlayerMounted"), CrumbParams);
		}

		Player.SetCapabilityAttributeObject(ClockworkBirdTags::ClockworkBird, this);

		InteractionComp.Disable(n"PlayerMounted");

		ActivePlayer = Player;
		DismountedPlayerCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		UHazeLocomotionAssetBase LocomotionAssetTo = Game::GetCody() == Player ? CodyLocomotionAssetBase : MayLocomotionAssetBase;	
		Player.AddLocomotionAsset(LocomotionAssetTo, this, 1);

		Player.AddCapabilitySheet(PlayerSheet, EHazeCapabilitySheetPriority::OverrideAll, this);
		bActivePlayerWantsToUseBird = true;

		// Block vehicle chase on the player while the sheet is active,
		//  ClockworkBirdFlyingCameraCapability unblocks it using the Bird as the
		//  instigator when it wants to do vehicle chase.
		Player.BlockCapabilities(n"CameraVehicleChaseAssistance", this);
		bUsingVehicleChaseCam = false;

		OnPlayerMounted.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_PlayerMounted(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		SetControlSide(Player);
	}

	void PlayerStoppedUsingBird()
	{
		if (ActivePlayer == nullptr)
			return;

		ActivePlayer.ClearLocomotionAssetByInstigator(this);
		ActivePlayer.RemoveCapabilitySheet(PlayerSheet, this);
		ActivePlayer.SetCapabilityAttributeObject(ClockworkBirdTags::ClockworkBird, nullptr);

		if (!bUsingVehicleChaseCam)
			ActivePlayer.UnblockCapabilities(n"CameraVehicleChaseAssistance", this);

		ActivePlayer = nullptr;
		System::SetTimer(this, n"AfterPlayerJumpOff", 0.2f, false);

		bActivePlayerWantsToUseBird = false;
		PlayerInput = FVector::ZeroVector;
		PlayerLerpedRawInput = FVector::ZeroVector;
		PlayerLerpedRawTargetInput = FVector::ZeroVector;

		InteractionComp.Disable(n"WaitForEnable");
		InteractionComp.Enable(n"PlayerMounted");

		TriggerMovementTransition(this);

		if (HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_EnableInteraction"), CrumbParams);
		}
	}

	UFUNCTION()
	private void AfterPlayerJumpOff()
	{
		if (ActivePlayer == nullptr)
			DismountedPlayerCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_EnableInteraction(FHazeDelegateCrumbData CrumbData)
	{
		InteractionComp.EnableAfterFullSyncPoint(n"WaitForEnable");
	}

	void UseVehicleChaseCam(bool bUseChase)
	{
		if (ActivePlayer != nullptr)
		{
			if (bUsingVehicleChaseCam != bUseChase)
			{
				if (bUseChase)
					ActivePlayer.UnblockCapabilities(n"CameraVehicleChaseAssistance", this);
				else
					ActivePlayer.BlockCapabilities(n"CameraVehicleChaseAssistance", this);
				bUsingVehicleChaseCam = bUseChase;
			}
		}
	}

	bool PlayerIsUsingBird(AHazePlayerCharacter Player)const
	{
		if(ActivePlayer == Player)
			return bActivePlayerWantsToUseBird;
		return false;
	}

	bool AnyPlayerIsUsingBird()const
	{
		return ActivePlayer != nullptr;
	}

	// This will make the players capability to stop using the bird
	void MakeActivePlayerNotUseBird()
	{
		bActivePlayerWantsToUseBird = false;
	}

	bool PlayerCanQuitRiding()const
	{
		if (bIsFlying || bIsLanding)
			return false;
		if (!MoveComp.IsGrounded())
			return false;
		if (bDisableDismount)
			return false;
		if (bIsDead)
			return false;
		return true;
	}

	UFUNCTION()
	void DidSecondJump(bool bDidSecondJumpThisFrame)
	{
		bDidSecondJump = bDidSecondJumpThisFrame;
	}

	UFUNCTION()
	void IsFlapping(bool bWasFlappingThisFrame)
	{
		bIsFlapping = bWasFlappingThisFrame;
	}

	UFUNCTION(BlueprintEvent)
	void SetCameraShakeEnabled(bool bEnabled)
	{
		if (bEnabled)
		{
			FlyingCamShake = ActivePlayer.PlayCameraShake(CamShakeBird, 1.f);
		}
		else
		{
			if (FlyingCamShake != nullptr)
			{
				ActivePlayer.StopCameraShake(FlyingCamShake);	
			}			
		}
	}

	UFUNCTION(BlueprintEvent)
	void StopTimeline()
	{

	}

	void SetNewLerpedInput(FVector NewLerpedInput)
	{
		PlayerLerpedRawTargetInput = NewLerpedInput;
	}

	FVector GetPlayerRawInput()const
	{
		return PlayerLerpedRawTargetInput;
	}

	// Called from ClockworkBirdFlyingCapability when player presses "A" whilst flying
	UFUNCTION(BlueprintEvent)
	void FlapWings()
	{
		
	}

	// Called from ClockworkBirdFlyingCapability when player launches
	UFUNCTION(BlueprintEvent)
	void LaunchBird()
	{
		SetCapabilityActionState(n"AudioLaunchBird", EHazeActionState::ActiveForOneFrame);		
	}

	// Teleport the bird to a location and put it into flying mode immediately 
	UFUNCTION()
	void TeleportBirdIntoFlying(FVector Location, FRotator Rotation)
	{
		TeleportActor(Location, Rotation);
		SetCapabilityActionState(n"LaunchBirdAfterLand", EHazeActionState::Active);
	}

	UFUNCTION()
	void SetMoveCompVelocityZero()
	{
		MoveComp.Velocity = FVector(0.f);
		// PrintToScreen("SetMoveCompVelocityZero");
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBirdDeath(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnBirdRespawn(AHazePlayerCharacter Player) {}
}