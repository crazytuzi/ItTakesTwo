import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPath;
import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkPedalBoat;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

delegate void FCancelBoatInteractionDelegate(UInteractionComponent InteractionComp); 

class USplineBoatPlayerComponent : UActorComponent
{
	float TargetSpeed;

	FVector LockedPosition;

	FRotator RotatedPosition;

	FVector NextBoatPosition;

	FCancelBoatInteractionDelegate CancelBoatAction;

	UInteractionComponent OurInteractionComp;

	ASplineBoatPath SplinePath;

	UHazeSplineFollowComponent SplineFollowComp;

	// UObject SplineBoat;

	FHazeSplineSystemPosition SplinePosition;

	UPROPERTY()
	ULocomotionFeatureClockWorkPedalBoat MayLocomotion;

	UPROPERTY()
	ULocomotionFeatureClockWorkPedalBoat CodyLocomotion;

	AHazeActor BoatRef;

	bool bIsActive;

	//for animation
	bool bIsInBoat;

	bool bHaveCompletedTutorial;

	bool bIsSlow;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt HoldRight;
	default HoldRight.Action = ActionNames::PrimaryLevelAbility;
	default HoldRight.MaximumDuration = -1;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt HoldLeft;
	default HoldLeft.Action = ActionNames::SecondaryLevelAbility;
	default HoldLeft.MaximumDuration = -1;

	UFUNCTION()
	void ShowRightPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, HoldRight, this);
	}

	UFUNCTION()
	void ShowLeftPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, HoldLeft, this);
	}

	UFUNCTION()
	void RemovePrompts(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}
}