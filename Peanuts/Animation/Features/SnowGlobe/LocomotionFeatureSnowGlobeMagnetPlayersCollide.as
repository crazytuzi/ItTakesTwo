class ULocomotionFeatureSnowGlobeMagnetPlayersCollide : UHazeLocomotionFeatureBase
{
    default Tag = n"PlayersCollide";

    // Collision
    UPROPERTY(Category = "PlayersCollide")
    FHazePlaySequenceData Collide;

	// Mh to play until the players let go of the control
    UPROPERTY(Category = "PlayersCollide")
    FHazePlaySequenceData Mh;

};