import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeHarpoon;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.AimWidgetHarpoon;

event void FOnPlayerCancelledMagnetHarpoon(AHazePlayerCharacter Player);

enum EMagnetHarpoonState
{
	Default,
	GotCatch,
	ReleaseCatch
}

class UHarpoonPlayerComponent : UActorComponent
{
	FOnPlayerCancelledMagnetHarpoon OnPlayerCancelledMagnetHarpoon;

	EMagnetHarpoonState MagnetHarpoonState;

	UPROPERTY(Category = "Camera Settings")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt FirePrompt;
 	default FirePrompt.Action = ActionNames::PrimaryLevelAbility;
    default FirePrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ReleasePrompt;
 	default ReleasePrompt.Action = ActionNames::PrimaryLevelAbility;
    default ReleasePrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Animations")
	ULocomotionFeatureSnowGlobeHarpoon HarpoonFeatureMay;
	
	UPROPERTY(Category = "Animations")
	ULocomotionFeatureSnowGlobeHarpoon HarpoonFeatureCody;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UAimWidgetHarpoon> AimWidgetClass; 

	UAimWidgetHarpoon AimWidget;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect Feedback;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> CamShake;

	float CoolDownTime;
	float DefaultCoolDownTime = 1.5f;
	bool bCanTimer;

	bool bCanHarpoon;

	UFUNCTION()
	void ShowHarpoonCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void HideHarpoonCancel(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void ShowFirePrompt(AHazePlayerCharacter Player)
	{
		Player.ShowTutorialPrompt(FirePrompt, this);
	}

	UFUNCTION()
	void ShowReleasePrompt(AHazePlayerCharacter Player)
	{
		Player.ShowTutorialPrompt(ReleasePrompt, this);
	}

	UFUNCTION()
	void HidePrompts(AHazePlayerCharacter Player)
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bCanHarpoon = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanTimer)
		{
			CoolDownTime -= DeltaTime;

			if (CoolDownTime <= 0.f)
			{
				bCanTimer = false;
				bCanHarpoon = true;
			}
		}
	}

	void FiredHarpoon()
	{
		CoolDownTime = DefaultCoolDownTime;
		bCanTimer = true;
		bCanHarpoon = false;
	}

	void PlayFeedback(AHazePlayerCharacter Player, float Amplitude)
	{
		Player.PlayForceFeedback(Feedback, false, true, n"MagnetHarpoon", Amplitude);
		Player.PlayCameraShake(CamShake, Amplitude);
	}
}