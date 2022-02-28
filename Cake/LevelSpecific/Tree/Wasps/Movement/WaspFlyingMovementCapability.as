import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

class UWaspFlyingMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Flying");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 20.f;

    UWaspBehaviourComponent BehaviourComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UWaspBehaviourComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WaspFlyingMovement");
		if (HasControl())
		{
			float Acceleration = BehaviourComp.Acceleration;
			if (Acceleration < 0.f)
				Acceleration = 0.f;

			FVector Destination = BehaviourComp.GetMoveDestination();
			Destination += BehaviourComp.TargetGroundVelocity.Value * DeltaSeconds; // One tick behind

			// Accelerate towards destination with friction 
			// As it's air movement it can be nice to get some oscillation, 
			// so don't use critically dampened spring acceleration. 
			FVector Velocity = MoveComp.GetVelocity();
			FVector ToTargetDir = (Destination - Owner.GetActorLocation()).GetSafeNormal();
			FVector AccleratedVelocity = ToTargetDir * Acceleration;
			FVector Dampening = Velocity * 1.3f;
			Velocity += (AccleratedVelocity - Dampening) * DeltaSeconds;
	
			MoveData.ApplyVelocity(Velocity);
			MoveData.ApplyTargetRotationDelta();

			if (BehaviourComp.MovementLockHeightStrength > 0.f) 
				MoveData.ApplyDelta(FVector(0.f, 0.f, FMath::Lerp(0.f, BehaviourComp.MovementLockedHeight - Owner.ActorLocation.Z, DeltaSeconds * BehaviourComp.MovementLockHeightStrength)));

			// We expect behaviours to set acceleration each tick, or we will just drift to a stop
			BehaviourComp.Acceleration = 0.f;
			BehaviourComp.MovementLockHeightStrength = 0.f;
		}
		else
		{
			// Remote, follow them crumbsies
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();
	}
};
