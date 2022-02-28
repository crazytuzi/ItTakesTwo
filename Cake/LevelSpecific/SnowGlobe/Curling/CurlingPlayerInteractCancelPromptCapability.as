import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;
class UCurlingPlayerInteractCancelPromptCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerInteractCancelPromptCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	
	UCurlingPlayerInteractComponent PlayerInteractComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerInteractComp = UCurlingPlayerInteractComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerInteractComp.InteractionState == EInteractionState::Interacting)
        	return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerInteractComp.InteractionState != EInteractionState::Interacting)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerInteractComp.ActivateCancelPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerInteractComp.DeactivateCancelPrompt(Player);
	}
}