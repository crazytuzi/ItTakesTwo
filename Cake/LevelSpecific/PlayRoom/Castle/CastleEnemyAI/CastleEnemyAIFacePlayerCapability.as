import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAIFacePlayerCapability : UCharacterMovementCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyMovement");
    default CapabilityTags.Add(n"CastleEnemyAI");

    ACastleEnemy Enemy;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		Super::Setup(Params);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (Enemy.AggroedPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate; 

		if (Enemy.bChangeNetworkSideOnAggro && !Enemy.AggroedPlayer.HasControl())
			return EHazeNetworkActivation::DontActivate; 

		return EHazeNetworkActivation::ActivateUsingCrumb; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (Enemy.AggroedPlayer == nullptr)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyFacePlayer");

		if (HasControl())
		{
			AHazePlayerCharacter FacingPlayer = Enemy.AggroedPlayer;
			FVector ToTarget = FacingPlayer.ActorLocation - Enemy.ActorLocation;

			MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToTarget.GetSafeNormal()), Enemy.FacingRotationSpeed);
			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		Movement.ApplyTargetRotationDelta();
		Movement.FlagToMoveWithDownImpact();
		MoveComp.Move(Movement);

		Enemy.SendMovementAnimationRequest(Movement, n"Movement", NAME_None);
    }
};