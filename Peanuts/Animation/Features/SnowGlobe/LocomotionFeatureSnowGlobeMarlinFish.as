class ULocomotionFeatureMarlinFish : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureMarlinFish()
    {
        Tag = n"MarlinFish";
    }



    UPROPERTY(Category = "Swimming")
    FHazePlaySequenceData SwimMh;

    UPROPERTY(Category = "Swimming")
    FHazePlaySequenceData SwimFastMh;


	};