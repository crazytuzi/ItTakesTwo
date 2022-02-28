import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Tutorial.TutorialStatics;

class USwimmingTimedTutorialCapability : UHazeCapability
{	
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	default CapabilityDebugCategory = n"Tutorial Swimming";

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;

	float TutorialTimer = 0.f;
	float ButtonPressTimer = 0.f;
	float ButtonPressTime = 0.3f;

	UPROPERTY()
	float TutorialShowUpTime = 10.f;

	UPROPERTY()
	TArray<FTutorialPrompt> TutorialPrompts;

	bool bHasDisplayedTutorial = false;
	bool bHasPressedButtons = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
/*
		if (bHasDisplayedTutorial)
      		return EHazeNetworkActivation::DontActivate;
*/
		if (bHasPressedButtons)
      		return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bIsInWater)
       		return EHazeNetworkActivation::DontActivate;

/*
		if (IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::MovementCrouch))
			return EHazeNetworkActivation::DontActivate;
*/

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bHasPressedButtons)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
/*
		if (!bHasDisplayedTutorial && (IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::MovementCrouch)))
       		return EHazeNetworkDeactivation::DeactivateFromControl;
*/
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TutorialTimer = TutorialShowUpTime;
		ButtonPressTimer = ButtonPressTime;
		bHasDisplayedTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::MovementCrouch))
		{
//			PrintToScreen("ButtonPressTimer: " + ButtonPressTimer, 0.f, FLinearColor::Green);

			if (ButtonPressTimer > 0.f)
				ButtonPressTimer -= DeltaTime;
			else
				bHasPressedButtons = true;
		}
		else
			ButtonPressTimer = ButtonPressTime;

		if (TutorialTimer > 0.f)
		{
			TutorialTimer -= DeltaTime;
//			PrintToScreen("TutorialTimer: " + TutorialTimer, 0.f, FLinearColor::Green);
		}
		else if (!bHasDisplayedTutorial)
		{
			for (auto TutorialPrompt : TutorialPrompts)
			{
				Player.ShowTutorialPrompt(TutorialPrompt, this);
			}

			bHasDisplayedTutorial = true;
		}

	}	

}
