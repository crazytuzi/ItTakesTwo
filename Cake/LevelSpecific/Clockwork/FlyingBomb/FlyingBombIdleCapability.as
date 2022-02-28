import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;

class UFlyingBombIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombIdle");
	default CapabilityTags.Add(n"FlyingBombAI");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 150;

	AFlyingBomb Bomb;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	FRandomStream RandomStream;
	FVector TargetPosition;

	FHazeAcceleratedRotator AccelRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
		MoveComp = Bomb.MoveComp;
		CrumbComp = Bomb.CrumbComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddNumber(n"Seed", FMath::Rand());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RandomStream.Initialize(ActivationParams.GetNumber(n"Seed"));
		TargetPosition = Bomb.StartPosition;

		Bomb.State = EFlyingBombState::Idle;

		FRotator StartRotation = Bomb.ActorRotation;
		StartRotation.Pitch = Bomb.VisualRoot.RelativeRotation.Pitch;
		StartRotation.Roll = 0.f;
		AccelRotation.SnapTo(StartRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;
		if (Bomb.LocalWantHeldByBird != nullptr)
			return;

		FVector Velocity = MoveComp.Velocity;
		FVector PreviousVelocity = Velocity;
		FVector DeltaToTarget = TargetPosition - Bomb.ActorLocation;
		float DistanceToTarget = DeltaToTarget.Size();

		FVector DirectionToTarget = DeltaToTarget;
		if (DistanceToTarget > 0.f)
			DirectionToTarget /= DistanceToTarget;

		float AccelerationDirection = 1.f;

		// Modify velocity to go in the direction of the target
		Velocity += DirectionToTarget * Bomb.IdleAcceleration * AccelerationDirection;
		Velocity = Velocity.GetClampedToMaxSize(Bomb.IdleMaxVelocity);

		// Damped lateral velocity so we don't orbit
		if (DistanceToTarget > 0.f)
		{
			FVector ForwardVelocity = Velocity.ProjectOnTo(DirectionToTarget);
			FVector LateralVelocity = Velocity - ForwardVelocity;
			Velocity = ForwardVelocity + (LateralVelocity * FMath::Pow(0.9f, DeltaTime));
		}

		// Check if we reached the target during this move
		float DistanceFromMovement = FMath::ClosestPointOnLine(Bomb.ActorLocation, Bomb.ActorLocation + (Velocity * DeltaTime), TargetPosition).Distance(TargetPosition);
		if (DistanceFromMovement < Bomb.IdleTargetReachedDistance)
		{
			// Make a new target position for next frame
			TargetPosition = Bomb.StartPosition + (RandomStream.VRand() * Bomb.IdleRadius * 0.9f);
		}

		// Tilt the bomb based on its velocity
		float Speed = Velocity.Size2D();

		FRotator WantRotation;
		if (Speed > 1.f)
		{
			WantRotation = FRotator::MakeFromX(Velocity);
			WantRotation.Roll = 0.f;
			WantRotation.Pitch = -(Speed / Bomb.IdleMaxVelocity) * Bomb.IdleMaxTiltPitch;
		}
		else
		{
			WantRotation = Bomb.ActorRotation;
		}

		AccelRotation.AccelerateTo(WantRotation, 1.f, DeltaTime);
		Bomb.VisualRoot.RelativeRotation = FRotator(AccelRotation.Value.Pitch, 0.f, 0.f);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FlyingBombIdle");
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.OverrideCollisionProfile(n"NoCollision");
		FrameMove.SetRotation(FRotator(0.f, AccelRotation.Value.Yaw, 0.f).Quaternion());
		MoveComp.Move(FrameMove);

		//System::DrawDebugLine(Bomb.ActorLocation, TargetPosition, FLinearColor::Red);
		//System::DrawDebugSphere(Bomb.StartPosition, Bomb.IdleRadius);
	}
};
