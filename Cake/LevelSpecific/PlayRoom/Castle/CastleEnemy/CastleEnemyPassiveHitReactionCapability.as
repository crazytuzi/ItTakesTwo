import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAnimation.CastleEnemyKnockbackFeature;

class UCastleEnemyPassiveHitReactionCapability : UHazeCapability
{
    default CapabilityTags.Add(n"CastleEnemyKnockback");
    default CapabilityTags.Add(n"CastleEnemyPassiveHitReaction");

    UPROPERTY()
    float HitReactionTime = 0.25f;

    ACastleEnemy Enemy;
    UHazeBaseMovementComponent MoveComp;

    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 30;

	float TimeRemaining = 0.f;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Enemy);

        Enemy.OnKnockedBack.AddUFunction(this, n"OnKnockedBack");
    }

    UFUNCTION()
    void OnKnockedBack(ACastleEnemy KnockedEnemy, FCastleEnemyKnockbackEvent Event)
    {
		TimeRemaining = HitReactionTime;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (TimeRemaining > 0.f)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (TimeRemaining <= 0.f)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		UCastleEnemyKnockbackFeature Feature = UCastleEnemyKnockbackFeature::Get(Enemy);
		//Enemy.StopAdditiveAnimation(Feature.HitReaction.Sequence);
		//Enemy.PlayAdditiveAnimation(FHazeAnimationDelegate(), Feature.HitReaction.Sequence);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
    }
};