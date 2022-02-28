import Vino.Interactions.Widgets.InteractionWidgetsComponent;

class UInteractionCapability : UHazeCapability
{
    default CapabilityTags.Add(CapabilityTags::Interaction);
    default CapabilityTags.Add(CapabilityTags::GameplayAction);

    UHazeTriggerUserComponent TriggerUser;
    UInteractionWidgetsComponent Widgets;
	UHazeJumpToComponent JumpToComp;

	TArray<EHazeActivationType> ActivationTypes;
	TArray<FName> ActivationButtons;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TriggerUser = UHazeTriggerUserComponent::GetOrCreate(Owner);
		Widgets = UInteractionWidgetsComponent::GetOrCreate(Owner);
		JumpToComp = UHazeJumpToComponent::GetOrCreate(Owner);

		ActivationTypes.Add(EHazeActivationType::Action);
		ActivationButtons.Add(ActionNames::InteractionTrigger);

		ActivationTypes.Add(EHazeActivationType::SecondaryLevelAbility);
		ActivationButtons.Add(ActionNames::SecondaryLevelAbility);

		ActivationTypes.Add(EHazeActivationType::PrimaryLevelAbility);
		ActivationButtons.Add(ActionNames::PrimaryLevelAbility);
	}

	private TArray<UHazeTriggerComponent> Triggers;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bHaveAvailableTriggers = false;
		for (auto ActivationType : ActivationTypes)
		{
			Triggers.Reset();
			if (TriggerUser.GetAvailableTriggers(EHazeActivationType::Action, Triggers))
			{
				bHaveAvailableTriggers = true;
				break;
			}
		}

		if (bHaveAvailableTriggers)
		{
			Owner.SetCapabilityActionState(CapabilityTags::Interaction, EHazeActionState::Active);
		}
		else
		{
			Owner.SetCapabilityActionState(CapabilityTags::Interaction, EHazeActionState::Inactive);
		}

		Widgets.bCanInteract = !IsBlocked();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Don't allow interacting while a jumpto is active
		if (JumpToComp.ActiveJumpTos.Num() != 0)
			return EHazeNetworkActivation::DontActivate;

		// Check if any button for interacting was pressed
		for (FName Button : ActivationButtons)
		{
			if (WasActionStarted(Button))
				return EHazeNetworkActivation::ActivateLocal;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Immediately deactivate whenever this becomes active		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		for (int i = 0, Count = ActivationTypes.Num(); i < Count; ++i)
		{
			if (WasActionStarted(ActivationButtons[i]))
			{
				auto ActivatedTrigger = TriggerUser.ActivateAnyAvailableTrigger(ActivationTypes[i]);
				if (ActivatedTrigger != nullptr)
					break;
			}
		}
    }
}