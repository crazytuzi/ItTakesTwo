class ULocomotionFeatureSnowGlobeWindWalk : UHazeLocomotionFeatureBase
{
	default Tag = n"WindWalk";

	UPROPERTY(Category = "WindWalk")
	FHazePlayBlendSpaceData Walk;


	UPROPERTY(Category = "WindWalkMagnet")
	FHazePlaySequenceData MagnetEnter;

	UPROPERTY(Category = "WindWalkMagnet")
	FHazePlayBlendSpaceData UsingMagnets;

	UPROPERTY(Category = "WindWalkMagnet")
	FHazePlaySequenceData MagnetExit;

	// IK ref for when the character is holding the magnet
	UPROPERTY(Category = "InverseKinematics")
	FHazePlaySequenceData IKRef;

	UPROPERTY(Category = "Totem")
	bool bIsTotemRiding;

};