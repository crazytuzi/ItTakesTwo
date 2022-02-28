class UCastleEnemyTeleportFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyTeleportFeature()
    {
        Tag = n"CastleEnemyTeleport";
    }

    UPROPERTY(Category = "Castle Enemy Teleport")
    FHazePlaySequenceData TeleportEnter;

    UPROPERTY(Category = "Castle Enemy Teleport")
    FHazePlaySequenceData TeleportExit;
};