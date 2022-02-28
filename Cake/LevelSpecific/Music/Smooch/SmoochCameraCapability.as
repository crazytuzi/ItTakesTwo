import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;
	FHazeAcceleratedFloat AcceleratedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsCody())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SmoochComp.CameraSequence.PlayLevelSequenceSimple(FOnHazeSequenceFinished(), Game::May);

		FMovieSceneSequencePlaybackParams Params;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		Params.Time = 0.f;
		SmoochComp.CameraSequence.SequencePlayer.SetPlaybackPosition(Params);

		AcceleratedTime.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SmoochComp.CameraSequence.SequencePlayer.StopAtCurrentTime();
		SmoochComp.CameraSequence.Stop(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SequenceDuration = SmoochComp.CameraSequence.GetDurationAsSeconds();
		float TargetTime = SequenceDuration * GetSmoochMinimumProgress();
		AcceleratedTime.AccelerateTo(TargetTime, 3.f, DeltaTime);

		FMovieSceneSequencePlaybackParams Params;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		Params.Time = AcceleratedTime.Value;
		SmoochComp.CameraSequence.SequencePlayer.SetPlaybackPosition(Params);

		UHazeCameraComponent Cam = Player.GetCurrentlyUsedCamera();

		// Make the movement much more subtle the longer into the kiss we are
		float MoveScale = FMath::Lerp(1.f, 0.2f, Math::Saturate(GetSmoochMinimumProgress() * 1.5f));
		float RotateScale = FMath::Lerp(1.f, 0.f, Math::Saturate(GetSmoochMinimumProgress() * 1.6f)); 

		float Time = Time::GameTimeSeconds;
		Cam.RelativeLocation = FVector(0.f, FMath::Cos(Time * 0.452136) * 2.9f, FMath::Sin(Time * 0.85213521) * 5.8f) * MoveScale;
		Cam.RelativeRotation = FRotator(FMath::Sin(Time * 0.342512) * 0.5f, FMath::Cos(Time * 0.153296) * 0.3f, 0.f) * RotateScale;
	}
}
