import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

class UDinoCraneTutorialCapability : UHazeCapability
{
    default CapabilityTags.Add(n"DinoCrane");

	default CapabilityDebugCategory = n"Example";
	
    default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ADinoCrane DinoCrane;
	UDinoCraneRidingComponent RideComp;

	bool bIsShowingTutorial;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DinoCrane = UDinoCraneRidingComponent::GetOrCreate(Owner).DinoCrane;
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		ShowTutorial();
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopTutorial();
	}

		void ShowTutorial()
	{
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::SecondaryLevelAbility;
			Prompt.Mode = ETutorialPromptMode::Default;
			Prompt.DisplayType = ETutorialPromptDisplay::Action;
			Prompt.Text = RideComp.DinoCrane.MoveNeckDownText;

			ShowTutorialPrompt(Player, Prompt, this);
		}
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::PrimaryLevelAbility;
			Prompt.Mode = ETutorialPromptMode::Default;
			Prompt.DisplayType = ETutorialPromptDisplay::Action;
			Prompt.Text = RideComp.DinoCrane.MoveNeckupText;
			
			ShowTutorialPrompt(Player, Prompt, this);
		}

		bIsShowingTutorial = true;
	}

	void StopTutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);

		bIsShowingTutorial = false;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
		{
            return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (RideComp.DinoCrane == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
				
		if (bIsShowingTutorial && RideComp.DinoCrane.IsAnyCapabilityActive(n"GrabbedPlatform"))
		{
			StopTutorial();
		}

		if (!bIsShowingTutorial && !RideComp.DinoCrane.IsAnyCapabilityActive(n"GrabbedPlatform"))
		{
			ShowTutorial();
		}
	}
}