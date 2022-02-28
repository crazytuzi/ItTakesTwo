class ULocomotionFeatureGrindShared : UHazeLocomotionFeatureBase
{

	default Tag = n"Grind";

	// The animation when you land on the rail
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlaySequenceData GrindStart;

	// The MH animation when grinding
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlayBlendSpaceData GrindBS;

	// The animation when you jump while in a Grind
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlaySequenceData GrindJump;

	// The animation when you Dash while in a Grind
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlaySequenceData GrindDash;

	UPROPERTY(Category = "GrindGrapple")
	FHazePlaySequenceData GrindGrapple;

	UPROPERTY(Category = "GrindGrapple")
	FHazePlaySequenceData GrindGrappleEnter;

	UPROPERTY(Category = "GrindTurnAround")
	FHazePlaySequenceData GrindTurnAroundSlowdown;

	UPROPERTY(Category = "GrindTurnAround")
	FHazePlaySequenceData GrindTurnAroundBoost;

}

class ULocomotionFeatureGrind : ULocomotionFeatureGrindShared
{
	// The MH animation when grinding
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlayBlendSpaceData GrindLook;

	// The MH animation when grinding
	UPROPERTY(Category = "Locomotion Grind")
	FHazePlayBlendSpaceData GrindReach;

	// Enter upside down blendspace
	UPROPERTY(Category = "UpsideDown Locomotion Grind")
	FHazePlaySequenceData UpsideDownGrindEnter;

	// The MH animation when grinding upside down
	UPROPERTY(Category = "UpsideDown Locomotion Grind")
	FHazePlayBlendSpaceData UpsideDownGrindBS;

	// The animation when you jump while in a Grind upside down
	UPROPERTY(Category = "UpsideDown Locomotion Grind")
	FHazePlaySequenceData UpsideDownGrindJump;

	// The animation when you Dash while in a Grind upside down
	UPROPERTY(Category = "UpsideDown Locomotion Grind")
	FHazePlaySequenceData UpsideDownGrindDash;

	// Leave upside down blendspace for normal one
	UPROPERTY(Category = "UpsideDown Locomotion Grind")
	FHazePlaySequenceData UpsideDownGrindExitToMh;

};