import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSunbathing;
import Vino.Interactions.InteractionComponent;
import Vino.Tutorial.TutorialStatics;

event void FPlayerCancelChair(AHazePlayerCharacter Player);

class USunChairPlayerComponent : UActorComponent
{
	FPlayerCancelChair OnPlayerCancelChairEvent;

	UPROPERTY(Category = "Animation Features")
	ULocomotionFeatureSnowGlobeSunbathing MayLocomotion;

	UPROPERTY(Category = "Animation Features")
	ULocomotionFeatureSnowGlobeSunbathing CodyLocomotion;

	UPROPERTY(Category = "Animation")
	UAnimSequence AnimSeq;

	UInteractionComponent InteractionComp;

	bool bCanCancel;

	UFUNCTION()
	void ShowPlayerCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void HidePlayerCancel(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}
}