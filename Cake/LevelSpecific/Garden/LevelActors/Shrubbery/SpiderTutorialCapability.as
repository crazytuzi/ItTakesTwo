import Vino.Tutorial.TutorialStatics;

class USpiderTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpiderTutorial");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	bool bAimTutorialActive = false;
	bool bShootTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"SpiderTutorial"))
     		return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"SpiderTutorial"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, Player);
		bShootTutorialActive = false;
		bAimTutorialActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			ShowAimTutorial();
		}

		if(IsActioning(ActionNames::PrimaryLevelAbility))
		{
			ShowShootTutorial();
		}

		if(WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			bAimTutorialActive = false;
		}

		if(WasActionStarted(ActionNames::MovementJump))
		{
			bShootTutorialActive = false;
		}
	}

	UFUNCTION()
	void ShowAimTutorial()
	{
		if(bAimTutorialActive)
			return;
		
		FTutorialPrompt AimPrompt;
		AimPrompt.Action = ActionNames::PrimaryLevelAbility;
		AimPrompt.Text = NSLOCTEXT("Spider", "SpiderAimWebTutorial", "Aim web");
		AimPrompt.MaximumDuration = 10.f;
		AimPrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		ShowTutorialPrompt(Player, AimPrompt, this);
		bAimTutorialActive = true;

		if(bShootTutorialActive)
		{
			RemoveTutorialPromptByInstigator(Player, Player);
			bShootTutorialActive = false;
		}
	}

	UFUNCTION()
	void ShowShootTutorial()
	{
		if(bShootTutorialActive)
			return;
		
		FTutorialPrompt WebPrompt;
		WebPrompt.Action = ActionNames::MovementJump;
		WebPrompt.Text = NSLOCTEXT("Spider", "SpiderShootWebTutorial", "Shoot web");
		WebPrompt.MaximumDuration = 10.f;
		WebPrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		ShowTutorialPrompt(Player, WebPrompt, Player);
		bShootTutorialActive = true;
	}

}