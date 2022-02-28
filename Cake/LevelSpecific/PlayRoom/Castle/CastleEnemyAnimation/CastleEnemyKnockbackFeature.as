class UCastleEnemyKnockbackFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyKnockbackFeature()
    {
        Tag = n"CastleEnemyKnockback";
    }

    UPROPERTY(Category = "Castle Enemy Knockback")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "Castle Enemy Knockback")
    FHazePlayBlendSpaceData HitReactionBS;
};