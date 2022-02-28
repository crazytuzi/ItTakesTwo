import Vino.Buttons.GroundPoundButton;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PulseEqualizerManager;
import Vino.Camera.CameraStatics;
class ADrumMachineDoorButton : AGroundPoundButton
{
	bool bButtonEnabled = false;

	UPROPERTY()
	ASynthDoor ConnectedSynthDoor;

	UPROPERTY()
	APulseEqualizerManager EQManager;

	FVector LitColor = FVector(10.f, 0.f, 0.f);

	UPROPERTY()
	UMaterialInterface UnlitMat;

	UPROPERTY()
	UMaterialInterface LitMat;

	UPROPERTY()
	FHazeTimeLike BumpUpButtonTimeline;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonBumpUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonGroundPoundedAudioEvent;

	bool bHasAppliedPoi = false;

	FVector StartingPos;
	FVector TargetPos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ConnectedSynthDoor.SynthPuzzleSolved.AddUFunction(this, n"SynthPuzzleSolved");

		StartingPos = ActorLocation;
		TargetPos = ActorLocation + FVector(0.f, 0.f, 100.f);

		BumpUpButtonTimeline.BindUpdate(this, n"BumpUpButtonTimelineUpdate");
		BumpUpButtonTimeline.SetPlayRate(1/0.5f);
	}

	UFUNCTION(NotBlueprintCallable)
    void ButtonGroundPounded(AHazePlayerCharacter Player) override
    {
		if (!bButtonEnabled)
			return;

		Super::ButtonGroundPounded(Player);
		Player.PlayerHazeAkComp.HazePostEvent(ButtonGroundPoundedAudioEvent);

		ConnectedSynthDoor.OpenDoor();
		EQManager.SetPulseEqualizerActive(true);
		bButtonEnabled = false;
    }

	UFUNCTION()
	void SetDrumMachineButtonEnabled(bool bNewEnabled)
	{
		if (bButtonEnabled)
			return;

		bButtonEnabled = bNewEnabled;
		System::SetTimer(this, n"VisuallyActivateButton", 2.f, false);

		if (!bHasAppliedPoi && bButtonEnabled)
		{
			bHasAppliedPoi = true;
			
			for (auto Player : Game::GetPlayers())
			{
				FLookatFocusPointData Data;
				Data.Actor = this;
				Data.FOV = 40.f;
				Data.ShowLetterbox = false;
				Data.POIBlendTime = 2.f;
				Data.Duration = 2.f;
				LookAtFocusPoint(Player, Data);
			}
		}
	}

	UFUNCTION()
	void VisuallyActivateButton()
	{
		if (bButtonEnabled)
			ButtonMesh.SetMaterial(0, LitMat);
		else
			ButtonMesh.SetMaterial(0, UnlitMat);

		BumpUpButtonTimeline.Play();
		UHazeAkComponent::HazePostEventFireForget(ButtonBumpUpAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void BumpUpButtonTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::Lerp(StartingPos, TargetPos, CurrentValue));
	}

	UFUNCTION()
	void SynthPuzzleSolved(bool bSolved)
	{
		SetDrumMachineButtonEnabled(bSolved);	
	}
}