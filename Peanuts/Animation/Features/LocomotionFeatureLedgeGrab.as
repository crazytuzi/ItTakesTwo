class ULocomotionFeatureLedgeGrab : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureLedgeGrab()
    {
        Tag = FeatureName::LedgeGrab;
    }

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeGrab;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeHangMH;

	UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlayBlendSpaceData MHBlendSpace;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FVector HangOffset = FVector::ZeroVector;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeJumpUp;

	UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeJumpBackLeft;

	UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeJumpBackRight;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeDrop;

    UPROPERTY(Category = "Locomotion LedgeGrab")
    FHazePlaySequenceData LedgeClimbUp;
};