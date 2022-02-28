enum ClockBirdLandingType {
	JumpLanding,
	FlyLanding,
	DiveLanding,
}

class ULocomotionFeatureClockBird : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureClockBird()
    {
        Tag = n"ClockBird";
    }

    UPROPERTY(Category = "Enter")
    FHazePlaySequenceData Enter;

    // Movement BlendSpace
    UPROPERTY(Category = "AirMovement")
    FHazePlayBlendSpaceData Gliding;
	// Movement BlendSpace
	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Flap;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData SecondFlap;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData DiveFlap;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData DiveStart;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Dive;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Brake;

	UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData TurnBack;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Dash;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Hover;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData BombLegOverride;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData InitialFlap;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Catch;

    UPROPERTY(Category = "AirMovement")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "GroundMovement")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "GroundMovement")
    FHazePlayRndSequenceData Jog;

	UPROPERTY(Category = "GroundMovement")
    FHazePlaySequenceData Stop;

    UPROPERTY(Category = "TakeOff")
    FHazePlaySequenceData Jump;

	UPROPERTY(Category = "TakeOff")
    FHazePlaySequenceData FlapJump;

	UPROPERTY(Category = "Landing")
    FHazePlaySequenceData FlyLanding;

	UPROPERTY(Category = "Landing")
    FHazePlaySequenceData JumpLanding;

	UPROPERTY(Category = "Landing")
    FHazePlaySequenceData DiveLanding;

};