import Vino.Interactions.InteractionComponent;
import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Vino.Movement.Components.MovementComponent;
import Vino.LevelSpecific.Garden.ValveTurnInteractionLocomotionFeature;
import Vino.LevelSpecific.Garden.ValveTurnData;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

class UValveTurnInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Interaction);
	default CapabilityTags.Add(n"ValveInteraction");
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	const float InvalidInputTimeMax = 0.65f;

	AHazePlayerCharacter PlayerOwner;
	AValveTurnInteractionActor InteractionActor;
	UValveTurnInteractionLocomotionFeature ActiveFeature;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	bool bHadStickInputLastFrame = false;
	FQuat LastStickRotation;

	EValveTurnInteractionAnimationDirection CurrentInputType = EValveTurnInteractionAnimationDirection::Unset;
	EValveTurnInteractionAnimationDirection LastValidInputDirection = EValveTurnInteractionAnimationDirection::Unset;

	float LastFrameRotationValue = 0;
	float LastTimeChangeRotationValue = 0;
	float LastGameTimeValueChanged = 0;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			if(!IsActive() && !IsBlocked() && InteractionActor == nullptr)
			{
				UObject Temp;
				if(ConsumeAttribute(n"ValveToTurn", Temp))
				{
					InteractionActor = Cast<AValveTurnInteractionActor>(Temp);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(InteractionActor == nullptr)	
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(InteractionActor == nullptr)	
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(InteractionActor.SyncValue >= InteractionActor.MaxValue && InteractionActor.bForceEndOnFinsihed)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(GetActionStatus(n"ForceEndValveTurn") == EActionStateStatus::Active)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"ValveToTurn", InteractionActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		InteractionActor = Cast<AValveTurnInteractionActor>(ActivationParams.GetObject(n"ValveToTurn"));
		PlayerOwner.TriggerMovementTransition(this);
		PlayerOwner.BlockMovementSyncronization(this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
		SetMutuallyExclusive(CapabilityTags::Movement, true);

		if(PlayerOwner.IsMay())
			ActiveFeature = InteractionActor.MayFeature;
		else
			ActiveFeature = InteractionActor.CodyFeature;

		PlayerOwner.Mesh.SetAnimObjectParam(ValveTurnTags::InteractionActor, InteractionActor);
		PlayerOwner.AddLocomotionFeature(ActiveFeature);

		LastGameTimeValueChanged = Time::GetGameTimeSeconds();
		LastFrameRotationValue = InteractionActor.SyncComponent.Value;
		LastTimeChangeRotationValue = LastFrameRotationValue;

		if(InteractionActor.bShowTutorialWidget)
		{
			// Tutorial
			FTutorialPrompt TurnPrompt;
			if(InteractionActor.InputType == EValveTurnInputType::Rotating)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
				{
					TurnPrompt.Text = InteractionActor.CW_TutorialDisplayText;
					TurnPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Rotate_CW;
					TurnPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::KeyBoard_LeftRight;
				}
				else
				{
					TurnPrompt.Text = InteractionActor.CCW_TutorialDisplayText;
					TurnPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Rotate_CCW;
					TurnPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::KeyBoard_LeftRight;
				}
			}
			else if(InteractionActor.InputType == EValveTurnInputType::LeftRight)
			{
				TurnPrompt.Text = InteractionActor.Input_TutorialDisplayText;
				TurnPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
				TurnPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::KeyBoard_LeftRight;
			}
			else if(InteractionActor.InputType == EValveTurnInputType::UpDown)
			{
				TurnPrompt.Text = InteractionActor.Input_TutorialDisplayText;
				TurnPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
				TurnPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::KeyBoard_UpDown;
			}

			ShowTutorialPrompt(PlayerOwner, TurnPrompt, this);
		}

		if (!InteractionActor.bUseCustomCancelText)
			ShowCancelPrompt(PlayerOwner, this);
		else
			ShowCancelPromptWithText(PlayerOwner, this, InteractionActor.CustomCancelText);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockMovementSyncronization(this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
		SetMutuallyExclusive(CapabilityTags::Movement, false);

		const bool bIsValidEnding = DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural;
		if(InteractionActor != nullptr)
		{
			InteractionActor.EndInteraction(PlayerOwner);
		}
			
		// Remove buttons in relation to cancel so we don't dubbelpress
		if(bIsValidEnding)
			PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		PlayerOwner.RemoveLocomotionFeature(ActiveFeature);	
		ActiveFeature = nullptr;
		InteractionActor = nullptr;
		bHadStickInputLastFrame = false;
		LastValidInputDirection = EValveTurnInteractionAnimationDirection::Unset;
		RemoveTutorialPromptByInstigator(PlayerOwner, this);

		RemoveCancelPromptByInstigator(PlayerOwner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Always update the input from the players controlside
		if(HasControl())
		{	
			const EValveTurnInteractionAnimationDirection LastInputType = CurrentInputType;
			UpdateControlInputData(DeltaTime);
			if(LastInputType != CurrentInputType)
			{
				NetReplicateControlInputData(CurrentInputType);
			}
		}

		// Some interactions want to update the rotation from the world side
		if(IsControllingSide())
		{
			UpdateInteractionTurnValueToReplicate(DeltaTime);
			
			// We have finished the interaction and will force it to the other side
			if(InteractionActor.SyncValue >= InteractionActor.MaxValue 
				&& LastFrameRotationValue < InteractionActor.MaxValue)
			{
				NetControlsideHasFinished();
			}
		}

		// Update the animation on the interaction actor
		UpdateInteractionActor();
			
		float PlayerProgress = InteractionActor.SyncValue /18;
		PlayerProgress = Math::FWrap(PlayerProgress,0.f,2.f);
		PlayerOwner.Mesh.SetAnimFloatParam(n"RotationValue",PlayerProgress);
	
		// Finalize 
		if(MoveComp.CanCalculateMovement())
		{
			FHazeRequestLocomotionData AnimationRequest;
			AnimationRequest.AnimationTag = ActiveFeature.Tag;
			PlayerOwner.RequestLocomotion(AnimationRequest);
	
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(AnimationRequest.AnimationTag);
			MoveComp.Move(FrameMove);		
		}
	
		if(IsDebugActive())
		{
			FString Debug = "";
			Debug += "Valve Value: " + InteractionActor.SyncValue + " / " + InteractionActor.MaxValue + "\n";
			Debug += "Can finish: " + InteractionActor.bForceEndOnFinsihed + "\n";
			Debug += "Status: " + InteractionActor.PlayerStatus + " | AnimSpeed: " + InteractionActor.AnimationSpeed + "\n";
			PrintToScreen(Debug);
		}	

		const float TimeSinceValid = Time::GetGameTimeSince(LastGameTimeValueChanged);
		
		// PrintToScreen("Value: " + InteractionActor.SyncComponent.Value
		// +"\nLastFrameRotationValue: " + LastFrameRotationValue 
		// +"\nLastTimeChangeRotationValue: " + LastTimeChangeRotationValue
		// +"\nTimeSinceValid: " + TimeSinceValid);

		// This is to remove the floating point error in network replication
		if(FMath::Abs(InteractionActor.SyncComponent.Value - LastTimeChangeRotationValue) > KINDA_SMALL_NUMBER)
		{
			LastTimeChangeRotationValue = InteractionActor.SyncComponent.Value;
			LastGameTimeValueChanged = Time::GetGameTimeSeconds();
		}

		LastFrameRotationValue = InteractionActor.SyncComponent.Value;
		if(CurrentInputType != EValveTurnInteractionAnimationDirection::Unset)
			LastValidInputDirection = CurrentInputType;
	}

	void UpdateInteractionActor() const
	{
		InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::None;
		InteractionActor.AnimationSpeed = 0;
		InteractionActor.InputStatus = CurrentInputType;
		
		bool bSameRotationValue = true;
		if(IsControllingSide())
		{
			bSameRotationValue = InteractionActor.SyncValue == LastFrameRotationValue;
		}
		else
		{
			bSameRotationValue = Time::GetGameTimeSince(LastGameTimeValueChanged) > 0.05f + (Network::GetPingRoundtripSeconds() * 0.5f);
		}

		// Are we struggling
		bool bIsStruggling = false;
		if(CurrentInputType != EValveTurnInteractionAnimationDirection::Unset
			&& !InteractionActor.bLoopRotation
			&& bSameRotationValue)
	 	{
			if(LastValidInputDirection == CurrentInputType)
				bIsStruggling = true;
		}

		if(bIsStruggling)
		{
			if(InteractionActor.bClockwiseIsCorrectInput)
			{
				// Struggle status
				if(CurrentInputType == EValveTurnInteractionAnimationDirection::Valid)
					InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::LeftStruggle;
				else
					InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::RightStruggle;
			}
			else
			{
				// Struggle status
				if(CurrentInputType == EValveTurnInteractionAnimationDirection::Valid)
					InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::LeftStruggle;
				else
					InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::RightStruggle;
			}
		}
		else
		{
			// Check at end
			if(bSameRotationValue)
			{
				if(LastFrameRotationValue < KINDA_SMALL_NUMBER)
				{
					if(InteractionActor.bClockwiseIsCorrectInput)
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::LeftEnd;
					else
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::RightEnd;
				}
				else if(LastFrameRotationValue > InteractionActor.MaxValue - KINDA_SMALL_NUMBER)
				{
					if(InteractionActor.bClockwiseIsCorrectInput)
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::RightEnd;
					else
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::LeftEnd;
				}
			}
			else
			{
				if(CurrentInputType == EValveTurnInteractionAnimationDirection::Valid)
				{
					InteractionActor.AnimationSpeed = (InteractionActor.IncreaseValueSpeed / InteractionActor.MaxValue) * 5.f;
					if(InteractionActor.bClockwiseIsCorrectInput)
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::Right;
					else
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::Left;
				}
				else if(CurrentInputType == EValveTurnInteractionAnimationDirection::Invalid)
				{
					InteractionActor.AnimationSpeed = (InteractionActor.DecreaseValueSpeed / InteractionActor.MaxValue) * 5.f;;
					if(InteractionActor.bClockwiseIsCorrectInput)
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::Left;
					else
						InteractionActor.PlayerStatus = EValveTurnInteractionAnimationType::Right;
				}
			}
		}
	}

	bool IsControllingSide() const
	{
		if(InteractionActor.bUpdateValveFromWorldControl)
		{
			return GetWorld().HasControl();
		}
		else
		{
			return HasControl();
		}
	}
 
	void UpdateControlInputData(float DeltaTime)
	{
		const FVector2D InputRawStick = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector InputDir(InputRawStick.X, InputRawStick.Y, 0.f);
		const float InputSize = InputDir.Size();

		// We give us some time to come back to a valid input
		if(InputSize <= 0.9f && bHadStickInputLastFrame)
		{
			const float SpeedAlpha = 1.f - (InputSize / 0.9f);
			const float LerpSpeed = FMath::Lerp(1.f, 10.f, SpeedAlpha);
			InputDir = FMath::VInterpTo(LastStickRotation.Vector(), InputDir, DeltaTime, LerpSpeed);
		}

		if(InputSize <= 0.8f)
		{
			CurrentInputType = EValveTurnInteractionAnimationDirection::Unset;
			bHadStickInputLastFrame = false;
			return;
		}
		
		auto InputComp = UHazeInputComponent::Get(PlayerOwner);
		const EHazePlayerControllerType ControllerType = InputComp.GetControllerType();
		
		InputDir.Normalize();
		if(InteractionActor.InputType == EValveTurnInputType::Rotating)
		{
			if (ControllerType == EHazePlayerControllerType::Keyboard)
			{
				CurrentInputType = GetInputValuesUsingKeyboard(InputDir);
			}
			else
			{
				CurrentInputType = GetInputValuesUsingStick(InputDir, DeltaTime);
			}
		}
		else
		{
			CurrentInputType = GetInputValuesUsingDirection(InputDir);
		}

		LastStickRotation = InputDir.ToOrientationQuat();
		bHadStickInputLastFrame = true;
	}

	EValveTurnInteractionAnimationDirection GetInputValuesUsingKeyboard(FVector InputDir) const
	{
		const float Margin = KINDA_SMALL_NUMBER;
		{
			// We are turning clockwise
			if(InputDir.X > Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Valid;
				else
					return EValveTurnInteractionAnimationDirection::Invalid;
			}
			// We are turning counter-clockwise
			else if(InputDir.X < -Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Invalid;
				else
					return EValveTurnInteractionAnimationDirection::Valid;	
			}
		}

		return EValveTurnInteractionAnimationDirection::Unset;
	}

	EValveTurnInteractionAnimationDirection GetInputValuesUsingStick(FVector InputDir, float DeltaTime) const
	{
		// Need 1 value to compare against
		if(!bHadStickInputLastFrame)
			return EValveTurnInteractionAnimationDirection::Unset;

		const float Margin = DeltaTime;
		const float InvalidInputAlpha = 1.f - FMath::Min((1.f / DeltaTime) / 60.f, 1.f);
		const float MarginMax = FMath::Lerp(0.25f, -0.9f, FMath::Pow(InvalidInputAlpha, 2.f));

		const float Dot = InputDir.DotProduct(LastStickRotation.RightVector);
		const float ValidAngle = InputDir.DotProduct(LastStickRotation.ForwardVector);

		if(FMath::Abs(Dot) <= KINDA_SMALL_NUMBER * 2)
			return CurrentInputType;

		if(ValidAngle < MarginMax)
			return CurrentInputType;

		// We are turning clockwise
		if(Dot > Margin)
		{
			if(InteractionActor.bClockwiseIsCorrectInput)
				return EValveTurnInteractionAnimationDirection::Invalid;
			else
				return EValveTurnInteractionAnimationDirection::Valid;	
		}
		// We are turning counter-clockwise
		else if(Dot < -Margin)
		{
			if(InteractionActor.bClockwiseIsCorrectInput)
				return EValveTurnInteractionAnimationDirection::Valid;
			else
				return EValveTurnInteractionAnimationDirection::Invalid;
		}	

		return EValveTurnInteractionAnimationDirection::Unset;
	}

	EValveTurnInteractionAnimationDirection GetInputValuesUsingDirection(FVector InputDir) const
	{
		// Need 1 value to compare against
		if(!bHadStickInputLastFrame)
			return EValveTurnInteractionAnimationDirection::Unset;

		const float Margin = KINDA_SMALL_NUMBER;
		if(InteractionActor.InputType == EValveTurnInputType::LeftRight)
		{
			// We are turning clockwise
			if(InputDir.X > Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Valid;
				else
					return EValveTurnInteractionAnimationDirection::Invalid;
			}
			// We are turning counter-clockwise
			else if(InputDir.X < -Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Invalid;
				else
					return EValveTurnInteractionAnimationDirection::Valid;	
			}
		}
		else if(InteractionActor.InputType == EValveTurnInputType::UpDown)
		{
			// We are turning clockwise
			if(InputDir.Y > Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Valid;
				else
					return EValveTurnInteractionAnimationDirection::Invalid;
			}
			// We are turning counter-clockwise
			else if(InputDir.Y < -Margin)
			{
				if(InteractionActor.bClockwiseIsCorrectInput)
					return EValveTurnInteractionAnimationDirection::Invalid;
				else
					return EValveTurnInteractionAnimationDirection::Valid;	
			}
		}

		return EValveTurnInteractionAnimationDirection::Unset;
	}

	void UpdateInteractionTurnValueToReplicate(float DeltaTime)
	{
	 	if(CurrentInputType != EValveTurnInteractionAnimationDirection::Unset)
	 	{
			if(!InteractionActor.bLoopRotation)
			{
				if(CurrentInputType == EValveTurnInteractionAnimationDirection::Valid)
				{
					InteractionActor.SyncComponent.Value = FMath::FInterpConstantTo(LastFrameRotationValue, InteractionActor.MaxValue, DeltaTime, InteractionActor.IncreaseValueSpeed);
				}
				else if(CurrentInputType == EValveTurnInteractionAnimationDirection::Invalid)
				{
					InteractionActor.SyncComponent.Value = FMath::FInterpConstantTo(LastFrameRotationValue, 0, DeltaTime, InteractionActor.DecreaseValueSpeed);
				}
			}
			else
			{
				if(CurrentInputType == EValveTurnInteractionAnimationDirection::Valid)
				{
					InteractionActor.SyncComponent.Value = LastFrameRotationValue + (InteractionActor.IncreaseValueSpeed * DeltaTime);
				}
				else if(CurrentInputType == EValveTurnInteractionAnimationDirection::Invalid)
				{
					InteractionActor.SyncComponent.Value = LastFrameRotationValue - (InteractionActor.DecreaseValueSpeed * DeltaTime);
				}
			}
	 	}
	}

	UFUNCTION(NetFunction)
	void NetReplicateControlInputData(EValveTurnInteractionAnimationDirection RepControlSideInput)
	{
		if(HasControl())
			return;

		CurrentInputType = RepControlSideInput;
	}

	// The interaction might be controlled from the world side, so this needs to be networked
	UFUNCTION(NetFunction)
	void NetControlsideHasFinished()
	{
		if(HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			if(InteractionActor.bForceEndOnFinsihed)
				CrumbParams.AddActionState(n"ForceEnd");
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_InteractionFinished"), CrumbParams);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_InteractionFinished(FHazeDelegateCrumbData CrumbData)
	{
		// Force the synvalue to the end
		if(InteractionActor == nullptr)
			return;

		InteractionActor.SyncComponent.SetValue(InteractionActor.MaxValue);
		InteractionActor.OnTurnFinished.Broadcast(InteractionActor);
		if(CrumbData.GetActionState(n"ForceEnd"))
		{
			InteractionActor.EnterInteraction.DisableForPlayer(PlayerOwner, n"Finished");
			InteractionActor.EnterInteraction.DisableForPlayer(PlayerOwner.GetOtherPlayer(), n"Finished");
		}
	}	
}