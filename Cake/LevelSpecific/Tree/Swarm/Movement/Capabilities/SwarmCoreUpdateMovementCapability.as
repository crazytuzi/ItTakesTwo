
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

class USwarmCoreUpdateMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmMovement");

	default TickGroup = ECapabilityTickGroups::LastMovement;

	ASwarmActor SwarmActor = nullptr;
	USwarmMovementComponent MoveComp = nullptr;

	float PrevDeltaTime = 0.f;
	FVector PrevLocation = FVector::ZeroVector;
	FVector PrevPhysicsVelocity = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = USwarmMovementComponent::Get(Owner);
		SwarmActor = Cast<ASwarmActor>(Owner);

		PrevLocation = SwarmActor.GetActorLocation();
		PrevPhysicsVelocity = MoveComp.PhysicsVelocity;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MoveComp.DesiredSwarmActorTransform.GetLocation().IsZero())
			return EHazeNetworkActivation::DontActivate;

		// local is intentional. DesiredLocation might be zerovector when it activates on remote otherwise
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MoveComp.DesiredSwarmActorTransform.GetLocation().IsZero())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		const FVector DesiredLocation = MoveComp.DesiredSwarmActorTransform.GetLocation(); 

		ensure(DesiredLocation != FVector::ZeroVector);

		// calculate velocity based on the delta move performed between 2 frames.
		const FVector DeltaMoveSincePreviousRecordedMove = DesiredLocation - PrevLocation;
		MoveComp.TranslationVelocity = DeltaMoveSincePreviousRecordedMove / (DeltaTime + PrevDeltaTime);
		PrevDeltaTime = DeltaTime;

		// Physics == Translation velocity - when it isn't being used.
		if (PrevPhysicsVelocity == MoveComp.PhysicsVelocity)
		{
			MoveComp.PhysicsVelocity = MoveComp.TranslationVelocity;

			// Clamp the speed to something sane
			const float VSQ = MoveComp.PhysicsVelocity.SizeSquared();
			const float MaxSpeed = 10000.f;
			if(VSQ > FMath::Square(MaxSpeed))
			{
				const float Scale = MaxSpeed * FMath::InvSqrt(VSQ);
				MoveComp.PhysicsVelocity *= Scale;
			}

		}

		MoveComp.SwarmAcceleration = MoveComp.PhysicsVelocity - PrevPhysicsVelocity;
		MoveComp.SwarmAcceleration /= DeltaTime;

		PrevPhysicsVelocity = MoveComp.PhysicsVelocity;

		// Update prev location before we move the swarm
		const FVector CurrentLocation = SwarmActor.GetActorLocation();
		PrevLocation = CurrentLocation;

		// only update transform if we actual need to move
		const FVector DesiredDeltaMove = DesiredLocation - CurrentLocation;
		if(!DesiredDeltaMove.IsZero())
			SwarmActor.SetActorTransform(MoveComp.DesiredSwarmActorTransform);
		else if(!SwarmActor.ActorQuat.Equals(MoveComp.DesiredSwarmActorTransform.Rotation))
			SwarmActor.SetActorTransform(MoveComp.DesiredSwarmActorTransform);

		if(MoveComp.bReachedEndOfSpline)
		{
			// we'll keep this local here. HasControl + NetFunction can be applied when it is needed. 
			SwarmActor.OnReachedEndOfSpline.Broadcast(SwarmActor);
			MoveComp.bReachedEndOfSpline = false;
		}

//		PrintToScreen("PhysicsVelocity: " + MoveComp.PhysicsVelocity.Size(), 0.f, FLinearColor::Green );
//		PrintToScreen("TranslationVelocity: " + MoveComp.TranslationVelocity.Size(), 0.f, FLinearColor::Yellow );
//		System::DrawDebugPoint(MoveComp.DesiredSwarmActorTransform.GetLocation(), 4.f, FLinearColor::Green);

	}

}
















