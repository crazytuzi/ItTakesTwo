class ULocomotionFeaturePlayRoomPinBall : UHazeLocomotionFeatureBase
{

    default Tag = n"PinBall";

    UPROPERTY(Category = "PinBall")
    FHazePlaySequenceData PinBallEnter;

	UPROPERTY(Category = "PinBall")
    FHazePlaySequenceData PinBallExit;

	UPROPERTY(Category = "PinBall")
    FHazePlayBlendSpaceData PinBallBS;

	UPROPERTY(Category = "PinBall")
    FHazePlaySequenceData PinBallHitLeft;

	UPROPERTY(Category = "PinBall")
    FHazePlaySequenceData PinBallHitRight;

	UPROPERTY(Category = "PinBall")
    FHazePlaySequenceData IKReference;


    
    // Example of BlendSpace data
    // UPROPERTY(Category = "PinBall")
	// FHazePlayBlendSpaceData Blendspace;

}