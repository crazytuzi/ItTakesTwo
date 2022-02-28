

class ULocomotionFeatureTimeControl : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureTimeControl()
    {
        Tag = n"TimeControl";
    }

	// General movement

    // 
	UPROPERTY(Category = "TimeControl")
    FHazePlaySequenceData TimeMH;
	
	UPROPERTY(Category = "TimeControl")
    FHazePlaySequenceData Equip;

	UPROPERTY(Category = "TimeControl")
    FHazePlayBlendSpaceData TurnInPlace;
	
	UPROPERTY(Category = "TimeControl")
    FHazePlayBlendSpaceData Aim;





	

};