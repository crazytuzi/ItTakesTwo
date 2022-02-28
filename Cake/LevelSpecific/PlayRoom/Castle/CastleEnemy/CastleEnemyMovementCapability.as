import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyMovementCapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(n"Movement");
    default CapabilityTags.Add(n"GroundMovement");
    default CapabilityTags.Add(n"CastleEnemyMovement");

    default TickGroup = ECapabilityTickGroups::ActionMovement;

    const float FrictionPerSecond = 0.5f;

	ACastleEnemy Enemy;
	UPrimitiveComponent LastFloor;
	FTransform LastCalculatedFloorTransform;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		UCharacterMovementCapability::Setup(Params);
        SetMutuallyExclusive(n"GroundMovement", true);

		Enemy = Cast<ACastleEnemy>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
			
        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate; 
    }

	bool RequiresMovementCalculation()
	{
		if (!MoveComp.IsGrounded())
			return true;

		UPrimitiveComponent FloorComp;
		FVector RelativeLocation;
		if (!MoveComp.GetCurrentMoveWithComponent(FloorComp, RelativeLocation))
			return true;
		if (FloorComp.Mobility == EComponentMobility::Static)
			return false;
		if (FloorComp != LastFloor)
			return false;
		if (FloorComp.WorldTransform.Equals(LastCalculatedFloorTransform))
			return false;
		return true;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!MoveComp.CanCalculateMovement())
			return;
		// if(!RequiresMovementCalculation())
		// {
		// 	MoveComp.SetMoveWithComponent(LastFloor, NAME_None);
		// 	return;
		// }

		FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyMovement");

		if (HasControl())
		{
			Movement.ApplyAndConsumeImpulses();
			Movement.ApplyTargetRotationDelta();

			if (MoveComp.IsAirborne() && Enemy.bTempBoolAllowFalling)
			{
				Movement.ApplyGravityAcceleration();
				Movement.ApplyActorVerticalVelocity();
			}
			Movement.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		/*if (Movement.HasAnyMovement())*/
		MoveComp.Move(Movement);

		// Record where our floor was so we know when to update
		UPrimitiveComponent FloorComp;
		FVector RelativeLocation;
		if (MoveComp.GetCurrentMoveWithComponent(FloorComp, RelativeLocation))
			LastCalculatedFloorTransform = FloorComp.WorldTransform;
		LastFloor = FloorComp;

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();
    }
};
