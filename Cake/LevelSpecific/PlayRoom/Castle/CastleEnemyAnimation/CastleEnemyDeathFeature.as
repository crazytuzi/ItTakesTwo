class UCastlEnemyDeathFeature : UHazeLocomotionFeatureBase
{
    UCastlEnemyDeathFeature()
    {
        Tag = n"CastleEnemyDeath";
    }

    UPROPERTY(Category = "Castle Enemy Death")
    FHazePlaySequenceData Death;

	UPROPERTY(Category = "Castle Enemy Death")
    FHazePlayBlendSpaceData DeathBS;
	

};