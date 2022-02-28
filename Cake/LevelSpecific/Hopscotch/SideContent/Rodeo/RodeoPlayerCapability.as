import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.Hopscotch.SideContent.Rodeo.RodeoInputButton;
import Cake.LevelSpecific.Hopscotch.SideContent.Rodeo.RodeoMechanicalBull;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomRodeo;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnRodeoFinishedThrowOff(AHazePlayerCharacter Player);

class URodeoPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"GameplayAction";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<URodeoInputButton> InputButtonClass;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SuccessRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailRumble;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePlayRoomRodeo MayFeature;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePlayRoomRodeo CodyFeature;

	ULocomotionFeaturePlayRoomRodeo Feature;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BullMh;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BullIdle;

	AHazePlayerCharacter Player;
	ARodeoMechanicalBull CurrentRodeoBull;
	UHazeSkeletalMeshComponentBase BullMesh;
	
	UPROPERTY(Category = "Events")
	FOnRodeoFinishedThrowOff OnRodeoFinishedThrowOff;

	UPROPERTY(NotEditable)
	URodeoInputButton InputButtonWidget;
	TArray<FName> InputActionNames;
	default InputActionNames.Add(ActionNames::MinigameBottom);
	default InputActionNames.Add(ActionNames::MinigameLeft);
	default InputActionNames.Add(ActionNames::MinigameTop);
	default InputActionNames.Add(ActionNames::MinigameRight);
	FName CurrentlyValidName;

	FTimerHandle ChangeInputTimerHandle;
	float MinChangeInputDelay = 1.f;
	float MaxChangeInputDelay = 1.5f;
	float CurrentChangeInputDelay = 1.5f;
	float ChangeInputDelayReductionPerPress = 0.028f;

	float MinReactionTime = 0.5f;
	float MaxReactionTime = 1.4f;
	float CurrentMaxReactionTime = 1.4f;
	float CurrentTimeToReact = 1.4f;
	float ReactionTimeReductionPerPress = 0.042f;

	FScoreHudData ScoreData;

	int MaxFails = 3;
	int FailsLeft = 3;

	bool bFailed = false;

	UAnimSequence Anim;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"Rodeo"))
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"Rodeo"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bFailed)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bFailed = false;
		FailsLeft = MaxFails;
		CurrentMaxReactionTime = MaxReactionTime;
		CurrentTimeToReact = MaxReactionTime;

		CurrentRodeoBull = Cast<ARodeoMechanicalBull>(GetAttributeObject(n"RodeoBull"));
		BullMesh = CurrentRodeoBull.BullMesh;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = BullMh;
		AnimParams.BlendTime = 0.2f;
		AnimParams.bLoop = true;
		BullMesh.PlaySlotAnimation(AnimParams);

		if (HasControl())
		{
			InputButtonWidget = Cast<URodeoInputButton>(Player.AddWidget(InputButtonClass));
			InputButtonWidget.BP_SetInputIcon(InputActionNames[0]);
			InputButtonWidget.AttachWidgetToComponent(CurrentRodeoBull.BullRoot);
			InputButtonWidget.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 555.f));
			CurrentlyValidName = InputActionNames[0];

			CurrentChangeInputDelay = MaxChangeInputDelay;

			StartChangeInputDelayTimer();
		}

		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, -150.f), CameraBlend::Additive(), this);

		Player.SetAnimIntParam(n"RodeoFails", FailsLeft);
		Feature = Player.IsMay() ? MayFeature : CodyFeature;
		Player.AddLocomotionFeature(Feature);
	}

	void StartChangeInputDelayTimer()
	{
		ChangeInputTimerHandle = System::SetTimer(this, n"ChangeInput", CurrentChangeInputDelay, false);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if (bFailed)
		{
			DeactivationParams.AddActionState(n"Failed");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CurrentRodeoBull.PlayerDismounted();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		if (InputButtonWidget != nullptr)
			Player.RemoveWidget(InputButtonWidget);

		System::ClearAndInvalidateTimerHandle(ChangeInputTimerHandle);

		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);

		if (InputButtonWidget != nullptr)
			Player.RemoveWidget(InputButtonWidget);

		if (DeactivationParams.GetActionState(n"Failed"))
		{
			KnockdownActor(Player, (Player.ActorForwardVector * -1500.f) + FVector(0.f, 0.f, 1250.f));
			CurrentRodeoBull.PlayerThrownOff(Player);
		}
		else
		{
			Player.TriggerMovementTransition(this);
		}

		Player.SetCapabilityActionState(n"Rodeo", EHazeActionState::Inactive);

		Player.RemoveLocomotionFeature(Feature);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = BullIdle;
		AnimParams.BlendTime = 0.2f;
		AnimParams.bLoop = true;

		FHazeAnimationDelegate OnStartSlotAnim;
		FHazeAnimationDelegate OnFinishSlotAnim;

		BullMesh.PlaySlotAnimation(OnStartSlotAnim, OnFinishSlotAnim, AnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bFailed)
			return;

		if (Player.HasControl())
		{
			bool bInvalidInputPressed = false;
			bool bValidInputPressed = false;

			if (InputButtonWidget != nullptr)
			{
				CurrentTimeToReact -= DeltaTime;
				
				float Progress = FMath::GetMappedRangeValueClamped(FVector2D(0.f, CurrentMaxReactionTime), FVector2D(0.f, 1.f), CurrentTimeToReact);
				InputButtonWidget.BP_UpdateProgress(Progress);

				for (FName CurInput : InputActionNames)
				{
					if (WasActionStarted(CurInput) && CurInput != CurrentlyValidName)
					{
						bInvalidInputPressed = true;
					}
					else if (WasActionStarted(CurInput) &&  CurInput == CurrentlyValidName)
					{
						bValidInputPressed = true;
					}
				}

				if (bInvalidInputPressed || Progress == 0.f)
				{
					Player.PlayForceFeedback(FailRumble, false, true, n"Fail");

					if (FailsLeft == 0)
					{
						bFailed = true;
						return;
					}
					else if (GetGodMode(Player) == EGodMode::Mortal)
					{
						FailsLeft--;
					}

					InputButtonWidget.BP_Fail();
					InputButtonWidget = nullptr;
					StartChangeInputDelayTimer();
					CurrentRodeoBull.OnPlayerFail.Broadcast(Player);
				}
				else if (bValidInputPressed)
				{
					InputButtonWidget.BP_Success();
					InputButtonWidget = nullptr;
					Player.PlayForceFeedback(SuccessRumble, false, true, n"Success");
					StartChangeInputDelayTimer();
					CurrentRodeoBull.OnPlayerSuccess.Broadcast(Player);
				}
			}
		}
		
		Player.SetAnimIntParam(n"RodeoFails", FailsLeft);

		FHazeRequestLocomotionData LocoData;
		LocoData.AnimationTag = n"Rodeo";
		Player.RequestLocomotion(LocoData);

		// BullMesh.SetAnimIntParam(n"RodeoFail", FailsLeft);
	}

	UFUNCTION()
	void ChangeInput()
	{
		TArray<FName> ActionNames = InputActionNames;
		ActionNames.Shuffle();
		for (FName CurName : ActionNames)
		{
			if (CurName != CurrentlyValidName)
			{
				CurrentlyValidName = CurName;
				break;
			}
		}

		CurrentMaxReactionTime -= ReactionTimeReductionPerPress;
		CurrentMaxReactionTime = FMath::Clamp(CurrentMaxReactionTime, MinReactionTime, MaxReactionTime);
		CurrentTimeToReact = CurrentMaxReactionTime;

		CurrentChangeInputDelay -= ChangeInputDelayReductionPerPress;
		CurrentChangeInputDelay = FMath::Clamp(CurrentChangeInputDelay, MinChangeInputDelay, MaxChangeInputDelay);

		if (InputButtonWidget == nullptr)
		{
			InputButtonWidget = Cast<URodeoInputButton>(Player.AddWidget(InputButtonClass));
			InputButtonWidget.AttachWidgetToComponent(CurrentRodeoBull.BullRoot);
			InputButtonWidget.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 555.f));
		}

		InputButtonWidget.BP_SetInputIcon(CurrentlyValidName);
	}
}