import Cake.LevelSpecific.Tree.GliderSquirrel.GliderSquirrel;

class UGliderSquirrelFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GliderSquirrel");
	default CapabilityTags.Add(n"GliderSquirrelFollow");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AGliderSquirrel Squirrel;
	AFlyingMachine Target;

	FVector FollowOffset;
	FRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AGliderSquirrel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Squirrel.IsDead())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Squirrel.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		FollowOffset.X = FMath::RandRange(-1000.f, -3000.f);
		FollowOffset.Y = FMath::RandRange(-1000.f, 1000.f);
		FollowOffset.Z = FMath::RandRange(-200.f, 1000.f);
		Params.AddVector(n"Offset", FollowOffset);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Target = Squirrel.Target;
		ensure(Target != nullptr);

		FollowOffset = Params.GetVector(n"Offset");
		Rotation = Squirrel.GetActorRotation();
	}

	FVector GetTargetWorldPosition()
	{
		FVector OffsetWorld = Target.ActorTransform.TransformPosition(FollowOffset);
		return OffsetWorld;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Forward = Rotation.ForwardVector;
		FVector TargetLoc = GetTargetWorldPosition();
		FVector Direction = TargetLoc - Owner.GetActorLocation();
		float Distance = Direction.Size();
		Direction /= Distance;

		// Get how much we should yaw
		FVector RotateAxis = Forward.CrossProduct(Direction);
		float Angle = FMath::Acos(Forward.DotProduct(Direction));

		float YawDiff = 0.f;
		YawDiff = Angle * RotateAxis.GetSafeNormal().DotProduct(FVector::UpVector);

		// Do rolling, and yaw based on how much we're rolling
		float TargetRoll = (YawDiff / PI) * 400.f;
		TargetRoll = FMath::Clamp(TargetRoll, -70.f, 70.f);

		Rotation.Roll = FMath::Lerp(Rotation.Roll, TargetRoll, 4.f * DeltaTime);
		Rotation.Yaw += Rotation.Roll * 2.f * DeltaTime;

		// Pitch
		float PitchDiff = (FMath::Asin(Direction.DotProduct(FVector::UpVector)) * RAD_TO_DEG) - Rotation.Pitch;
		Rotation.Pitch += PitchDiff * 5.f * DeltaTime;

		// Figure out speed based on how much behind the target we are
		FVector Diff = TargetLoc - Owner.GetActorLocation();
		float DiffDot = Diff.DotProduct(Target.GetActorForwardVector());

		float Speed = FMath::GetMappedRangeValueClamped(
			FVector2D(400.f, 5000.f),
			FVector2D(500.f, 5000.f),
			Diff.Size()
		);

		Squirrel.CurrentVelocity = Forward * Speed;

		Owner.SetActorLocationAndRotation(Owner.ActorLocation + Squirrel.CurrentVelocity * DeltaTime, Rotation);
	}
}