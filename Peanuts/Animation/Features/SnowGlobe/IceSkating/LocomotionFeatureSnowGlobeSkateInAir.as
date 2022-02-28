class ULocomotionFeatureSnowGlobeSkateInAir : UHazeLocomotionFeatureBase
{
	default Tag = n"SkateInAir";

	UPROPERTY(Category = "AirGlide", BlueprintReadOnly)
	const FName AirGlideSubAnimTag = n"SkateAirGlide";

	//Plays when entering InAir from something other than jump
	UPROPERTY(Category = "InAirMovement")
	FHazePlayRndSequenceData InAirEntry;

	UPROPERTY(Category = "InAirMovement")
	FHazePlayBlendSpaceData InAirMovement;

	UPROPERTY(Category = "AirGlide")
	FHazePlaySequenceData FallIntoAirGlide;

	UPROPERTY(Category = "AirGlide")
	FHazePlaySequenceData AirGlideEnter;

	UPROPERTY(Category = "AirGlide")
	FHazePlayBlendSpaceData AirGlideMovement;
};