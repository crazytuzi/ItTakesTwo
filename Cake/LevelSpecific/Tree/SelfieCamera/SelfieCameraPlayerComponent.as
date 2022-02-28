import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraWidget;

class USelfieCameraPlayerComponent : UActorComponent
{
	AHazeCameraActor SelfieCamera;
	
	UObject SelfieCameraActor;
	
	USelfieCameraWidget WidgetRef;

	UPROPERTY(Category = "Camera Settings")
	UHazeCameraSpringArmSettingsDataAsset CamSettings; 

	UPROPERTY(Category = "Animation")
	TPerPlayer<UAnimSequence> PlayerCameraLookMH;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect SelfieCameraRumble;

	UPROPERTY(Category)
	FTutorialPrompt TakePicturePrompt;
	default TakePicturePrompt.Action = ActionNames::MovementJump;
	default TakePicturePrompt.MaximumDuration = -1.f;
	default TakePicturePrompt.Text = NSLOCTEXT("SelfieCamera", "Prompt", "Take Picture");

	bool bCanLook;

	bool bCanCancel;

	bool bShowTakePicVisible;

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

	UFUNCTION()
	void ShowPlayerTakePic(AHazePlayerCharacter Player)
	{
		if (!bShowTakePicVisible)
		{
			Player.ShowTutorialPrompt(TakePicturePrompt, this);
			bShowTakePicVisible = true;
		}
	}

	UFUNCTION()
	void HidePlayerTakePic(AHazePlayerCharacter Player)
	{
		if (bShowTakePicVisible)
		{
			Player.RemoveTutorialPromptByInstigator(this);
			bShowTakePicVisible = false;
		}
	}

	UFUNCTION()
	void PlayRumble(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(SelfieCameraRumble, false, true, n"SelfieCamera");
	}
}