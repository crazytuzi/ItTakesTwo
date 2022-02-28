import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Hopscotch.FidgetspinnerActor;
import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Grinding.GrindingActivationPointComponent;

class UFidgetSpinnerAbilityCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FidgetSpinner");

	default CapabilityDebugCategory = n"FidgetSpinner";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	USwingingComponent SwingComp;
	UUserGrindComponent GrindingComp;
	UGrindingActivationComponent GrindActivationComp;

	UPROPERTY()
	UCurveFloat ZCurveFloat;

	UPROPERTY()
	UCurveFloat FallSpeedCurve;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset LaunchCamSettings;

	UPROPERTY()
	UBlendSpaceBase MayBlendSpace;

	UPROPERTY()
	UBlendSpaceBase CodyBlendSpace;

	UPROPERTY()
	UAnimSequence CodyEnter;

	UPROPERTY()
	UAnimSequence CodyEnterAir;

	UPROPERTY()
	UAnimSequence CodyExit;

	UPROPERTY()
	UAnimSequence CodyExitAir;

	UPROPERTY()
	UAnimSequence MayEnter;

	UPROPERTY()
	UAnimSequence MayEnterAir;

	UPROPERTY()
	UAnimSequence MayExitAir;

	UPROPERTY()
	UAnimSequence MayExit;

	UPROPERTY()
	TSubclassOf<AFidgetSpinnerActor> FidgetClassToSpawn;

	UPROPERTY()
    TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY()
    TSubclassOf<UCameraShakeBase> FallCamShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandCamShake;

   	UPROPERTY()
    UForceFeedbackEffect LandRumble;

	UPROPERTY()
    UForceFeedbackEffect LaunchRumble;

	UPROPERTY()
	UForceFeedbackEffect PreLaunchRumble;

	UPROPERTY()
	UAnimSequence MayLandAnim;

	UPROPERTY()
	UAnimSequence CodyLandAnim;

	UPROPERTY()
	FText TutorialText;

	AFidgetSpinnerActor FidgetSpinner;
	UPlayerRespawnComponent RespawnComp;

	FHazeFrameMovement FrameMov;

	FHazePointOfInterest LaunchPointOfInterest;

	FVector TargetHorizontalMoveDelta; 
	FVector CurrentHorizontalMoveDelta;
	FVector HorizontalMoveDeltaLastTick;
	
	FVector StartingVerticalVelocity = FVector(0.f, 0.f, -350.f);
	FVector MaxVerticalVelocity = FVector(0.f, 0.f, -6000.f);;
	FVector TargetVerticalVelocity;
	FVector CurrentVerticalVelocity;
	FVector DownwardVelocityAtActiviation;

	FVector2D TargetBlendSpaceInput;

	bool bFidgetCameraDoOnce;
	bool bWasActionStarted;
	bool bWasLaunched;
	bool bCurrentlyLaunching;
	bool bHasPlayerLaunchRumble;
	bool bHasBeenGrounded = false;
	bool bChargeEventPosted = false;
	bool bFlewUpInAirEventPosted = false;
	bool bFastBoostActive = false;
	bool bFastBoostTimerActive = false;
	bool bCanDeactivate = false;
	float FastBoostTimer = 0.f;

	FRotator TargetRotation;

	float LaunchDurationMax;
	float SlowDownFallTime;
	float Time = 99.f;
	float HoldTriggerTime = 99.f;
	float FallTime;
	float CurrentRoll;
	float CurrentPitch;
	float HorizontalSpeed = 1300.f;
	float HorizontalSpeedMultiplier;
	float CanDeactivateTimer = 1.f;
	float RespawnCooldown = 0.f;

	float NotifyFidgetOfVoTimer = 0.f;
	bool bHasNotifiedFidgetOfVo = false;

	float NotifyFidgetOfBeingUsedTimer = 0.f;
	bool bHasNotifiedFidgetOfBeingUsed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCharacterMovementCapability::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = USwingingComponent::Get(Owner);
		GrindingComp = UUserGrindComponent::Get(Owner);
		GrindActivationComp = UGrindingActivationComponent::Get(Owner);

		RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnRespawn.AddUFunction(this, n"PlayerRespawned");

		LaunchDurationMax = 0.75f;
		
		FTutorialPrompt Prompt;
		Prompt.MaximumDuration = 10.f;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Action = n"PrimaryLevelAbility";
		Prompt.Text = TutorialText;
		ShowTutorialPrompt(Player, Prompt, this);

		Player.BlockCapabilities(n"Skydive", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(n"Skydive", this);
		RespawnComp.OnRespawn.Unbind(this, n"PlayerRespawned");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (RespawnCooldown > 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsPlayerDead())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(n"CharacterBouncePadCapability"))
			return EHazeNetworkActivation::DontActivate;

		if (SwingComp.GetActiveSwingPoint() != nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (GrindingComp.ActiveGrindSplineData.GrindSpline != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::SwingAttach))
			return EHazeNetworkActivation::DontActivate;
		
		if (IsActioning(ActionNames::PrimaryLevelAbility) && bWasActionStarted)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

		else
        	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
			
		if (RespawnCooldown > 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (bCurrentlyLaunching)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (Player.IsAnyCapabilityActive(n"CharacterBouncePadCapability"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (SwingComp.GetActiveSwingPoint() != nullptr)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (GrindingComp.ActiveGrindSplineData.GrindSpline != nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(ActionNames::SwingAttach))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsGrounded() && Time > LaunchDurationMax)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (HoldTriggerTime < .75f)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(n"LedgeGrab", this);
		Player.PlayBlendSpace(Player == Game::GetCody() ? CodyBlendSpace : MayBlendSpace);
		Player.TriggerMovementTransition(this);
		Player.SetCapabilityActionState(n"BananaBounce", EHazeActionState::Inactive);
		
		bCurrentlyLaunching = false;
		bHasPlayerLaunchRumble = false;
		

		HorizontalMoveDeltaLastTick = FVector::ZeroVector;
		TargetHorizontalMoveDelta = FVector::ZeroVector;
		HorizontalSpeedMultiplier = 0.f;
		CurrentHorizontalMoveDelta = FVector::ZeroVector;
		
		if (!bWasLaunched)
		{
			bCanDeactivate = true;
			bHasBeenGrounded = false;
			HoldTriggerTime = 0.f;
			bWasLaunched = false;
			
			UAnimSequence AnimToPlay;
			AnimToPlay = Player == Game::GetCody() ? CodyEnter : MayEnter;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay);
		} else 
		{
			bCanDeactivate = false;
			bWasLaunched = true;
			//HoldTriggerTime = 99.f;
			Time = 99.f;
			UAnimSequence AnimToPlay;
			AnimToPlay = Player == Game::GetCody() ? CodyEnterAir : MayEnterAir;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay);
			HorizontalMoveDeltaLastTick = MoveComp.GetActualVelocity();
		}

		Player.PlayForceFeedback(PreLaunchRumble, true, true, n"Fidget");

		bFidgetCameraDoOnce = false;

		FHazeCameraBlendSettings LaunchBlend;
		LaunchBlend.BlendTime = 1.75f;

		if (!bWasLaunched)
		{
			LaunchPointOfInterest.FocusTarget.WorldOffset = FVector(Player.GetActorLocation() + FVector(0.f, 0.f, 3200.f) + Player.GetActorForwardVector() * 450.f);
			LaunchPointOfInterest.Blend.BlendTime = 1.5f;
			LaunchPointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
			Player.ApplyCameraSettings(LaunchCamSettings, LaunchBlend, this);
			Player.PlayCameraShake(LaunchCamShake, 1.f);
			TargetVerticalVelocity = StartingVerticalVelocity;
			FallTime = 0.f;
		}

		if (FidgetSpinner == nullptr)
			FidgetSpinner = Cast<AFidgetSpinnerActor>(SpawnActor(FidgetClassToSpawn, Player.GetActorLocation()));		
		
		FidgetSpinner.AttachToPlayer(Player, false);

		DownwardVelocityAtActiviation = FVector(0.f, 0.f, MoveComp.Velocity.Z);
		CurrentVerticalVelocity = FVector(MoveComp.Velocity);
		TargetHorizontalMoveDelta = FVector::ZeroVector;
		CurrentHorizontalMoveDelta = FVector::ZeroVector;
		HorizontalSpeedMultiplier = 0.f;

		TargetRotation = Player.GetActorRotation();

		SlowDownFallTime = 0.f;
		if (!bWasLaunched)
			Time = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (HoldTriggerTime < 0.65f && !bWasLaunched)
		{
			FidgetSpinner.InteruptedCharge();
		} 
		else 
		{
			FidgetSpinner.StoppedSpinning();
		}
		
		bHasNotifiedFidgetOfVo = false;
		NotifyFidgetOfVoTimer = 0.f;
		HoldTriggerTime = 0.f;
		Player.MeshOffsetComponent.ResetWithTime();
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(n"LedgeGrab", this);
		Player.StopAllCameraShakes();
		Player.StopBlendSpace();
		Player.ClearCameraSettingsByInstigator(this, 10.f);
		bChargeEventPosted = false;
		bFlewUpInAirEventPosted = false;

		UAnimSequence AnimToPlay;
		AnimToPlay = Player == Game::GetCody() ? CodyExitAir : MayExitAir;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay);
		
		if (FidgetSpinner != nullptr)
		{
			FidgetSpinner.AttachToPlayer(Player, true);
		}

		if (MoveComp.IsGrounded() && bWasLaunched)
		{
			Player.PlayCameraShake(LandCamShake);
			Player.PlayForceFeedback(LandRumble, false, true, n"Fidget");

			UAnimSequence Animation;
			Animation = Player == Game::GetCody() ? CodyExit : MayExit;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animation);
		} else 
		{
			UAnimSequence Animation;
			Animation = Player == Game::GetCody() ? CodyExitAir : MayExitAir;
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animation);
		}

		Player.StopForceFeedback(PreLaunchRumble, n"Fidget");

		if (!MoveComp.IsGrounded())
			Player.SetCapabilityActionState(n"FidgetSpinnerAirControl", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bWasActionStarted = WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 1.f);	
		RespawnCooldown -= DeltaTime;

		if (MoveComp.IsGrounded() && !IsActive() && !Player.IsAnyCapabilityActive(GrindingCapabilityTags::Movement))
		{
			TargetVerticalVelocity = StartingVerticalVelocity;
			FallTime = 0.f;
			bHasBeenGrounded = true;
			bWasLaunched = false;
		}

		if (Player.IsAnyCapabilityActive(n"CharacterBouncePadCapability") || Player.IsAnyCapabilityActive(n"GrindingMovement"))
		{
			FallTime = 0.f;
			bHasBeenGrounded = false;
			bWasLaunched = true;
		}

		UObject Fidget;
		if (ConsumeAttribute(n"FidgetSpinner", Fidget))
		{
			FidgetSpinner = Cast<AFidgetSpinnerActor>(Fidget);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsActioning(n"FidgetBoostFast") && !bFastBoostActive)
		{
			bFastBoostActive = true;
			bFastBoostTimerActive = true;
			FastBoostTimer = 1.f;
		}

		if (bFastBoostActive)
		{
			FastBoostTimer -= DeltaTime;
			if (FastBoostTimer <= 0.f)
			{
				bFastBoostActive = false;
				bFastBoostActive = false;
				Player.SetCapabilityActionState(n"FidgetBoostFast", EHazeActionState::Inactive);
			}
		}

		if (!bHasNotifiedFidgetOfVo)
		{
			NotifyFidgetOfVoTimer += DeltaTime;
			if (NotifyFidgetOfVoTimer > 2.f)
			{
				bHasNotifiedFidgetOfVo = true;
				FidgetSpinner.CanPlayFidgetVO();
			}
		}

		if (!bHasNotifiedFidgetOfBeingUsed)
		{
			NotifyFidgetOfBeingUsedTimer += DeltaTime;
			if (NotifyFidgetOfBeingUsedTimer > 1.f)
			{
				bHasNotifiedFidgetOfBeingUsed = true;
				FidgetSpinner.FidgetUsedFirstTime();
			}
		}

		HoldTriggerTime += DeltaTime;

		if (HoldTriggerTime < 0.65f && !bWasLaunched)
		{
			FrameMov = MoveComp.MakeFrameMovement(n"FidgetSpinner");

			if (!bChargeEventPosted)
			{
				bChargeEventPosted = true;
				FidgetSpinner.StartedCharingSpinner();
			}
			
			if(HasControl())
			{
				ApplyLaunchVerticalFrameMove(DeltaTime);
			} else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				FrameMov.ApplyDeltaWithCustomVelocity(ConsumedParams.DeltaTranslation, ConsumedParams.Velocity);	
			}

			if (MoveComp.CanCalculateMovement())
			{
				FrameMov.ApplyTargetRotationDelta();
				MoveCharacter(FrameMov, FeatureName::AirMovement);
				CrumbComp.LeaveMovementCrumb();
			}

			return;
		}

		FidgetSpinner.CurrentVelocity(MoveComp.Velocity);

		bWasLaunched = true;

		if (!bFlewUpInAirEventPosted)
		{
			bFlewUpInAirEventPosted =  true;
			FidgetSpinner.FlewUpInAir();
		}

		PlayLaunchRumble();

		if (Time < LaunchDurationMax)
			bCurrentlyLaunching = true;

		else
		{
			bCurrentlyLaunching = false;
			FallTime += DeltaTime;
		}
		
		Time += DeltaTime;
		
		if (SlowDownFallTime < 1.f)
			SlowDownFallTime += DeltaTime * 3.5f;

		if (FidgetSpinner != nullptr)
		{
			FidgetSpinner.SpinFidget(FMath::GetMappedRangeValueClamped(FVector2D(StartingVerticalVelocity.Z, MaxVerticalVelocity.Z), FVector2D(2000.f, 5.f), TargetVerticalVelocity.Z));
		}
	
		FrameMov = MoveComp.MakeFrameMovement(n"FidgetSpinner");
		
		if(HasControl())
		{
			ApplyHorizontalFrameMove(DeltaTime);
			ApplyVerticalFrameMove(DeltaTime);
			SetBlendSpaceValues();	
			SetPlayerRotationOffset(DeltaTime);
		} else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMov.ApplyDeltaWithCustomVelocity(ConsumedParams.DeltaTranslation, ConsumedParams.Velocity);
			MoveComp.SetTargetFacingRotation(ConsumedParams.Rotation);	
			Player.SetBlendSpaceValues(TargetBlendSpaceInput.X, TargetBlendSpaceInput.Y);
		}

		if (MoveComp.CanCalculateMovement())
		{
			FrameMov.ApplyTargetRotationDelta();
			MoveCharacter(FrameMov, FeatureName::AirMovement);
			CrumbComp.LeaveMovementCrumb();
		}

		if (!HasControl())
		{
			if (TargetBlendSpaceInput.Size() > 0)
			{
				FRotator TargetRemoveRollPitch = FRotator(InterpCurrentPitch(DeltaTime) * -25.f, Player.GetCurrentlyUsedCamera().GetWorldRotation().Yaw, InterpCurrentRoll(DeltaTime) * 35.f); 
				Player.MeshOffsetComponent.OffsetRotationWithSpeed(TargetRemoveRollPitch, 5.f);	
			} 
			else	
			{	
				Player.MeshOffsetComponent.ResetRotationWithSpeed(0.8f);
			}
		}
	}

	void ApplyFidgetCameraSettings()
	{
		if (!bFidgetCameraDoOnce)
		{
			bFidgetCameraDoOnce = true;	
			Player.ClearCameraSettingsByInstigator(this);
			FHazeCameraBlendSettings Blend;		
			NetApplyFidgetCameraSettings(CamSettings, Blend, this);
		}
	}

	UFUNCTION(NetFunction)
	void NetApplyFidgetCameraSettings(UHazeCameraSpringArmSettingsDataAsset NewCamSettings, FHazeCameraBlendSettings NewBlend, UObject Instigator)
	{
		Player.ApplyCameraSettings(NewCamSettings, NewBlend, Instigator);	
	}

	float InterpCurrentRoll(float DeltaTime)
	{
		if (HasControl())
		{
			CurrentRoll = FMath::FInterpTo(CurrentRoll,	GetAttributeVector(AttributeVectorNames::LeftStickRaw).X, DeltaTime, 5.f);
			return CurrentRoll;
		} else
		{
			CurrentRoll = FMath::FInterpTo(CurrentRoll, TargetBlendSpaceInput.X, DeltaTime, 5.f);
			return CurrentRoll;
		}
	}

	float InterpCurrentPitch(float DeltaTime)
	{
		if (HasControl())
		{
			CurrentPitch = FMath::FInterpTo(CurrentPitch, GetAttributeVector(AttributeVectorNames::LeftStickRaw).Y, DeltaTime, 5.f);
			return CurrentPitch;
		} else 
		{
			CurrentPitch = FMath::FInterpTo(CurrentPitch, TargetBlendSpaceInput.Y, DeltaTime, 5.f);
			return CurrentPitch;
		}
	}

	FVector InterpCurrentVerticalVelocity(float DeltaTime)
	{
		CurrentVerticalVelocity = FMath::VInterpTo(CurrentVerticalVelocity, TargetVerticalVelocity, DeltaTime, 8.0f);
		return CurrentVerticalVelocity;
	}

	FVector InterpCurrentHorizontalMoveDelta(float DeltaTime)
	{
		TargetHorizontalMoveDelta = GetAttributeVector(AttributeVectorNames::MovementDirection) * (HorizontalSpeed + HorizontalSpeedMultiplier);
		CurrentHorizontalMoveDelta = FMath::VInterpTo(HorizontalMoveDeltaLastTick, TargetHorizontalMoveDelta, DeltaTime, 2.f);
		HorizontalSpeedMultiplier = FVector2D(InterpCurrentRoll(DeltaTime), InterpCurrentPitch(DeltaTime)).Size() * 1500.f;
		HorizontalMoveDeltaLastTick = CurrentHorizontalMoveDelta;		
		return CurrentHorizontalMoveDelta;
	}

	void PlayFallCamShake()
	{
		Player.PlayCameraShake(FallCamShake, FMath::GetMappedRangeValueClamped(FVector2D(StartingVerticalVelocity.Z, MaxVerticalVelocity.Z), FVector2D(0.f, 2.f), TargetVerticalVelocity.Z));
	}

	void SetBlendSpaceValues()
	{
		FVector BlendSpaceInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		Player.SetBlendSpaceValues(BlendSpaceInput.X, BlendSpaceInput.Y);
		FVector2D NewBlendSpace2D = FVector2D(BlendSpaceInput.X, BlendSpaceInput.Y);
		NetSyncBlendSpace(NewBlendSpace2D);

	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncBlendSpace(FVector2D NewBlendSpaceInput)
	{
		TargetBlendSpaceInput = NewBlendSpaceInput;
	}

	void ApplyHorizontalFrameMove(float DeltaTime)
	{
		FrameMov.ApplyDelta(InterpCurrentHorizontalMoveDelta(DeltaTime) * DeltaTime);
	}

	void ApplyVerticalFrameMove(float DeltaTime)
	{
		if (Time < LaunchDurationMax)
		{
			FrameMov.ApplyVelocity(FVector(0.f, 0.f, ZCurveFloat.GetFloatValue(Time)));
		}
		
		else
		{
			if(IsActioning(n"FidgetBoost") || bFastBoostActive)
			{
				float VerticalInterpSpeed = bFastBoostActive ? 4.f : 2.f;
				TargetVerticalVelocity = FMath::VInterpTo(TargetVerticalVelocity, FVector(0.f, 0.f, 3500.f), DeltaTime, VerticalInterpSpeed);
				FallTime = 0.f;
			} else 
			{
				TargetVerticalVelocity = FMath::VLerp(StartingVerticalVelocity, MaxVerticalVelocity, FVector(0.f, 0.f, FallSpeedCurve.GetFloatValue(FallTime)));
			}
			
			FrameMov.ApplyVelocity(InterpCurrentVerticalVelocity(DeltaTime));
			ApplyFidgetCameraSettings();
			PlayFallCamShake();
		}
	}

	void ApplyLaunchVerticalFrameMove(float DeltaTime)
	{
		FrameMov.ApplyVelocity(FVector(0.f, 0.f, -500.f));				
	}

	void SetPlayerRotationOffset(float DeltaTime)
	{
		if (GetAttributeVector(AttributeVectorNames::LeftStickRaw).Size() > 0)
			{
				TargetRotation = FRotator(InterpCurrentPitch(DeltaTime) * -25.f, Player.GetCurrentlyUsedCamera().GetWorldRotation().Yaw, InterpCurrentRoll(DeltaTime) * 35.f); 
				MoveComp.SetTargetFacingRotation(TargetRotation, 5.f);
				Player.MeshOffsetComponent.OffsetRotationWithSpeed(TargetRotation, 5.f);
				
			} 
			else	
			{
				MoveComp.SetTargetFacingRotation(FMath::RInterpTo(FRotator(0.f, Player.GetCurrentlyUsedCamera().GetWorldRotation().Yaw, 0.f), TargetRotation, DeltaTime, 0.2f), 0.8f);
				Player.MeshOffsetComponent.ResetRotationWithSpeed(0.8f);
			}
	}

	void PlayLaunchRumble()
	{
		if (!bHasPlayerLaunchRumble)
		{
			bHasPlayerLaunchRumble = true;
			Player.StopForceFeedback(PreLaunchRumble, n"Fidget");
			Player.PlayForceFeedback(LaunchRumble, false, true, n"Fidget");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		RespawnCooldown = 1.f;	
	}
}
