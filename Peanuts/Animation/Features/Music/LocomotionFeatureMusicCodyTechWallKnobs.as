class ULocomotionFeatureMusicCodyTechWallKnobs : UHazeLocomotionFeatureBase
{

    default Tag = n"CodyTechWallKnobs";

	UPROPERTY(Category = "TechWallKnob")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TechWallKnob")
    FHazePlaySequenceData SpinLeftDisk;

	UPROPERTY(Category = "TechWallKnob")
    FHazePlaySequenceData SpinRightDisk;

}