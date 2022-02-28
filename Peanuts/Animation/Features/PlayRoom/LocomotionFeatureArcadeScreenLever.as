class ULocomotionFeatureArcadeScreenLever : UHazeLocomotionFeatureBase 
{

    default Tag = n"ArcadeScreenLever";

    // Blendspace to control the lever
    UPROPERTY(Category = "ControlLever")
    FHazePlayBlendSpaceData ControlLever;

	UPROPERTY(Category = "ControlLever")
    FHazePlaySequenceData UseTrigger;

    // Reference Pose/Anim for the offset between hands, feet etc.
    UPROPERTY(Category = "ControlLever")
    FHazePlaySequenceData IKReferencePose;


}