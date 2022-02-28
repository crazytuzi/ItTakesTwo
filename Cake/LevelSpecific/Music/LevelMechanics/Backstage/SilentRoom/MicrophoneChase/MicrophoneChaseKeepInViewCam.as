import Vino.Camera.Actors.KeepInViewCameraActor;
import Vino.Audio.Music.MusicManagerActor;
class AMicrophoneChaseKeepInViewCam : AKeepInViewCameraActor
{
	float CamFStopTimer = 0.f;
	float CamFStopTimerDuration = 1.5f;
	bool bShouldTickDOF = false;
	float StartingFStopMax = 22.f;
	float TargetFStopMax = 0.05f;
	float StartingFStopMin = 1.2f;
	float TargetFStopMin = 0.05f;

	// Deactivating settings in Level BP

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Game::GetCody().CurrentlyUsedCamera == nullptr)
			return;

		if (Game::GetCody().CurrentlyUsedCamera.Owner != this)
			return;
		

		Game::GetCody().ApplyFieldOfView(30.f, CameraBlend::Normal(1.f), this, EHazeCameraPriority::Script);
		
		if (bShouldTickDOF)
		{
			Game::GetCody().CurrentlyUsedCamera.LensSettings.MaxFStop = FMath::Lerp(StartingFStopMax, TargetFStopMax, FMath::Min((CamFStopTimer/CamFStopTimerDuration), 1.f));
			Game::GetCody().CurrentlyUsedCamera.LensSettings.MinFStop = FMath::Lerp(StartingFStopMin, TargetFStopMin, FMath::Min((CamFStopTimer/CamFStopTimerDuration), 1.f));

			if (CamFStopTimer >= CamFStopTimerDuration)
				bShouldTickDOF = false;

			CamFStopTimer += DeltaTime;
		}

		FCameraFocusSettings FS;
		FS.FocusMethod = ECameraFocusMethod::Manual;
		FS.ManualFocusDistance = 5000.f;
		Game::GetCody().CurrentlyUsedCamera.FocusSettings = FS;
		Game::GetCody().CurrentlyUsedCamera.CurrentAperture = 0.1f;
		
		FHazeFocusTarget FocusTarget;
		FocusTarget.ViewOffset.Y = -1200.f;
		FocusTarget.ViewOffset.Z = -200.f;
		TArray<AHazePlayerCharacter> PlayerArray;
		for (auto Target : KeepInViewComponent.AllFocusTargets)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target.FocusTarget.Actor);
			if (Player == nullptr)
				continue;

			PlayerArray.Add(Player);
		}

		for (auto Player : PlayerArray)
		{
			FocusTarget.Actor = Player;
			KeepInViewComponent.AddTarget(FocusTarget);
		}
	}

	UFUNCTION()
	void StartTickingDOF()
	{
		Camera.LensSettings.MaxFStop = StartingFStopMax;
		Camera.LensSettings.MinFStop = StartingFStopMin;
		bShouldTickDOF = true;
	}
}