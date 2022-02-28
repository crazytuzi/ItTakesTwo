enum ESwimmingBreachExitType {
	Dive,
	DiveBackflip,
	DiveFast,
	GroundDive
};

enum ESwimmingBreachEnterTypes {
    None,
	Ground,
	SwimmingBoost,
	DoubleJump
};

class ULocomotionFeatureSnowGlobeSwimmingBreach : UHazeLocomotionFeatureBase
{

    default Tag = n"SwimmingBreach";

	UPROPERTY(Category = "Dive")
    FHazePlaySequenceData GroundDiveEnter;

	UPROPERTY(Category = "Dive")
    FHazePlaySequenceData DoubleJumpDiveEnter;

	UPROPERTY(Category = "Dive")
	bool bAllowTransitionFromGroundToBreach = true;

    // Default Breach Blendspace
    UPROPERTY(Category = "SwimmingBreach")
    FHazePlayBlendSpaceData Breach;

    // Breach from dash, will blend over to Breach once completed.
    UPROPERTY(Category = "SwimmingBreach")
    FHazePlaySequenceData BreachFromDash;

	 // The maximum position that BreachFromDash is allowed to start from based on how far the dash anim has played.
    UPROPERTY(Category = "SwimmingBreach")
    float MaxedAllowedDashDashStartPosition = 0.9f;

	// Freestlye FrontFlip
    UPROPERTY(Category = "Freestyle")
    FHazePlaySequenceData FrontFlip;

	// Freestlye BackFlip
    UPROPERTY(Category = "Freestyle")
    FHazePlaySequenceData BackFlip;

	UPROPERTY(Category = "Freestyle")
    float FrontFlipRotationRate = 600.f;

	UPROPERTY(Category = "Freestyle")
    float BackFlipRotationRate = 600.f;


    // Dive Start, will play if the player's Z-Velocity is moving upwards when it's triggered
    UPROPERTY(Category = "DiveFast")
    FHazePlaySequenceData DiveEnter;

	// Dive enter to play if character is doing a freestyle backflip
    UPROPERTY(Category = "DiveFast")
    FHazePlaySequenceData DiveEnterBackflip;

    // Dive Mh to hold until the player hits the water
    UPROPERTY(Category = "DiveFast")
    FHazePlaySequenceData DiveMh;

    // Dive Fast Start, will play if the player's Z-Velocity is moving downwards when it's triggered
    UPROPERTY(Category = "DiveFast")
    FHazePlaySequenceData DiveFastEnter;

    // Dive Fast Mh to hold until the player hits the water
    UPROPERTY(Category = "DiveFast")
    FHazePlaySequenceData DiveFastMh;

    // Exit to Swimming
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData ExitToSwimming;

	// Exit to Swimming
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData ExitToSwimmingFromGroundDive;

    // Exit to swimming from a dive
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData ExitToSwimmingFromDive;

    // Exit to swimming from a fast dive
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData ExitToSwimmingFromFastDive;

    // Exit to swimming Mh
    UPROPERTY(Category = "Exit")
    FHazePlaySequenceData ExitToSwimmingMh;

	// Optional
	UPROPERTY(Category = "CustomDiveFromGround")
    FHazePlaySequenceData CustomDiveFromGround;

};