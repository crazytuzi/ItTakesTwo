class UCastleEnemyBishopFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyBishopFeature()
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
	FHazePlayBlendSpaceData AnticipationBlend;

	UPROPERTY()
	FHazePlaySequenceData AttackStart;

	UPROPERTY()
    FHazePlaySequenceData AttackMH;

	UPROPERTY()
    FHazePlaySequenceData Impact;
}