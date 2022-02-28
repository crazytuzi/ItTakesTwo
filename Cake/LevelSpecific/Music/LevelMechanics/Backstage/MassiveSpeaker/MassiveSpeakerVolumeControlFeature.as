class UMassiveSpeakerVolumeControlFeature : UHazeLocomotionFeatureBase
{
    UMassiveSpeakerVolumeControlFeature()
    {
        Tag = n"MassiveSpeakerController";
    }

    UPROPERTY(Category = "MassiveSpeakerController")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "MassiveSpeakerController")
    FHazePlayBlendSpaceData Pushing;

	UPROPERTY(Category = "MassiveSpeakerController")
    FHazePlaySequenceData PushedBack;

	UPROPERTY(Category = "MassiveSpeakerController")
    FHazePlaySequenceData Exit;
};