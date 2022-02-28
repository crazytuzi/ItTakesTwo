import Vino.MinigameScore.PlayerMinigameTutorialComponent;
import Vino.MinigameScore.MinigameStatics;

class UPlayerMinigameTutorialCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerMinigameTutorialCancelCapability");
	default CapabilityTags.Add(n"MinigameTutorial");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerMinigameTutorialComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerMinigameTutorialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::Cancel))
	        return EHazeNetworkActivation::DontActivate;

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
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		PlayerComp.OnTutorialCancelFromPlayer.Broadcast(Player);
	}
}