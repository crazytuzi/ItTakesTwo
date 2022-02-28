class ULocomotionFeatureMusicWindChimes : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureMusicWindChimes()
    {
        Tag = n"WindChimes";
    }

	UPROPERTY(Category = "MH")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "Swinging")
    FHazePlayBlendSpaceData Swinging;

};