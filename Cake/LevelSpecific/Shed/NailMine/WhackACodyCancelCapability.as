import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;

class UWhackACodyCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	AHazePlayerCharacter Player;

	UPROPERTY()
	UWhackACodyComponent WhackaComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		auto Board = WhackaComp.WhackABoardRef;

		// No cancel during the countdown...
		if (Board.MinigameState == EWhackACodyGameStates::Countdown)
			return EHazeNetworkActivation::DontActivate;

		if (Board.MinigameState == EWhackACodyGameStates::ShowingTutorial)
			return EHazeNetworkActivation::DontActivate;

		if (Board.MinigameState == EWhackACodyGameStates::Idle)
		{
			// In idle state, we need to make sure we can cancel the double-interact
			if (!Board.DoubleInteract.CanPlayerCancel(Player))
				return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto Board = WhackaComp.WhackABoardRef;

		if (Board.MinigameState == EWhackACodyGameStates::Idle)
			Board.DoubleInteract.CancelInteracting(Player);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Board.PlayerCancelled(Player);
	}
}