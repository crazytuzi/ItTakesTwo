
class USkipCutsceneCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"SkipCutscene");
	default CapabilityDebugCategory = n"Sequencer";

	default TickGroup = ECapabilityTickGroups::Input;

	default TickGroupOrder = 100;

	AHazePlayerCharacter PlayerOwner = nullptr;

	AHazeLevelSequenceActor LastUsedLevelSequenceActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AHazeLevelSequenceActor SequenceActor = PlayerOwner.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SequenceActor.SkippableSetting == EHazeSkippableSetting::None)
			return EHazeNetworkActivation::DontActivate;
			
		if (!IsActioning(ActionNames::SkipCutscene))
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
    	AHazeLevelSequenceActor SequenceActor = PlayerOwner.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (SequenceActor.SkippableSetting == EHazeSkippableSetting::None)
			return EHazeNetworkDeactivation::DeactivateFromControl;
			
		if (!IsActioning(ActionNames::SkipCutscene))
			return EHazeNetworkDeactivation::DeactivateFromControl;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazeLevelSequenceActor SequenceActor = PlayerOwner.GetActiveLevelSequenceActor();
		if (SequenceActor != nullptr)
		{
			SequenceActor.SetPlayerWantsToSkipSequence(PlayerOwner.Player, true);
			LastUsedLevelSequenceActor = SequenceActor;
		}
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (LastUsedLevelSequenceActor != nullptr)
		{
			LastUsedLevelSequenceActor.SetPlayerWantsToSkipSequence(PlayerOwner.Player, false);
			LastUsedLevelSequenceActor = nullptr;
		}
	}
}