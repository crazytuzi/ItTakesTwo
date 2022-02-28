
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

class UCastleChessBossDeathCapability : UHazeCapability
{
	default TickGroupOrder = 1;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

    ACastleEnemy Enemy;
	UHazeBaseMovementComponent MoveComp;
	UChessPieceComponent PieceComp;

	bool bDead = false;
	FVector InitialVelocity;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnKilled.AddUFunction(this, n"OnKilled");
		Enemy.bDelayDeath = true;

		MoveComp = UHazeBaseMovementComponent::Get(Enemy);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
    }

    UFUNCTION()
    void OnKilled(ACastleEnemy DamagedEnemy, bool bKilledByDamage)
    {
        bDead = true;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bDead)
            return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		InitialVelocity = Enemy.ActorVelocity;

        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
        Owner.BlockCapabilities(n"CastleEnemyAttack", this);
        Owner.BlockCapabilities(n"CastleEnemyAbility", this);
        Owner.BlockCapabilities(n"CastleEnemyAI", this);

		Enemy.bUnhittable = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (Enemy.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleChessPiece";
			Request.SubAnimationTag = n"Death";

			Enemy.Mesh.RequestLocomotion(Request);
		}

		if (PieceComp.Chessboard != nullptr && PieceComp.Chessboard.bKingAndQueenDisable)
		{
			Enemy.SetActorHiddenInGame(true);
		}
    }
};