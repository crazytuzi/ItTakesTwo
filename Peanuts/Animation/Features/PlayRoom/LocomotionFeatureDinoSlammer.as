class ULocomotionFeatureDinoSlammer : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureDinoSlammer()
    {
        Tag = n"DinoSlammer";
    }


    // Movement BlendSpace
    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MH;

	UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MH_Bwd;

    // Turn Animation
    UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Turn;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Turn_Bwd;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Fall;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Fall_Bwd;

	// Slam Animation
    UPROPERTY(Category = "Slam")
    FHazePlayRndSequenceData Slam;

	// Slam Animation
    UPROPERTY(Category = "Slam")
    FHazePlayRndSequenceData FailedSlam;

	UPROPERTY(Category = "Slam")
    FHazePlayRndSequenceData FailedSlamBwd;

	UPROPERTY(Category = "Slam")
    FHazePlayRndSequenceData Slam_Bwd;

    // Player Animation
    UPROPERTY(Category = "PlayerAnimation")
    FHazePlaySequenceData JumpOn;

	// Player Animation
    UPROPERTY(Category = "PlayerAnimation")
    FHazePlaySequenceData JumpOff;

	// IK Reference pose
    UPROPERTY(Category = "IK Reference pose")
    FHazePlaySequenceData IK_ref;

	// IK Reference pose
    UPROPERTY(Category = "IK Reference pose")
    FHazePlaySequenceData IK_refBwd;

};