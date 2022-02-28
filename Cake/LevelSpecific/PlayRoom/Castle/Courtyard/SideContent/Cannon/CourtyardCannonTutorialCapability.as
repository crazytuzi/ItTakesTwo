import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;

class UCourtyardCannonTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"Cannon");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;	
	UCannonToShootMarblePlayerComponent CannonComponent;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		CannonComponent = UCannonToShootMarblePlayerComponent::Get(Player);
		CrumbComp = UHazeCrumbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CannonComponent.CannonActor.InteractingPlayer != Player)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CannonComponent.CannonActor.InteractingPlayer != Player)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FTutorialPrompt Tutorial;
		Tutorial.Action = ActionNames::PrimaryLevelAbility;
		Tutorial.DisplayType = ETutorialPromptDisplay::Action;
		Tutorial.Text = NSLOCTEXT("CourtyardCannon", "Shoot", "Shoot");;
		
		ShowTutorialPrompt(Player, Tutorial, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}
}