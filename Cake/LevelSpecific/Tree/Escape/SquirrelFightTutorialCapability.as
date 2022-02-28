import Vino.Tutorial.TutorialStatics;

class USquirrelFightTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tutorial");
	default CapabilityDebugCategory = n"Tutorial";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;


	AHazePlayerCharacter Player;
	
	FTutorialPrompt TutSettingsKick;
	FTutorialPrompt TutSettingsPunch;

	bool bHasPunched = false;
	bool bHasKicked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TutSettingsKick.Action = ActionNames::MeleeKick;
		TutSettingsKick.DisplayType = ETutorialPromptDisplay::Action;
		TutSettingsKick.Text = NSLOCTEXT("Melee", "MeleeKickTutorial", "Kick");

		TutSettingsPunch.Action = ActionNames::MeleePunch;
		TutSettingsPunch.DisplayType = ETutorialPromptDisplay::Action;
		TutSettingsPunch.Text = NSLOCTEXT("Melee", "MeleePunchTutorial", "Punch");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(bHasPunched && bHasKicked)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bHasPunched && bHasKicked)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowTutorialPromptWorldSpace(Player, TutSettingsKick, this);
		ShowTutorialPromptWorldSpace(Player, TutSettingsPunch, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bHasKicked && IsActioning(ActionNames::MeleeKick))
		{
			RemoveTutorialPromptByInstigator(Player, this);
			bHasKicked = true;
		}

		if (!bHasPunched && IsActioning(ActionNames::MeleePunch))
		{
			RemoveTutorialPromptByInstigator(Player, Player);
			bHasPunched = true;
		}
	}
}