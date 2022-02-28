import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyHealthCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::LastDemotable;

    ACastleEnemy Enemy;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        // This is a hack to make sure bTookDamageThisFrame is
        // reset at the end of all capabilities having ticked,
        // so we don't lose any damage frames.
        if(Enemy.bTookDamageThisFrame)
        {
            Enemy.bTookDamageThisFrame = false;
            Enemy.FrameDamageEvents.Empty();
        }
    }
};