enum EHazeAnimationCrouchEnters {
	Mh,
	Movement,
	AirMovement,
	GroundPound,
	Sliding,
	SlidingMovement
}

class ULocomotionFeatureCrouch : UHazeLocomotionFeatureBase
{
	default Tag = n"Crouch";

	// If this is true, blendspaces are used for exiting into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	
	bool UseBlendspacesToMovement = false;

	UPROPERTY(Category = "LookAt")
	bool bUseLookAt = false;

	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData Mh;

	// Mh -> Walk
	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData Start;

	// Walk -> Mh
	UPROPERTY(Category = "Crouch")
	FHazePlaySequenceData Stop;

	UPROPERTY(Category = "Crouch")
	FHazePlayBlendSpaceData Walk;

	// Enter crouch mh from the default mh
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterMh;

	// Enter crouch walk from jog
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterMovement;

	// Enter crouch mh from AirMovement/Falling
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterLanding;

	// Enter crouch mh from a groundPound
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterGroundPound;

	// Enter crouch mh from sliding
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterSliding;

	// Enter crouch walking from sliding
	UPROPERTY(Category = "Crouch Enter")
	FHazePlaySequenceData EnterWalkSliding;


	// Exit from Croch_Mh -> Mh
	UPROPERTY(Category = "Crouch Exits")
	FHazePlaySequenceData ExitMh;

	// Exit from Croch_Walk -> Walk
	UPROPERTY(Category = "Crouch Exits")
	FHazePlaySequenceData ExitToMovement;

	// Exit from Croch_Walk -> MovementAdvanced
	UPROPERTY(Category = "Crouch Exits")
	FHazePlayBlendSpaceData ExitToMovementBS;

};