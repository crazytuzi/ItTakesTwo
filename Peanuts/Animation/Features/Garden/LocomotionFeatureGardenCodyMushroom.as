class ULocomotionFeatureGardenCodyMushroom : UHazeLocomotionFeatureBase
{

    default Tag = n"CodyMushroom";

    UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData GrowUp;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData Bounce;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData ChargeupEnter;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData ChargeupMH;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData ChargeupExit;

	UPROPERTY(Category = "CodyMushroom")
    FHazePlaySequenceData Exit;
    
    
    // Example of BlendSpace data
    // UPROPERTY(Category = "CodyMushroom")
	// FHazePlayBlendSpaceData Blendspace;

}