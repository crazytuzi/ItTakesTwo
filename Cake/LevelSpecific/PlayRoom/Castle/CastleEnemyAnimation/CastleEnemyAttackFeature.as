class UCastleEnemyAttackFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyAttackFeature()
    {
        Tag = n"CastleEnemyAttack";
    }

	/* Animation used when starting to telegraph the attack. */
    UPROPERTY(Category = "Castle Enemy Attack")
    FHazePlaySequenceData TelegraphStartAnim;

	/* Looping MH animation used after telegraphing the attack. */
    UPROPERTY(Category = "Castle Enemy Attack")
    FHazePlaySequenceData TelegraphMHAnim;

	/* Animation used when the attack starts. */
    UPROPERTY(Category = "Castle Enemy Attack")
    FHazePlayRndSequenceData AttackExecuteAnims;

};