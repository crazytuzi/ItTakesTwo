import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingHazeWidget;

event void FEnableInteraction(UCurlingPlayerComp PlayerComp);
// event void FLeaveInteraction();

enum EPlayerCurlState
{
	Default,
	// WaitingAtInteraction,
	Engaging,
	MoveStone,
	Targeting,
	Shooting,
	Observing
};

class UCurlingPlayerComp : UActorComponent
{
	UObject TargetStone;

	UPROPERTY()
	EPlayerCurlState PlayerCurlState;

	FRotator BeforeShootCamRotation;

	FVector PlayerShootForwardVector;

	UPROPERTY()
	float TargetingBlendSpaceValue;

	bool bCompleteCamera;
	bool bIsMoving;
	bool bCanTargetAndFire;
	bool bCanCancel = true;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset TargetCamSettings;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect ForceShootImpact;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> CameraShakeShootImpact;

	UPROPERTY(Category = "Animation Features")
	UHazeLocomotionFeatureBase MayLocomotion;

	UPROPERTY(Category = "Animation Features")
	UHazeLocomotionFeatureBase CodyLocomotion;

	UPROPERTY(Category = "Prompts")
    FTutorialPrompt CurlShootPrompt;
    default CurlShootPrompt.MaximumDuration = -1.f;

	UPROPERTY()
	UCurveFloat PowerCurve;

	TArray<AHazeActor> DisabledMagnetObjects;

	UPROPERTY(Category = "Prompts")
	TSubclassOf<UCurlingHazeWidget> CurlingWidget;

	float CurlingPower;
	float MaxCurlingPower = 8000.f;
	float EngagedDistance = 230.f;

	FHazeAcceleratedFloat AcceleratedTurnRate;
	FHazeAcceleratedRotator AcceleratedRemoteRotation;

	UPROPERTY()
	bool bIsUsingLeftStick;
	
	void ShowCurlCancelPrompt(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	void ShowCurlShootPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, CurlShootPrompt, this);
	}

	void HideCurlShootPrompt(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	void HideCurlTutorialPrompt(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);
	}
}