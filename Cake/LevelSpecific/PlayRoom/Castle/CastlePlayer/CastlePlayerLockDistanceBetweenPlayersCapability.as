import Peanuts.Movement.DeltaProcessor;

class UCastlePlayerLockDistanceBetweenPlayersCapability : UHazeCapability
{
	UMaxPlayerDistanceProcessor Processor;
	UHazeBaseMovementComponent MoveComp;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		Processor = UMaxPlayerDistanceProcessor();
		Processor.PlayerOwner = PlayerOwner;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
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

}

class UMaxPlayerDistanceProcessor : UDeltaProcessor
{
	AHazePlayerCharacter PlayerOwner;
	float MaxDistance = 3300.f;

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTime) override
	{
		FVector HorizontalDelta;
		FVector VerticalDelta;
		Math::DecomposeVector(VerticalDelta, HorizontalDelta, SolverState.RemainingDelta, ActorState.WorldUp);

		FVector HorizSeparation = (SolverState.CurrentLocation + HorizontalDelta) - PlayerOwner.OtherPlayer.ActorLocation;
		HorizSeparation.Z = 0.f;

		float DistanceSQ = HorizSeparation.SizeSquared();
		if (DistanceSQ < FMath::Square(MaxDistance))
			return;

		float Distance = FMath::Sqrt(DistanceSQ);
		FVector AwayDirection = HorizSeparation / Distance;
		float AwayPart = HorizontalDelta.DotProduct(AwayDirection);
		if (AwayPart > 0.f)
			HorizontalDelta -= AwayDirection * AwayPart;

		SolverState.RemainingDelta = HorizontalDelta + VerticalDelta;
	}
}
