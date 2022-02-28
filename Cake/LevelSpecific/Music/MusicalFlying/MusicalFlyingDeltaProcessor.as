import Peanuts.Movement.DeltaProcessor;

class UMusicalFlyingDeltaProcessor : UDeltaProcessor
{
	void ImpactCorrection(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult& Impact) override
	{
		// if (Impact.bBlockingHit)
		// {
		// 	SolverState.RemainingDelta = Impact.Normal * 100.f;
		// 	SolverState.bVelocityIsDirty = true;
		// }
	}
}

class UMusicalFlyingUseDeltaProcessorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Flying");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UMusicalFlyingDeltaProcessor Processor;
	UHazeBaseMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Processor = UMusicalFlyingDeltaProcessor();
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Owner.IsAnyCapabilityActive(n"MusicalAirborne"))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Owner.IsAnyCapabilityActive(n"MusicalAirborne"))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.UseDeltaProcessor(Processor, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);
	}
};

