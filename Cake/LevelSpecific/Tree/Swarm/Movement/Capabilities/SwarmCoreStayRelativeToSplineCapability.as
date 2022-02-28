
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Movement.SwarmMovementComponent;

/*  Ensures that the Swarm keeps a relative location to the spline its supposed to follow. Regardless how fast that spline is moving */

class USwarmCoreStayRelativeToSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmMovement");
	default CapabilityTags.Add(n"SwarmMovementFollowActor");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ASwarmActor SwarmActor = nullptr;
	USwarmMovementComponent MoveComp = nullptr;

	AActor PreviousSplineActor = nullptr;
	FVector DebugExactLocation = FVector::ZeroVector;
	FTransform PreviousSplineTransform = FTransform::Identity;
	FVector SprungSplineLocation = FVector::ZeroVector;
	FVector SpringVelocity = FVector::ZeroVector;

	float AccelerateToDuration = 3.f;
	float LAMBERT_NOMINATOR = 9.23341f; // Within 0.1% error
//	float LAMBERT_NOMINATOR = 6.63835; // Within 1% error
	float AccelerateToTimeElapsed = 0.f;

	float SpringStiffness = 55555.f;
	float SpringDamping = 1.0f;
// 	float SpringStiffness = 10.f;
// 	float SpringDamping = 0.4f;

	void ResetTransient()
	{
		PreviousSplineActor = MoveComp.FollowSplineActor;
		PreviousSplineTransform = MoveComp.GetSplineToFollowTransform();
		SprungSplineLocation = MoveComp.GetSplineToFollowTransform().GetLocation();
		SpringVelocity = FVector::ZeroVector;
		AccelerateToTimeElapsed = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		MoveComp = USwarmMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MoveComp.HasSplineToFollow())
			return EHazeNetworkActivation::ActivateFromControl;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		PreviousSplineActor = MoveComp.FollowSplineActor;
		PreviousSplineTransform = MoveComp.GetSplineToFollowTransform();
		SprungSplineLocation = MoveComp.GetSplineToFollowTransform().GetLocation();
		DebugExactLocation = SwarmActor.MovementComp.DesiredSwarmActorTransform.GetLocation();
 	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float Dt)
	{
		const FTransform CurrentSplineTransform = MoveComp.GetSplineToFollowTransform();
		const FVector DeltaTranslation = CurrentSplineTransform.GetLocation() - PreviousSplineTransform.GetLocation();

		// early out for zero case
		if (DeltaTranslation.IsZero())
		{
			// added the reset here without testing..
			ResetTransient();
			return;
		}

		// Need to reset if we happen to switch spline.
		if (PreviousSplineActor != MoveComp.FollowSplineActor)
		{
			ResetTransient();
			return;
		}

		FVector DeltaMove = DeltaTranslation;

		if (AccelerateToTimeElapsed < AccelerateToDuration)
		{
			// Update swarm root actor transform (AccelerateTo) 
			const float Duration = FMath::Max(KINDA_SMALL_NUMBER, AccelerateToDuration - AccelerateToTimeElapsed);
			const float Acceleration = LAMBERT_NOMINATOR / Duration;
			const FVector ToTarget = CurrentSplineTransform.GetLocation() - SprungSplineLocation;
			SpringVelocity += ToTarget * FMath::Square(Acceleration) * Dt;
			SpringVelocity /= FMath::Square(1.f + Acceleration * Dt);
			AccelerateToTimeElapsed += Dt;

			// Update swarm root actor transform (SpringTo) 
//			const float IdealDampingValue = 2.f * FMath::Sqrt(SpringStiffness);
//			const FVector ToPrevSpringLocation = SprungSplineLocation - CurrentSplineTransform.GetLocation();
//			SpringVelocity -= (ToPrevSpringLocation * Dt * SpringStiffness);
//			SpringVelocity /= (1.f + (Dt * Dt * SpringStiffness) + (SpringDamping * IdealDampingValue * Dt));

			ensure(SpringVelocity.ContainsNaN() == false);

			DeltaMove = SpringVelocity * Dt;
			SprungSplineLocation += DeltaMove;
		}

  		MoveComp.DesiredSwarmActorTransform.AddToTranslation(DeltaMove);

		// Update particles
		for(USwarmSkeletalMeshComponent SwarmSkelMeshIter : SwarmActor.SwarmSkelMeshes)
		{
			for (int i = 0; i < SwarmSkelMeshIter.Particles.Num(); ++i)
			{
				SwarmSkelMeshIter.ApplyDeltaTranslationToParticleByIndex(i, DeltaMove);
			}
		}

		PreviousSplineTransform = CurrentSplineTransform;

// 		DebugExactLocation += DeltaTranslation;
// 		System::DrawDebugPoint(DebugExactLocation, 30.f, PointColor = FLinearColor::Blue);

	}

	FTransform GetSplineTransform() const
	{
		if (MoveComp.HasSplineToFollow())
			return MoveComp.FollowSplineActor.GetActorTransform();
		else
			ensure(false);
		return FTransform::Identity;
	}

}

















