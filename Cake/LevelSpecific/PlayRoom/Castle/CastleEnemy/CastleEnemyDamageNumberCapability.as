import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleDamageNumbers;

class UCastleEnemyDamageNumberCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::AfterPhysics;

    UPROPERTY()
    TSubclassOf<UCastleDamageNumberWidget> WidgetClass;

    UCastlePlayerDamageNumberComponent NumberComp;
    ACastleEnemy Enemy;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);

        NumberComp = UCastlePlayerDamageNumberComponent::GetOrCreate(Game::GetMay());
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (Enemy.bTookDamageThisFrame)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (!Enemy.bTookDamageThisFrame)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        for (FCastleEnemyDamageEvent Damage : Enemy.FrameDamageEvents)
        {
			EHazePlayer PlayerInvolved = EHazePlayer::MAX;
			auto PlayerSource = Cast<AHazePlayerCharacter>(Damage.DamageSource);
			if (PlayerSource != nullptr)
				PlayerInvolved = PlayerSource.Player;

            ShowCastleDamageNumber(PlayerSource, WidgetClass, Damage.DamageDealt, Damage.DamageLocation, Damage.DamageDirection, Damage.DamageSpeed, Damage.bIsCritical, false, PlayerInvolved);
        }
    }
};