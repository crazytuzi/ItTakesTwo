import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;

class ULarvaDropMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Dropping");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

    ULarvaMovementDataComponent BehaviourMoveComp = nullptr;

    FHazeAcceleratedQuat Rotation;
    FHazeAcceleratedQuat UpRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourMoveComp = ULarvaMovementDataComponent::Get(Owner);
        ensure((BehaviourMoveComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (BehaviourMoveComp.MoveType != ELarvaMovementType::Drop)
            return EHazeNetworkActivation::DontActivate;
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (BehaviourMoveComp.MoveType != ELarvaMovementType::Drop)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Rotation.SnapTo(FQuat(Owner.GetActorRotation()));
        UpRotation.SnapTo(MoveComp.WorldUp.ToOrientationQuat());
		BehaviourMoveComp.UseNonPathfindingCollisionSolver();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
        FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"LarvaDropMovement");

        // Align with world up
		FQuat CurUpRot = UpRotation.AccelerateTo(FVector::UpVector.ToOrientationQuat(), 1.f, DeltaSeconds);
        Owner.ChangeActorWorldUp(CurUpRot.Vector());

		if (HasControl())
		{
			FVector ToDest = Owner.ActorForwardVector;
			if (BehaviourMoveComp.bHasDestination)
			{
				ToDest = BehaviourMoveComp.Destination - Owner.GetActorLocation();
				if (ToDest.IsZero())
					ToDest = Owner.ActorForwardVector;
			}

			// Turn towards destination
			FQuat TargetRotation = ToDest.ToOrientationQuat(); 
			Rotation.Value = FQuat(Owner.GetActorRotation());
			Rotation.AccelerateTo(TargetRotation, 1.5f, DeltaSeconds);
			MoveComp.SetTargetFacingRotation(Rotation.Value); 

			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration(FVector::UpVector);// Always apply gravity in world down
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}
        MoveCharacter(MoveData, n"Drop");
		CrumbComp.LeaveMovementCrumb();

        // Consume destination
        BehaviourMoveComp.bHasDestination = false;
	}
};
