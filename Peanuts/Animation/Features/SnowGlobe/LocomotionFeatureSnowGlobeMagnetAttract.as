class ULocomotionFeatureSnowGlobeMagnetAttract : UHazeLocomotionFeatureBase
{
    default Tag = n"MagnetAttract";

    // Start anim
    UPROPERTY(Category = "MagnetAttract")
    FHazePlaySequenceData Start;

    // Flying Mh
    UPROPERTY(Category = "MagnetAttract")
    FHazePlaySequenceData Mh;

	// Enter animation when getting stuck on the wall
    UPROPERTY(Category = "PearchWall")
    FHazePlaySequenceData WallEnter;

	// Mh while stuck on the wall
    UPROPERTY(Category = "PearchWall")
    FHazePlaySequenceData WallMh;

	// Transition from WallMh to GroundMh (triggers while on a moving platform)
    UPROPERTY(Category = "PearchWall")
    FHazePlaySequenceData WallToGround;

	// Transition from WallMh to RoofMh (triggers while on a moving platform)
    UPROPERTY(Category = "PearchWall")
    FHazePlaySequenceData WallToRoof;

	UPROPERTY(Category = "PearchWall")
    FHazePlaySequenceData WallJump;

	// Enter animation when getting stuck on the ground
    UPROPERTY(Category = "PearchGround")
    FHazePlaySequenceData GroundEnter;

	// Enter animation when close enough to the magnet platform to skip the flying state
    UPROPERTY(Category = "PearchGround")
    FHazePlaySequenceData GroundCloseEnter;

	// Mh while stuck on the ground
    UPROPERTY(Category = "PearchGround")
    FHazePlaySequenceData GroundMh;

    // Exit from Ground Mh (will go into default Mh once done)
    UPROPERTY(Category = "PearchGround")
    FHazePlaySequenceData GroundExit;

	// Transition from GroundMh to WallMh (triggers while on a moving platform)
    UPROPERTY(Category = "PearchGround")
    FHazePlaySequenceData GroundToWall;

	// Enter animation when getting stuck on the roof
    UPROPERTY(Category = "PearchRoof")
    FHazePlaySequenceData RoofEnter;

	// Mh while stuck on the roof
    UPROPERTY(Category = "PearchRoof")
    FHazePlaySequenceData RoofMh;

    // Jump off roof (will go into Falling once done)
    UPROPERTY(Category = "PearchRoof")
    FHazePlaySequenceData RoofExit;

	// Transition from RoofMh to WallMh (triggers while on a moving platform)
    UPROPERTY(Category = "PearchRoof")
    FHazePlaySequenceData RoofToWall;

	// Transition from RoofMh to WallMh (triggers while on a moving platform)
    UPROPERTY(Category = "Players")
    FHazePlaySequenceData AttractionCollide;

};