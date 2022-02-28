import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;

class UFlyingBombGoBackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombGoBack");
	default CapabilityTags.Add(n"FlyingBombAI");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 40;

	AFlyingBomb Bomb;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	bool bReachedStart = false;

	const float GoBackTime = 8.f;

	FHazeAcceleratedRotator AccelRotation;
	FHazeAcceleratedVector AccelPosition;

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
		if (Bomb.CurrentState != EFlyingBombState::Chasing)
			return EHazeNetworkActivation::DontActivate;
		if (Bomb.ChasingBird != nullptr)
		{
			float Distance = Bomb.ChasingBird.ActorLocation.DistSquared(Bomb.StartPosition);
			if (Distance < FMath::Square(Bomb.EscapeRadius))
				return EHazeNetworkActivation::DontActivate;
		}
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Bomb.CurrentState != EFlyingBombState::GoingBack)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (bReachedStart)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// This is the default setting
		//ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bomb.State = EFlyingBombState::GoingBack;
		bReachedStart = false;

		Bomb.BlockCapabilities(n"FlyingBombChase", this);

		FRotator StartRotation = Bomb.ActorRotation;
		StartRotation.Pitch = Bomb.VisualRoot.RelativeRotation.Pitch;
		StartRotation.Roll = 0.f;
		AccelRotation.SnapTo(StartRotation);

		AccelPosition.SnapTo(Bomb.ActorLocation, Bomb.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		DeactivationParams.EnableTransformSynchronizationWithTime(0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bomb.UnblockCapabilities(n"FlyingBombChase", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		FRotator WantRotation = AccelRotation.Value;
		FVector WantPosition;
		float RotationAccel = 1.f;

		WantPosition = AccelPosition.AccelerateTo(Bomb.StartPosition,
			FMath::Max(GoBackTime - ActiveDuration, 0.f), DeltaTime);
		RotationAccel = 0.5f;

		if (AccelPosition.Value.Equals(Bomb.StartPosition, 50.f))
			bReachedStart = true;

		if (!MoveComp.Velocity.IsNearlyZero())
		{
			WantRotation = FRotator::MakeFromX(MoveComp.Velocity.GetSafeNormal());
			WantRotation.Pitch += 90.f;
			WantRotation.Roll = 0.f;
		}

		AccelRotation.AccelerateTo(WantRotation, RotationAccel, DeltaTime);
		Bomb.VisualRoot.RelativeRotation = FRotator(AccelRotation.Value.Pitch, 0.f, 0.f);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FlyingBombGoBack");
		FrameMove.ApplyDelta(WantPosition - Bomb.ActorLocation);
		FrameMove.SetRotation(FRotator(0.f, AccelRotation.Value.Yaw, 0.f).Quaternion());
		FrameMove.OverrideCollisionProfile(n"NoCollision");
		MoveComp.Move(FrameMove);
	}
};