class UCastleEnemyKnightFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyKnightFeature()
    {
        Tag = n"CastleEnemyKnight";
    }

	UPROPERTY()
    FHazePlayRndSequenceData Summon;

	UPROPERTY()
    FHazePlaySequenceData IdleMH;

	UPROPERTY()
    FHazePlayRndSequenceData RunStart;

	UPROPERTY()
	FHazePlayBlendSpaceData Running;
	
}