import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureMagnetStrafe;

class ULocomotionFeatureMagnetStrafeTotem: ULocomotionFeatureMagnetStrafe
{
    default Tag = n"MagnetStrafeTotem";

	// Used for if the player is riding the other player
	UPROPERTY(BlueprintReadOnly, Category = "Totem")
    bool bTopTotemPlayer;

	UPROPERTY(Category = "Totem")
    FHazePlaySequenceData TopPlayerMagnetOffsetRef;

	UPROPERTY(Category = "Movement")
    FHazePlaySequenceData Exit;

};