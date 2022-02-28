import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;

class ULarvaLeapMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Leaping");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
    default TickGroupOrder = 90;

    float LeapSpeed = 800.f;
    float LeapVertSpeed = 1200.f;

    ULarvaMovementDataComponent BehaviourMoveComp = nullptr;
    FHazeAcceleratedVector LeapVelocity;
	FHazeAcceleratedRotator UpRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourMoveComp = ULarvaMovementDataComponent::Get(Owner);
        ensure(BehaviourMoveComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (BehaviourMoveComp.MoveType != ELarvaMovementType::Leap)
            return EHazeNetworkActivation::DontActivate;
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (MoveComp.BecameGrounded())
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	    FVector LeapDir = (BehaviourMoveComp.Destination - Owner.GetActorLocation()).GetSafeNormal();
		FVector LeapVel = LeapDir * LeapSpeed;
		LeapVel.Z = LeapVertSpeed;
        LeapVelocity.SnapTo(LeapVel); 
		BehaviourMoveComp.UseNonPathfindingCollisionSolver();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        BehaviourMoveComp.MoveType = ELarvaMovementType::Crawl;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"LarvaLeap");
		UpRotation.Value = MoveComp.WorldUp.Rotation();
		UpRotation.AccelerateTo(FVector::UpVector.Rotation(), 0.3f, DeltaSeconds);
        Owner.ChangeActorWorldUp(UpRotation.Value.Vector());

		if (HasControl())
		{
			FVector TargetVel = LeapVelocity.Value;
			TargetVel.Z = -1200.f;
			LeapVelocity.AccelerateTo(TargetVel, 1.3f, DeltaSeconds);

			Move.ApplyVelocity(LeapVelocity.Value);
			Move.OverrideStepDownHeight(0.f);
			Move.OverrideStepUpHeight(0.f);
			Move.ApplyTargetRotationDelta();
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			Move.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveCharacter(Move, FeatureName::AirMovement);
	}
};
