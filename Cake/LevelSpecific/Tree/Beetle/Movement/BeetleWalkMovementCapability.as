import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Beetle.Movement.BeetleMovementDataComponent;
import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;

class UBeetleWalkMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Walking");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	UBeetleBehaviourComponent BehaviourComp = nullptr;
    UBeetleMovementDataComponent MoveDataComp = nullptr;
	UCapsuleComponent CollisionComp = nullptr;

    FHazeAcceleratedFloat Speed;
    FHazeAcceleratedRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
        MoveDataComp = UBeetleMovementDataComponent::Get(Owner);
		CollisionComp = UCapsuleComponent::Get(Owner);
		ensure((CollisionComp != nullptr) && (MoveDataComp != nullptr) && (BehaviourComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComp.State == EBeetleState::None)
    	  	return EHazeNetworkActivation::DontActivate;
		if (MoveDataComp.MoveType != EBeetleMovementType::Walk)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		AHazePlayerCharacter May = Game::May;
		AHazePlayerCharacter Cody = Game::Cody;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		if (BehaviourComp.State == EBeetleState::None)
    	 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (MoveDataComp.MoveType != EBeetleMovementType::Walk)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Speed.SnapTo(Owner.GetActualVelocity().DotProduct(Owner.GetActorForwardVector()));
        Rotation.SnapTo(Owner.GetActorRotation());
		BehaviourComp.LogEvent("Activating walk movement.");
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
        FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"BeetleMovement");
		if (HasControl())
		{
			FVector ToDest = FVector::ZeroVector;
			FVector Velocity = FVector::ZeroVector;
			if (MoveDataComp.bHasDestination)
			{
				// We have a destination
				FVector Destination = MoveDataComp.Destination;
				ToDest = Destination - Owner.GetActorLocation();
				ToDest.Z = 0.f; // Ground bound

				// Accelerate when moving towards destination, otherwise come to a stop
				float DistToDest = ToDest.Size();
				float TargetSpeed = MoveDataComp.Speed;
				if (DistToDest < 40.f)
					TargetSpeed = 0.f; // Almost there!
				Speed.AccelerateTo(TargetSpeed, 2.f, DeltaSeconds);
				
				if (DistToDest > 0.f)
					Velocity = ToDest * (Speed.Value / DistToDest); // Normalized ToDest * Speed

				if (!ToDest.IsZero())
				{
					// Turn towards destination
					FRotator TargetRotation = Velocity.Rotation(); 
					if (TargetSpeed == 0) 
						TargetRotation = ToDest.Rotation(); // Turning in place
					Rotation.Value = Owner.GetActorRotation();
					Rotation.AccelerateTo(TargetRotation, MoveDataComp.TurnDuration, DeltaSeconds);
					MoveComp.SetTargetFacingRotation(Rotation.Value); 
				}
			}
			else
			{
				// No destination, come to a stop
				Speed.AccelerateTo(0.f, 0.5f, DeltaSeconds);
				Velocity = Owner.GetActorForwardVector() * Speed.Value; 
			}

			MoveData.ApplyVelocity(Velocity);
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			// Remote, follow crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}
        MoveCharacter(MoveData, n"Walking");
		CrumbComp.LeaveMovementCrumb();

        // Consume destination
        MoveDataComp.bHasDestination = false;
	}
};
