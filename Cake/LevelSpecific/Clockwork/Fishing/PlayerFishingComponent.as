import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkFishingMinigame;

event void FExitFishing(AHazePlayerCharacter Player);
event void FCatchObject(int RIndex);
event void FSlackValue(float Value);
event void FWindValue(float Value);

enum EFishingState
{
	// Inactive,
	Default, //Default is controlled state + everything is set back to it's beginning stages
	WindingUp,
	Casting,
	Catching,
	Reeling,
	Hauling,
	HoldingCatch,
	ThrowingCatch
}

class UPlayerFishingComponent : UActorComponent
{
	EFishingState FishingState;

	FExitFishing EventExitFishing;
	// FCatchObject EventCatchObject;
	FSlackValue EventSlackValue;
	FWindValue EventWindValue;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect ReelRumble;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsDefault;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsEngagedMay;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsEngagedCody;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsGotCatchMay;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsGotCatchCody;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsThrowCatch;

	UPROPERTY(Category = "Animation")
	ULocomotionFeatureClockWorkFishingMinigame MayLocomotion;

	UPROPERTY(Category = "Animation")
	ULocomotionFeatureClockWorkFishingMinigame CodyLocomotion;
	
	//*** GENERAL SETUP ***//
	bool bCanCancelFishing;
	bool bCatchIsHere;
	bool bHaulingUpcatch;
	bool bCatchReady;
	bool bHaveActivatedCam;
	UObject RodBase;
	AHazeCameraActor CameraThrowCatch; 

	//*** WIND UP AND CAST ***//
	float StoredCastPower;
	//float NetStoredPower;
	float MaxCastPower = 1700.f;

	//*** REELING ***//
	float AlphaPlayerReel;
	float AlphaStartingValue = 0.3f;
	float AlphaMax; 

	//*** LEFT AND RIGHT ANGLE CHECKS ***//
	float CurrentDotRight;
	float CurrentDotForward;
	float DotLeftMax;
	float DotRightMax;

	//*** ROTATION INPUTS ***//
	float TargetRotationInput;
	float InputValue;
	float InterpSpeed;
	float DefaultInterpSpeed = 3.7f;
	float HaltInterpSpeed = 22.f;

	//*** MANAGER INFO ***//
	int MaxCatchIndexAmount;

	//*** LINE MATERIAL FOR SETTING MAIN VALUES ***//
	float DefaultSlackTarget;
	float CastSlackTarget;
	float ReelSlackTarget;

	//*** LINE MATERIAL FOR SETTING MAIN VALUES ***//
	FVector FishballLoc;
	FVector RodRightVector;

	//*** ANIMATIONS ***//
	float TurnBaseLeverInput;
	FHazeAcceleratedFloat ReelingCatchInput;

	//*** PROMPTS ***//
	UPROPERTY(Category = "Prompts")
	TSubclassOf<UHazeUserWidget> CatchProgressWidget;

	UPROPERTY(Category = "Prompts")
    FTutorialPrompt ShowThrowCatch;
    default ShowThrowCatch.Action = ActionNames::Cancel;
    default ShowThrowCatch.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ShowRightTriggerCast;
    default ShowRightTriggerCast.Action = ActionNames::PrimaryLevelAbility;
    default ShowRightTriggerCast.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ShowCatchFish;
    default ShowCatchFish.Action = ActionNames::ClockFishingCatch;
    default ShowCatchFish.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ShowReelPrompt;
    default ShowReelPrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ShowReelPromptNonController;
    default ShowReelPrompt.MaximumDuration = -1.f;

	UFUNCTION()
	void ShowRightTriggerCastPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, ShowRightTriggerCast, this); 
	}

	UFUNCTION()
	void ShowRightTriggerReelPrompt(AHazePlayerCharacter Player)
	{
		if (Player.IsUsingGamepad())
			ShowTutorialPrompt(Player, ShowReelPrompt, this); 
		// else
		// 	ShowTutorialPrompt(Player, ShowReelPromptNonController, this); 
	}

	UFUNCTION()
	void ShowCatchFishPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, ShowCatchFish, this); 
	}

	UFUNCTION()
	void HideTutorialPrompt(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this); 
	} 

	UFUNCTION()
	void ShowCancelInteractionPrompt(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this); 
	}

	UFUNCTION()
	void HideCancelInteractionPrompt(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void ShowThrowCatchPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, ShowThrowCatch, this); 
	}

	UFUNCTION()
	void HideThrowCatchPrompt(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this); 
	}
}