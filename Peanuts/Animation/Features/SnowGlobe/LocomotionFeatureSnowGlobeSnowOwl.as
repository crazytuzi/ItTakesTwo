class ULocomotionFeatureSnowOwl : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureSnowOwl()
    {
        Tag = n"SnowOwl";
    }

    UPROPERTY(Category = "Fly")
    FHazePlayRndSequenceData Fly;

	UPROPERTY(Category = "Override")
	FHazePlayOverrideAnimationParams Override;

	};