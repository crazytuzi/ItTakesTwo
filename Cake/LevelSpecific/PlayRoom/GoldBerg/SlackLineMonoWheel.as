import Peanuts.Spline.SplineActor;
import Peanuts.Fades.FadeStatics;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.SlackLineBalanceBoard;
import Vino.Camera.Actors.KeepInViewCameraActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.SlacklineMonowheelAnimationDataComponent;
import Rice.TemporalLog.TemporalLogStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Camera.Actors.SplineCamera;
import Vino.Tutorial.TutorialStatics;

event void FSlacklineEvent();
event void FSlacklinePlayerEvent(AHazePlayerCharacter Player);

UCLASS(abstract)
class ASlackLineWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlayerAttachPosition;

	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY(DefaultComponent, Attach = PlayerAttachPosition)
	UHazeCharacterSkeletalMeshComponent MonowheelMeshComponent;
	default MonowheelMeshComponent.bUseBoundsFromMasterPoseComponent = true;
	default MonowheelMeshComponent.bComponentUseFixedSkelBounds = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	AKeepInViewCameraActor KeepInViewCamera;

	UPROPERTY(Category = "SlacklineWheel")
	FSlacklineEvent ReachedEndOfSlackline;

	UPROPERTY(Category = "SlacklineWheel")
	FSlacklineEvent StartedSlackline;

	UPROPERTY(Category = "SlacklineWheel")
	FSlacklineEvent SlacklineFail;

	UPROPERTY(Category = "SlacklineWheel")
	FSlacklinePlayerEvent CloseToFailSlackLine;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartBikeAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopBikeAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EnterBikeAudioEvent;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset CodyLocomotionStateMachineAsset;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset MayLocomotionStateMachineAsset;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset MonowheelLocomotionStateMachineAsset;

	UPROPERTY()
	ASplineActor SplineActor;

	UPROPERTY()
	ASlackLineBalanceBoard BalanceBoard;
	
    UHazeSplineComponent Spline;

	UPROPERTY()
	UAnimSequence FailFwdAnim_Bike;

	UPROPERTY()
	UAnimSequence FailFwdAnim_May;

	UPROPERTY()
	UAnimSequence FailFwdAnim_Cody;

	UPROPERTY()
	UAnimSequence FailBwdAnim_Bike;

	UPROPERTY()
	UAnimSequence FailBwdAnim_May;

	UPROPERTY()
	UAnimSequence FailBwdAnim_Cody;

	UPROPERTY()
	UAnimSequence Success_Cody_Top;
	
	UPROPERTY()
	UAnimSequence Success_May_Top;

	UPROPERTY()
	UAnimSequence Success_Cody_Bottom;

	UPROPERTY()
	UAnimSequence Success_May_Bottom;

	UPROPERTY(DefaultComponent, Attach = PlayerAttachPosition)
    UInteractionComponent MonowheelInteraction;

	UPROPERTY(DefaultComponent, Attach = PlayerAttachPosition)
    UInteractionComponent BalancingInteraction;

	UPROPERTY()
	UCurveFloat BalanceCurve;

	UPROPERTY()
	UCurveFloat DifficultyCurve;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> RiderCameraShake;

	UPROPERTY()
	UForceFeedbackEffect RiderRumble;

	FTimerHandle ResetToStartPositionsTimer;

	UPROPERTY()
	USlacklineMonoWheelAnimationDataComponent AnimationData;

	UPROPERTY()
    AHazePlayerCharacter PlayerOnLine;

	UPROPERTY()
	ASplineCamera SplineCamera;

	float DesiredFOV = 70;

	UPROPERTY()
	AHazePlayerCharacter PlayerOnTop;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	float CurrentMoveInput;
	float BalanceInput;
	float WheelVelocity;
	float Acceleration = 650;
	float MaxSpeed = 400;
	float DistanceAlongSpline = 0;

	bool bReachedEnd;

	bool bFinishedBike;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent DistanceAlongSplineSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent WheelVelocitySync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent BalanceLevelSync;

	bool bShouldLerpToEnd = false;
	float TimeWithoutInput;

	float BalanceLevel = 0;
	float CurrentPitch;
	FQuat StartRotation;

	UPROPERTY()
	bool IsInResetState = false;

	bool PlayerOnLineWantsToReset = false;
	bool PlayerOnBalanceBoardWantsToReset = false;
	bool HasRequestedReset = false;
	bool HasExecutedReset = false;
	bool ExecutedPositionalReset = false;
	bool bHasGivenInput = false;
	bool bBlockinput = false;

	// We can set a smooth teleport from the defaults
	default MonowheelInteraction.MovementSettings.InitializeSmoothTeleport();

	// You can override the defaults for the action shape
	default MonowheelInteraction.ActionShape.Type = EHazeShapeType::Sphere;
	default MonowheelInteraction.ActionShape.SphereRadius = 350.f;

	// You can override the defaults for the focus shape
	default MonowheelInteraction.FocusShape.Type = EHazeShapeType::Sphere;
	default MonowheelInteraction.FocusShape.SphereRadius = 1000.f;

	// The visual offset will by default be slightly above the actual interaction location,
	// you can set it to 0 offset by default if you want.
	default MonowheelInteraction.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UFUNCTION(BlueprintPure)
	bool ReachedEnd()
	{
		return bReachedEnd;
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		StartRotation = GetActorRotation().Quaternion();
		MonowheelInteraction.OnActivated.AddUFunction(this, n"OnMonoWheelInteracted");
		BalancingInteraction.OnActivated.AddUFunction(this, n"OnBalancingInteraction");
		BalancingInteraction.DisableForPlayer(Game::GetMay(), n"Startup");
		BalancingInteraction.DisableForPlayer(Game::GetCody(), n"Startup");
		Spline = UHazeSplineComponent::Get(SplineActor);
		
		BalanceBoard.OnBallIsOnBoard.AddUFunction(this, n"EnableMonoWheelInteractions");

		MonowheelInteraction.Disable(n"NoBall");
		BalancingInteraction.Disable(n"NoBall");

		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType);
	}

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType);
	}

	UFUNCTION()
	void SetBikeReachedEnd()
	{
		bReachedEnd = true;
		BalanceBoard.ReachedEnd = true;
	}

	UFUNCTION()
	void StoppedReachedEnd()
	{
		bReachedEnd = false;
		BalanceBoard.ReachedEnd = false;
	}

	UFUNCTION(NetFunction)
	void NetBeginReset(bool IsFailingFwd, bool BallFellOut)
	{
		if (!IsInResetState)
		{
			System::SetTimer(this, n"ExecuteReset", 1.2f, bLooping=false);
			BalanceBoard.IsRunningFailstate = true;
			BalanceBoard.bBlockBallRoll = true;

			Sync::FullSyncPoint(this, n"StoppedReachedEnd");

			FadeOutFullscreen(-1.f, 0.75f, 1.f);
			IsInResetState = true;
			HasRequestedReset = false;
			SlacklineFail.Broadcast();
			HazeAkComponent.HazePostEvent(StopBikeAudioEvent);

			AnimationData.FailedFwd = IsFailingFwd;
			BalanceBoard.AnimationDataComponent.FailedFwd = IsFailingFwd;
			AnimationData.FailedBwd = !IsFailingFwd;
			BalanceBoard.AnimationDataComponent.FailedBwd = !IsFailingFwd;
			
			// Block input is to make sure you cannot have input curing fadeback;
			bBlockinput = true;
		}
	}

	UFUNCTION()
	void EvaluateReset()
	{
		float DistanceToStartPos = ActorLocation.Distance(Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World));

		if (DistanceToStartPos < 200 && ExecutedPositionalReset)
		{
			
			if (HasRequestedReset == false)
			{
				if(PlayerOnLine.HasControl())
				{
					NetRequestRemoveResetState(PlayerOnLine);
					HasRequestedReset = true;
				}
				if (PlayerOnTop.HasControl())
				{
					NetRequestRemoveResetState(PlayerOnTop);
					HasRequestedReset = true;
				}
			}
		}
	}



	UFUNCTION()
	void EnableMonoWheelInteractions()
	{
		MonowheelInteraction.Enable(n"NoBall");
		BalancingInteraction.Enable(n"NoBall");
	}

	UFUNCTION()
	void ExecuteReset()
	{
		FVector ActorPosition = Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		SetActorLocation(ActorPosition);
		SetRotation(0);
		DistanceAlongSpline = 200;
		WheelVelocity = 0;
		BalanceLevel = 0;
		bHasGivenInput = false;

		bShouldLerpToEnd = false;

		Sync::FullSyncPoint(this, n"StoppedReachedEnd");

		AnimationData.Velocity = 0;
		AnimationData.WheelBalance = 0;
		AnimationData.MarbleBalance = 0;

		BalanceBoard.AnimationDataComponent.Velocity = 0;
		BalanceBoard.AnimationDataComponent.WheelBalance = 0;
		BalanceBoard.AnimationDataComponent.MarbleBalance = 0;
		
		AnimationData.LerpToZero = false;
		BalanceBoard.AnimationDataComponent.LerpToZero = false;
		AnimationData.FailedBwd = false;
		AnimationData.FailedFwd = false;
		BalanceBoard.AnimationDataComponent.FailedFwd = false;
		BalanceBoard.AnimationDataComponent.FailedBwd = false;
		ExecutedPositionalReset = true;

		ShowTutorial(PlayerOnLine);
		ShowTutorial(PlayerOnTop);

		// Block input is to make sure you cannot have input curing fadeback;
		System::SetTimer(this, n"UnblockInput", 2, false);
	}

	UFUNCTION()
	void UnblockInput()
	{
		// Block input is to make sure you cannot have input curing fadeback;
		bBlockinput = false;
	}


	UFUNCTION()
	void ShowTutorial(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		Prompt.MaximumDuration = 8;
		Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION(NetFunction)
	void NetRequestRemoveResetState(AHazePlayerCharacter Player)
	{
		if (HasControl())
		{
			if(Player == PlayerOnLine)
			{
				PlayerOnLineWantsToReset = true;
			}

			else
			{
				PlayerOnBalanceBoardWantsToReset = true;
			}

			if(PlayerOnLineWantsToReset && PlayerOnBalanceBoardWantsToReset)
			{
				NetRemoveResetState();
				
			}
		}
	}

	UFUNCTION(BlueprintPure)
	bool GetReachedEnd()
	{
		return bReachedEnd;
	}

	UFUNCTION(NetFunction)
	void NetRemoveResetState()
	{
		IsInResetState = false;
		PlayerOnLineWantsToReset = false;
		PlayerOnBalanceBoardWantsToReset = false;
		HasRequestedReset = false;
		BalanceBoard.IsRunningFailstate = false;
		BalanceBoard.HasBroadCastedFailstate = false;
		BalanceBoard.ResetBalanceboard();
		HazeAkComponent.HazePostEvent(StartBikeAudioEvent);
		ExecutedPositionalReset = false;
		ClearFullscreenFades(1.f);
	}

	UFUNCTION()
    void OnMonoWheelInteracted(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		PlayerOnLine = Player;
		Player.SetCapabilityAttributeObject(n"Slackline", this);
		BalancingInteraction.EnableForPlayer(Player.OtherPlayer, n"Startup");
		MonowheelInteraction.Disable(n"");
		ActivateSideCamera(PlayerOnLine);

		BalanceLevelSync.OverrideControlSide(PlayerOnLine);
		DistanceAlongSplineSync.OverrideControlSide(PlayerOnLine);
		WheelVelocitySync.OverrideControlSide(PlayerOnLine);

		AnimationData = Cast<USlacklineMonoWheelAnimationDataComponent>(Player.GetOrCreateComponent(USlacklineMonoWheelAnimationDataComponent::StaticClass(), n"MonowheelAnimationData"));
		AnimationData.IsOnBike = true;

		HazeAkComponent.HazePostEvent(StartBikeAudioEvent);

		Player.PlayerHazeAkComp.HazePostEvent(EnterBikeAudioEvent);

		if (Player.IsCody())
		{
			Player.AddLocomotionAsset(CodyLocomotionStateMachineAsset, this);
		}
		else
		{
			Player.AddLocomotionAsset(MayLocomotionStateMachineAsset, this);
		}

		MonowheelMeshComponent.AddLocomotionAsset(MonowheelLocomotionStateMachineAsset, this);
    }

	UFUNCTION()
    void OnBalancingInteraction(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Player.SetCapabilityAttributeObject(n"BalanceBoard", this);
		PlayerOnTop = Player;
		BalancingInteraction.Disable(n"");
		BalanceBoard.AnimationDataComponent = Cast<USlacklineMonoWheelAnimationDataComponent>(Player.GetOrCreateComponent(USlacklineMonoWheelAnimationDataComponent::StaticClass(), n"MonowheelAnimationData"));
		BalanceBoard.AnimationDataComponent.IsOnBike = false;
		BalanceBoard.SetPlayerOwner(Player);

		if (Player.IsCody())
		{
			Player.AddLocomotionAsset(CodyLocomotionStateMachineAsset, this);
		}
		else
		{
			Player.AddLocomotionAsset(MayLocomotionStateMachineAsset, this);
		}

		if(Player.HasControl())
		{
			BalanceBoard.OnBallFellOutOfBoard.AddUFunction(this, n"NetBeginReset");
		}

		AnimationData.bBothPlayersOn = true;
		StartedSlackline.Broadcast();

		ShowTutorial(PlayerOnLine);
		ShowTutorial(PlayerOnTop);
    }

	UFUNCTION(BlueprintEvent)
	void ActivateSideCamera(AHazePlayerCharacter PlayerOnLine)
	{
		if(!bFinishedBike)
		{
			FHazeFocusTarget FocusTarget;
			FocusTarget.Actor = PlayerOnLine;
			FocusTarget.WorldOffset = FVector(0,-200, 75);
			KeepInViewCamera.KeepInViewComponent.SetPrimaryTarget(FocusTarget);
			KeepInViewCamera.ActivateCamera(PlayerOnLine, 0.5f, this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void DeactivateSideCamera(AHazePlayerCharacter PlayerOnLine)
	{
		KeepInViewCamera.DeactivateCamera(PlayerOnLine);
	}

	UFUNCTION()
	void DesiredMovementInput(float MovementInput)
	{
		CurrentMoveInput = MovementInput;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFinishedBike)
			return;

		if (!IsInResetState)
		{
			if (PlayerOnLine != nullptr && PlayerOnTop != nullptr)
			{
				UpdateMovement(DeltaTime);
				UpdateBalanceLevel(DeltaTime);	
				ZoomUpdate(DeltaTime);
				HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_MonoWheelBike_Velocity_Direction", WheelVelocitySync.Value);
				HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_MonoWheelBike_Leaning_Fwd_Bwd", BalanceLevel);
				UpdateDrumRoll();
			}
		}

		else
		{
 			EvaluateReset();
		}
	}

	void UpdateDrumRoll()
	{
		float DrumRollValue;

		DrumRollValue = FMath::Max(FMath::Abs(AnimationData.WheelBalance),FMath::Abs(AnimationData.MarbleBalance));
		HazeAkComponent.SetRTPCValue("RTPC_BalanceIntensity", DrumRollValue);
	}

	void ZoomUpdate(float DeltaTime)
	{
		PlayerOnLine.ApplyFieldOfView(DesiredFOV, FHazeCameraBlendSettings());
	}

	void LerpToEndUpdate(float DeltaTime)
	{
		if (PlayerOnLine.HasControl())
		{
			
		}

		SetRotation(0);
	}

	UFUNCTION(NetFunction)
	void NetReachedEnd()
	{
		Sync::FullSyncPoint(this, n"SetBikeReachedEnd");
		ReachedEndOfSlackline.Broadcast();
		SetReachedendonBalanceBoard();
		HazeAkComponent.HazePostEvent(StopBikeAudioEvent);
	}

	UFUNCTION()
	void SetReachedendonBalanceBoard()
	{
		DeactivateSideCamera(PlayerOnLine);
		BalanceBoard.ClearCameraSettings();
		HazeAkComponent.HazePostEvent(StopBikeAudioEvent);
	}

	void UpdateMovement(float DeltaTime)
	{
		if (PlayerOnLine.HasControl())
		{
			if (ProgressPercent > 0.98f && !bShouldLerpToEnd)
			{
				NetLerpToEnd();
			}

			if (bShouldLerpToEnd)
			{
				WheelVelocity += Acceleration * DeltaTime;
				WheelVelocity = FMath::Clamp(WheelVelocity, 300, 999999);
				DistanceAlongSpline += WheelVelocity * DeltaTime;
				DistanceAlongSpline = FMath::Clamp(DistanceAlongSpline, 0, Spline.SplineLength);

				float AlphaToEnd = DistanceAlongSpline / Spline.SplineLength;

				AnimationData.WheelBalance = 0;
				AnimationData.WheelOffset = 0;
				BalanceLevel = 0;


				if (DistanceAlongSpline == Spline.SplineLength && !GetReachedEnd())
				{
					NetReachedEnd();
				}
			}

			else
			{
				float SpeedChange = Acceleration * CurrentMoveInput;
				WheelVelocity += SpeedChange * DeltaTime;

				if (FMath::Abs(CurrentMoveInput) < 0.2f)
				{
					WheelVelocity = FMath::Lerp(WheelVelocity, 0.f , DeltaTime * 3);
				}

				WheelVelocity = FMath::Clamp(WheelVelocity, -MaxSpeed, MaxSpeed);


				if (bBlockinput)
				{
					CurrentMoveInput = 0;
					WheelVelocity = 0;
				}

				if (CurrentMoveInput == 0 && bHasGivenInput)
				{
					TimeWithoutInput += DeltaTime;
				}

				else 
				{
					TimeWithoutInput = 1;
				}
			}

			if (bShouldLerpToEnd)
			{
				WheelVelocity = 0;
			}

			DistanceAlongSpline += WheelVelocity * DeltaTime;
			DistanceAlongSpline = FMath::Clamp(DistanceAlongSpline, 0, Spline.SplineLength);
			FVector ActorPosition = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocation(ActorPosition);

			DistanceAlongSplineSync.Value = DistanceAlongSpline;
			WheelVelocitySync.Value = WheelVelocity;
			AnimationData.Velocity = WheelVelocity;
			BalanceBoard.AnimationDataComponent.Velocity = WheelVelocity;
		}
		else
		{
			float DistAlongSpline = DistanceAlongSplineSync.Value;
			FVector ActorPosition = Spline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocation(ActorPosition);
			
			AnimationData.Velocity = WheelVelocitySync.Value;
			BalanceBoard.AnimationDataComponent.Velocity = WheelVelocitySync.Value;
		}
	}

	bool GetBalanceLevelIsLow() property
	{
		return FMath::Abs(BalanceLevel) > 0.35f;
	}

	void UpdateBalanceLevel(float DeltaTime)
	{
		if (PlayerOnLine.HasControl())
		{
			float LerpSpeed = DeltaTime;
			float OldBalanceLevel = BalanceLevel;
			float MinMovement = OldBalanceLevel * DeltaTime * 1.3f;

			MinMovement = FMath::Clamp(MinMovement, 0, 0.06f);
			
			float ConstantBalanceToAdd = DeltaTime * - 0.45f;



			if (BalanceLevelIsLow)
			{
				if (BalanceLevel < -0.35f && CurrentMoveInput < 0)
				{
					BalanceLevel = OldBalanceLevel + (MinMovement + CurrentMoveInput * 0.5f * DeltaTime  + ConstantBalanceToAdd * 0.2f) * (0.75f * TimeWithoutInput * 1.2f);
				}
				else if (BalanceLevel > 0.35f && CurrentMoveInput > 0)
				{
					BalanceLevel = OldBalanceLevel + (MinMovement + CurrentMoveInput * 0.5f * DeltaTime + ConstantBalanceToAdd * 1.75f)  * (0.75f * TimeWithoutInput * 1.2f);
				}
				else
				{
					BalanceLevel = OldBalanceLevel + (MinMovement + CurrentMoveInput * 2.f * DeltaTime  + ConstantBalanceToAdd) * (0.75f * TimeWithoutInput * 1.2f);	
				}
			}

			else
			{
				BalanceLevel = OldBalanceLevel + (MinMovement + CurrentMoveInput * DeltaTime  + ConstantBalanceToAdd) * (0.75f * TimeWithoutInput * 1.2f);
			}
			
			BalanceLevel = FMath::Clamp(BalanceLevel, -1.f, 1.f);

			if(bShouldLerpToEnd)
			{
				BalanceLevel = 0;
			}

			if (BalanceLevelIsLow)
			{
				PlayerOnLine.PlayCameraShake(RiderCameraShake, 1);
				PlayerOnLine.PlayForceFeedback(RiderRumble, true, true, n"RiderRumble");
				CloseToFailSlackLine.Broadcast(PlayerOnLine);				
				DesiredFOV = 45.f;
			}
			else
			{
				ActivateSideCamera(PlayerOnLine);
				PlayerOnLine.StopAllCameraShakes();
				PlayerOnLine.StopForceFeedback(RiderRumble, n"RiderRumble");
				DesiredFOV = 70.f;
			}
			if (BalanceLevel == 1 || BalanceLevel == -1)
			{
				if (!IsInResetState)
				{
					if (BalanceLevel == 1)
					{
						NetBeginReset(true, false);				
					}
					else
					{
						NetBeginReset(false, false);
					}
				}
			}
			else
			{
				SetRotation(BalanceLevel);
			}

			if (FMath::Abs(CurrentMoveInput) > 0.01f)
			{
				bHasGivenInput = true;
			}
			
			if (!bHasGivenInput)
			{
				BalanceLevel = 0;
			}

			AnimationData.WheelBalance = BalanceLevel;
			BalanceBoard.AnimationDataComponent.WheelBalance = BalanceLevel;
			BalanceLevelSync.Value = BalanceLevel;
		}
		
		else
		{
			if (!IsInResetState)
			{
				BalanceLevel = BalanceLevelSync.Value;
				AnimationData.WheelBalance = BalanceLevel;
				BalanceBoard.AnimationDataComponent.WheelBalance = BalanceLevel;
			}
			
			SetRotation(BalanceLevel);
		}
	}

	float GetProgressPercent() property
	{
		return DistanceAlongSpline / Spline.SplineLength;
	}

	void SetRotation(float RotationPercent) property
	{
		AnimationData.WheelOffset = BalanceCurve.GetFloatValue(RotationPercent);
	}

	UFUNCTION(BlueprintCallable)
	void ReachedEndWithBall()
	{
		bFinishedBike = true;
		BalanceBoard.ReleaseMarbleBall();
		SetActorTickEnabled(false);
		PlayerOnLine.SetCapabilityAttributeObject(n"Slackline", nullptr);
		PlayerOnTop.SetCapabilityAttributeObject(n"BalanceBoard", nullptr);
		KeepInViewCamera.DeactivateCamera(PlayerOnLine);
		KeepInViewCamera.DeactivateCamera(PlayerOnTop);
		PlayerOnLine.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		PlayerOnTop.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		if (PlayerOnLine.IsCody())
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayerOnLine.PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Success_Cody_Bottom);
			PlayerOnTop.PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Success_May_Top);
		}
		else
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			OnBlendingOut.BindUFunction(this, n"RagDollMonowheel");
			PlayerOnLine.PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Success_May_Bottom);
			PlayerOnTop.PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Success_Cody_Top);
		}
	}

	UFUNCTION()
	void RagDollMonowheel()
	{
		MonowheelMeshComponent.SetSimulatePhysics(true);
		MonowheelMeshComponent.AddImpulse(FVector::RightVector * 0.0112f, bVelChange = true);
		MonowheelMeshComponent.SetEnableGravity(true);
	}

	UFUNCTION(NetFunction)
	void NetLerpToEnd()
	{
		bShouldLerpToEnd = true;
		AnimationData.LerpToZero = true;
		BalanceBoard.AnimationDataComponent.LerpToZero = true;
	}
}