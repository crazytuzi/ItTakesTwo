class UCastleEnemyRookFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyRookFeature()
    {
        Tag = n"CastleEnemyPiece";
    }

	UPROPERTY()
    FHazePlaySequenceData Summon;

	UPROPERTY()
    FHazePlaySequenceData IdleMH;

	UPROPERTY()
    FHazePlaySequenceData AnticipationStart;

	UPROPERTY()
	FHazePlaySequenceData AnticipationMH;

	UPROPERTY()
	FHazePlaySequenceData AttackStart;

	UPROPERTY()
    FHazePlaySequenceData AttackMove;

	UPROPERTY()
    FHazePlaySequenceData Impact;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData SlamAnticipation;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData SlamAnticipationMH;

	UPROPERTY(Category = "Slam")
	FHazePlayBlendSpaceData AnticipationBlend;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData SlamAttack;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData SlamMH;
}