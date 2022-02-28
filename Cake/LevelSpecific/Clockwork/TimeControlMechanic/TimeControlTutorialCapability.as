import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.Tutorial.TutorialStatics;

class UTimeControlTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(TimeControlCapabilityTags::TimeControlCapability);

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!HasControl())
			return;

		FTutorialPromptChain TutorialChain;

		FTutorialPrompt TriggerPrompt;
		TriggerPrompt.Action = ActionNames::PrimaryLevelAbility;
		TriggerPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		TriggerPrompt.Text = NSLOCTEXT("Clockwork", "TimeControlTutorial", "Control Time");
		TutorialChain.Prompts.Add(TriggerPrompt);

		FTutorialPrompt StickPrompt;
		StickPrompt.Action = AttributeVectorNames::MovementRaw;
		StickPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		TutorialChain.Prompts.Add(StickPrompt);

		ShowTutorialPromptChain(Player, TutorialChain, this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		RemoveTutorialPromptByInstigator(Player, this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!HasControl())
			return;

		if (Player.IsAnyCapabilityActive(n"TimeControlling"))
		{
			SetTutorialPromptChainPosition(Player, this, 1);
		}
		else
		{
			SetTutorialPromptChainPosition(Player, this, 0);
		}
	}
}