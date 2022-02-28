class ULocomotionFeatureTreeBird : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureTreeBird()
    {
        Tag = n"TreeBird";
    }



   
    UPROPERTY(Category = "TreeBird")
    FHazePlaySequenceData Sad;

	UPROPERTY(Category = "TreeBird")
    FHazePlaySequenceData HappySad;
	
	UPROPERTY(Category = "TreeBird")
    FHazePlaySequenceData Happy;

	UPROPERTY(Category = "TreeBird")
    FHazePlaySequenceData Idle;

	   




    UPROPERTY(Category = "TreeBirdBaby")
    FHazePlaySequenceData EggIdle;

	 UPROPERTY(Category = "TreeBirdBaby")
    FHazePlaySequenceData Hatch;

	 UPROPERTY(Category = "TreeBirdBaby")
    FHazePlaySequenceData HatchIdle;

  

    
}