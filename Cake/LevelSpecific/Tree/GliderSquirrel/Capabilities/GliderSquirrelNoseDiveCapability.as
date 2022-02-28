import Cake.LevelSpecific.Tree.GliderSquirrel.GliderSquirrel;

class UGliderSquirrelNoseDiveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GliderSquirrel");
	default CapabilityTags.Add(n"GliderSquirrelNoseDive");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AGliderSquirrel Squirrel;
	FRotator Rotation;
	float Speed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AGliderSquirrel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Squirrel.IsDead())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Squirrel.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Rotation = Squirrel.GetActorRotation();
		Speed = Squirrel.CurrentVelocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Rotation.Pitch = FMath::Lerp(Rotation.Pitch, -80.f, 0.5f * DeltaTime);
		Rotation.Roll += 90.f * DeltaTime;
		Rotation.Yaw += Rotation.Roll * DeltaTime;

		Speed += 300.f * DeltaTime;

		Squirrel.CurrentVelocity = Rotation.ForwardVector * Speed;

		FVector Loc = Squirrel.GetActorLocation();
		FVector Delta = Squirrel.CurrentVelocity * DeltaTime;

		FHitResult Hit;
		if (System::LineTraceSingle(Loc, Loc + Delta, ETraceTypeQuery::Visibility, false, TArray<AActor>(), EDrawDebugTrace::None, Hit, true))
		{
			Squirrel.BP_OnDeath();
			Owner.DestroyActor();
		}

		Owner.SetActorRotation(Rotation);
		Owner.AddActorWorldOffset(Squirrel.CurrentVelocity * DeltaTime);
	}
}