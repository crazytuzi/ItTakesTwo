class ULocomotionFeatureSnowGlobeMagnetJump : UHazeLocomotionFeatureBase
{
    default Tag = n"MagnetJump";

    // Charge animation before jump
    UPROPERTY(Category = "MagnetJump")
    FHazePlaySequenceData Charge;

	// Charge wall
    UPROPERTY(Category = "MagnetJump")
    FHazePlaySequenceData ChargeWall;

 	// Exit anim while charging
    UPROPERTY(Category = "MagnetJump")
    FHazePlaySequenceData ChargeExit;

    // Jump animation (will go into Falling once done)
    UPROPERTY(Category = "MagnetJump")
    FHazePlaySequenceData Jump;

	// Jump wall animation
    UPROPERTY(Category = "MagnetJump")
    FHazePlaySequenceData JumpWall;

};