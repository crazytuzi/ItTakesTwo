class ULocomotionFeatureMusicMicrophoneChaseDoor : UHazeLocomotionFeatureBase
{

    default Tag = n"MicrophoneChaseDoor";

	UPROPERTY(Category = "MicrophoneChaseDoor")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "MicrophoneChaseDoor")
    FHazePlaySequenceData Struggle;

	UPROPERTY(Category = "MicrophoneChaseDoor")
    FHazePlaySequenceData Struggle_L;

	UPROPERTY(Category = "MicrophoneChaseDoor")
    FHazePlaySequenceData TakeStep;

	UPROPERTY(Category = "MicrophoneChaseDoor")
    FHazePlaySequenceData TakeStep_L;

}