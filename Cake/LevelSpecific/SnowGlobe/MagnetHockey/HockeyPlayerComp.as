// import Vino.Tutorial.TutorialPrompt;
// import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyStartingPoint;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;

enum EHockeyPlayerState
{
	Default,
	MovementBlocked,
	Countdown,
	InPlay,
	ResetNextPlay
};

class UHockeyPlayerComp : UActorComponent
{
	EHockeyPlayerState HockeyPlayerState;

	UPROPERTY(Category = "Anims")
	UAnimSequence AnimSequence;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem MagnetSlamSystemMay;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem MagnetSlamSystemCody;

	TArray<AHockeyPuck> HockeyPuckArray;

	AHockeyPuck HockeyPuck;

	AHockeyPaddle HockeyPaddle;

	AHazeCameraActor GameCamera;

	AHockeyStartingPoint StartingPointRef;

	FVector SmoothLocation;

	// FRotator SmoothRotation;

	bool bIsActivatingAbility;

	bool bHasCompletedPush;

	bool bBeginCount;

	bool bCanCancel;

	float Timer;

	float MaxTimer = 0.5f;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(HockeyPuckArray);
		HockeyPuck = HockeyPuckArray[0];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bHasCompletedPush && !bBeginCount)
		{
			bBeginCount = true;
			Timer = MaxTimer;
		}

		if (bBeginCount)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
			{
				bBeginCount = false;
				bHasCompletedPush = false;
			}
		}

		// PrintToScreen("Timer: " + Timer);
	}
}