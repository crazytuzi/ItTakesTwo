class UCastleEnemyCrusherFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyCrusherFeature()
    {
        Tag = n"CastleEnemyCrusher";
    }

	UPROPERTY()
    FHazePlaySequenceData IdleMH;

	UPROPERTY()
    FHazePlaySequenceData MoveForwards;

	UPROPERTY()
    FHazePlaySequenceData Smash;
}