import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

class USnowFolkMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkMovementCapability");
	default CapabilityDebugCategory = n"SnowFolkMovementCapability";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	ASnowfolkSplineFollower Snowfolk;
	UConnectedHeightSplineFollowerComponent SplineFollowerComp;
	USnowFolkMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UNiagaraComponent NiagaraComp;
	float LerpInTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snowfolk = Cast<ASnowfolkSplineFollower>(Owner);
		SplineFollowerComp = UConnectedHeightSplineFollowerComponent::Get(Snowfolk);
		MoveComp = Snowfolk.MovementComp;
		CrumbComp = UHazeCrumbComponent::Get(Snowfolk);
		NiagaraComp = UNiagaraComponent::Get(Snowfolk);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!Snowfolk.bCanMove)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsRecovering)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsHit)
			return EHazeNetworkActivation::DontActivate;
			
		if (Snowfolk.bIsDown)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Snowfolk.bCanMove)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsRecovering)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsDown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		// Hard-set the values :^)
		float SpeedScale = Snowfolk.MovementComp.bIsSkating ? 0.0001f : 0.003f / Snowfolk.ActorScale3D.X;
		Snowfolk.BSSpeed = FMath::Clamp(SplineFollowerComp.Velocity.Size(), 0.f, 10000.f) * SpeedScale;
		Snowfolk.BSLeanValue = FMath::Clamp(SplineFollowerComp.AngularVelocity.Z, -1.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		Snowfolk.BSSpeed = 0.f;
		Snowfolk.BSLeanValue = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SpeedScale = MoveComp.bIsSkating ? 0.0001f : 0.003f / Snowfolk.ActorScale3D.X;
		Snowfolk.BSSpeed = FMath::Clamp(SplineFollowerComp.Velocity.Size(), 0.f, 10000.f) * SpeedScale;
		Snowfolk.BSLeanValue = FMath::Lerp(Snowfolk.BSLeanValue, FMath::Clamp(SplineFollowerComp.AngularVelocity.Z, -1.f, 1.f), 5.f * DeltaTime);

		// Calculate spawn rate for snow-behind-feet VFX when moving
		float NiagaraSpawnRate = MoveComp.bIsSkating ? FMath::Clamp(FMath::Abs(SplineFollowerComp.AngularVelocity.Z), 0.f, 20.f) * 10.f :
			FMath::Square(FMath::Clamp(SplineFollowerComp.Velocity.Size(), 0.f, 1000.f) * 0.01f);

		NiagaraComp.SetNiagaraVariableFloat("SpawnRate", NiagaraSpawnRate);

		// Move the actor and rotate
		FVector Location =MoveComp.CurrentTransform.Location;
		FQuat Rotation = MoveComp.CurrentTransform.Rotation;
		Rotation = FQuat::Slerp(Owner.ActorQuat, Rotation, DeltaTime * 10.f);

		Owner.SetActorLocationAndRotation(Location, Rotation.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		Snowfolk.bMovementIsBlocked = IsBlocked();
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		Snowfolk.bMovementIsBlocked = IsBlocked();
	}
}