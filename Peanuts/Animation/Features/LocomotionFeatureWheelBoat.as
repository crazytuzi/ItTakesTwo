class ULocomotionFeatureWheelBoat : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWheelBoat()
    {
        Tag = n"WheelBoat";
    }

	//MH

	UPROPERTY(Category = "Player MH")
	FHazePlayBlendSpaceData MH;

	UPROPERTY(Category = "Player Port side")
    FHazePlaySequenceData LeftEnter;

	UPROPERTY(Category = "Player Port side")
    FHazePlaySequenceData LeftExit;

	UPROPERTY(Category = "Player Port side")
    FHazePlaySequenceData LeftFire;

	UPROPERTY(Category = "Player Starboard side")
    FHazePlaySequenceData RightEnter;
	
	UPROPERTY(Category = "Player Starboard side")
    FHazePlaySequenceData RightExit;

	UPROPERTY(Category = "Player Starboard side")
    FHazePlaySequenceData RightFire;

	UPROPERTY(Category = "Ship")
	FHazePlayBlendSpaceData Wheels;

	UPROPERTY(Category = "Ship")
	FHazePlaySequenceData BoatSlamReaction;

	UPROPERTY(Category = "Ship")
    FHazePlaySequenceData BoatEmerge;

	UPROPERTY(Category = "Ship")
	FHazePlaySequenceData BoatCannonBallHitReaction;

	UPROPERTY(Category = "Ship")
	FHazePlayBlendSpaceData CannonCharge;

	UPROPERTY(Category = "Ship")
	FHazePlaySequenceData CannonFire;

	//UPROPERTY(Category = "Ship")
	FHazePlayBlendSpaceData RightWheel;
	
	//UPROPERTY(Category = "Ship")
	FHazePlayBlendSpaceData RightCannonCharge;

	//UPROPERTY(Category = "Ship")
	FHazePlaySequenceData RightCannonFire;

	UPROPERTY(Category = "Ship")
    FHazePlaySequenceData BoatDeath;


};