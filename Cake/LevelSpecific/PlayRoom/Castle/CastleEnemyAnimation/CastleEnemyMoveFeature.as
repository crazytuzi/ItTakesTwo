class UCastleEnemyMovementFeature : UHazeLocomotionFeatureBase
{
   default Tag = n"Movement";

    UPROPERTY(Category = "Castle Enemy Movement")
    FHazePlayRndSequenceData Idle;

    UPROPERTY(Category = "Castle Enemy Movement")
    FHazePlaySequenceByValueData Movement;
};