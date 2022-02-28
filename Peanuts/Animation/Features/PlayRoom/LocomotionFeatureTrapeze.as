class ULocomotionFeatureTrapeze : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureTrapeze()
    {
        Tag = n"Trapeze";
    }



	UPROPERTY(Category = "Trapeze")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Trapeze")
    FHazePlaySequenceData SwingEnter;

	UPROPERTY(Category = "Trapeze")
    FHazePlaySequenceData Reach;

	UPROPERTY(Category = "Trapeze")
    FHazePlaySequenceData Catch;
	
	UPROPERTY(Category = "Trapeze")
    FHazePlaySequenceData Exit;

	UPROPERTY(Category = "SwingBlendSpace")
    FHazePlayBlendSpaceData SwingBlendSpace;


	UPROPERTY(Category = "TrapezeMarble")
    FHazePlaySequenceData EnterMarble;

	UPROPERTY(Category = "TrapezeMarble")
    FHazePlaySequenceData SwingEnterMarble;

	UPROPERTY(Category = "TrapezeMarble")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "TrapezeMarble")
    FHazePlaySequenceData ExitMarble;

	UPROPERTY(Category = "SwingBlendSpaceMarble")
    FHazePlayBlendSpaceData SwingBlendSpaceMarble;

	
	
};