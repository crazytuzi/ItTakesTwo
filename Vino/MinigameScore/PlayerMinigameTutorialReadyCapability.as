import Vino.MinigameScore.PlayerMinigameTutorialComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.MinigameScore.MinigameStatics;

class UPlayerMinigameTutorialReadyCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerMinigameTutorialReadyCapability");
	default CapabilityTags.Add(n"MinigameTutorial");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerMinigameTutorialComponent PlayerComp;

	float NetRate = 0.3f;
	float NetTime;

	float NetInputValue;

	FHazeAcceleratedFloat AccelInputValue;

	bool bHaveActivatedEvent = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerMinigameTutorialComponent::Get(Player);

		Player.BlockCapabilities(CameraTags::Control, this);
		Player.BlockCapabilities(n"Tutorial", this);
	
		bHaveActivatedEvent = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::InteractionTrigger))
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHaveActivatedEvent = true;
		PlayerComp.OnMinigamePlayerReady.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(CameraTags::Control, this);
		Player.UnblockCapabilities(n"Tutorial", this);
    }
}