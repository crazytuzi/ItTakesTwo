import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;

class USnowballFightCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowballFightCapability");
	default CapabilityTags.Add(n"SnowballFight");

	default CapabilityDebugCategory = n"GamePlay";

	AHazePlayerCharacter Player;
	USnowballFightComponent SnowballFightComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SnowballFightComponent = USnowballFightComponent::Get(Player);
		// Print("SNOWBALLFIGHTCAPABILITY ADDED TO PLAYER");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SnowballFightComponent == nullptr)
	        return EHazeNetworkActivation::DontActivate;

		// if(!IsActioning(n"SnowballTutorial"))
	    //     return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SnowballFightComponent == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (SnowballFightComponent.bHaveCompletedTutorial)
			return;

		SnowballFightComponent.ShowLeftPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		SnowballFightComponent.RemovePrompts(Player);
	}

	// UFUNCTION(BlueprintOverride)
	// void OnBlockTagRemoved(FName Tag)
	// {
	// 	if (SnowballFightComponent.bHaveCompletedTutorial)
	// 		return;

	// 	SnowballFightComponent.ShowLeftPrompt(Player);
	// }

};