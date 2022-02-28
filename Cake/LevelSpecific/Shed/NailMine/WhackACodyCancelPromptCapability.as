import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;

class UWhackACodyCancelPromptCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	AHazePlayerCharacter Player;
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

		auto Board = WhackaComp.WhackABoardRef;
		if (Board.MinigameState == EWhackACodyGameStates::Countdown)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		auto Board = WhackaComp.WhackABoardRef;
		if (Board.MinigameState == EWhackACodyGameStates::Countdown)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveCancelPromptByInstigator(this);
	}
}