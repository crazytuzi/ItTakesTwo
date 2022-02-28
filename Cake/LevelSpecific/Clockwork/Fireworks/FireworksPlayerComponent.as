import Cake.LevelSpecific.Clockwork.Fireworks.FireworkRocket;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworksManager;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

delegate void FFireworksPlayerCancel(AHazePlayerCharacter Player);

class UFireworksPlayerComponent : UActorComponent
{
	AFireworksManager FireworkManager;
	
	AHazeCameraActor HazeCameraActor;

	FRotator TargetRot;

	FFireworksPlayerCancel PlayerCancel;

	UPROPERTY(Category = "Animation Features")
	UHazeLocomotionFeatureBase MayLocomotion;

	UPROPERTY(Category = "Animation Features")
	UHazeLocomotionFeatureBase CodyLocomotion;
	
	UPROPERTY()
	bool bIsExiting;
	UPROPERTY()
	bool bPressingLeft;
	UPROPERTY()
	bool bPressingRight;

	float LeftTimer;
	float RightTimer;

	float PressMaxTimer = 0.6f;

	//*** PROMPTS ***//
	UPROPERTY(Category = "Prompts")
	FTutorialPrompt RightTriggerExplode;
    default RightTriggerExplode.Action = ActionNames::SecondaryLevelAbility;
    default RightTriggerExplode.MaximumDuration = -1.f;
    default RightTriggerExplode.DisplayType = ETutorialPromptDisplay::ActionHold;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt LeftTriggerLaunch;
    default LeftTriggerLaunch.Action = ActionNames::PrimaryLevelAbility;
    default LeftTriggerLaunch.MaximumDuration = -1.f;
	
	bool bShowingLeft;
	bool bShowingRight;

	void ShowRightTriggerPrompt(AHazePlayerCharacter Player)
	{
		if (!bShowingRight)
		{
			bShowingRight = true;
			ShowTutorialPrompt(Player, RightTriggerExplode, this);
		}
	}

	void ShowLeftTriggerPrompt(AHazePlayerCharacter Player)
	{
		if (!bShowingLeft)
		{
			ShowTutorialPrompt(Player, LeftTriggerLaunch, this);
			bShowingLeft = true;
		}
	}

	void ShowInteractionCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	void HideTutorialPrompts(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);
		bShowingLeft = false;
		bShowingRight = false;
	}
} 