class ULocomotionFeatureLedgeNode : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureLedgeNode()
    {
        Tag = FeatureName::LedgeNode;
    }

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeNodeEnter;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeNodeHangingMH;
	
};