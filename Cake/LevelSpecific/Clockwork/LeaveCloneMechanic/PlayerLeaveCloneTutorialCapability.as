import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Vino.Tutorial.TutorialStatics;

class UPlayerLeaveCloneTutorialCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UTimeControlSequenceComponent SeqComp;

	bool bCloneTutorial = false;
	bool bTutorialFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SeqComp = UTimeControlSequenceComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ShowLeaveCloneTutorial"))
			return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bTutorialFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"ShowLeaveCloneTutorial");
		bCloneTutorial = true;
		bTutorialFinished = false;

		FTutorialPrompt Prompt;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Prompt.Action = ActionNames::SecondaryLevelAbility;
		Prompt.Text = NSLOCTEXT("Clockwork", "LeaveCloneTutorial", "Leave Clone");
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bCloneTutorial)
		{
			if (SeqComp != nullptr && SeqComp.IsCloneActive())
			{
				FTutorialPrompt Prompt;
				Prompt.DisplayType = ETutorialPromptDisplay::Action;
				Prompt.Action = ActionNames::PrimaryLevelAbility;
				Prompt.Text = NSLOCTEXT("Clockwork", "TeleportToCloneTutorial", "Teleport to Clone");

				RemoveTutorialPromptByInstigator(Player, this);
				ShowTutorialPrompt(Player, Prompt, this);

				bCloneTutorial = false;
			}
		}
		else
		{
			if (Player.IsAnyCapabilityActive(n"SequenceTeleport"))
			{
				bTutorialFinished = true;
			}
		}
	}
};

UFUNCTION(Category = "Clockwork")
void ShowLeaveCloneTutorial(AHazePlayerCharacter Player)
{
	Player.AddCapability(UPlayerLeaveCloneTutorialCapability::StaticClass());
	Player.SetCapabilityActionState(n"ShowLeaveCloneTutorial", EHazeActionState::Active);
}

UFUNCTION(Category = "Clockwork")
void HideLeaveCloneTutorial(AHazePlayerCharacter Player)
{
	Player.RemoveCapability(UPlayerLeaveCloneTutorialCapability::StaticClass());
	Player.SetCapabilityActionState(n"ShowLeaveCloneTutorial", EHazeActionState::Inactive);
}