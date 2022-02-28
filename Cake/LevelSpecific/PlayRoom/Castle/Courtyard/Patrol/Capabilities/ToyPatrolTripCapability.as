import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

class UToyPatrolTripCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ToyPatrolTrip");
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	AToyPatrol ToyPatrol;
	UToyPatrolTripComponent TripComponent;
	FVector TripDirection;
	float RecoverTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		ToyPatrol = Cast<AToyPatrol>(Owner);
		TripComponent = UToyPatrolTripComponent::Get(Owner);

		TripComponent.OnTrip.AddUFunction(this, n"HandleTrip");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ToyPatrol.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"Tripped"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ToyPatrol.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Time::GameTimeSeconds >= RecoverTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		ToyPatrol.BlockCapabilities(n"ToyPatrolIdle", this);
		ToyPatrol.BlockCapabilities(n"ToyPatrolMovement", this);

		float TripDuration = 0.f;
		ConsumeAttribute(n"TripDirection", TripDirection);
		ConsumeAttribute(n"TripDuration", TripDuration);

		if (TripDirection.IsNearlyZero())
			TripDirection = ToyPatrol.ActorForwardVector;

		RecoverTime = Time::GameTimeSeconds + TripDuration;
		ToyPatrol.AudioPatrolComp.HandleInteruption();

		ToyPatrol.AudioPatrolComp.PatrolActorHazeAkComp.HazePostEvent(ToyPatrol.AudioPatrolComp.OnTackledEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		ToyPatrol.UnblockCapabilities(n"ToyPatrolIdle", this);
		ToyPatrol.UnblockCapabilities(n"ToyPatrolMovement", this);
		ToyPatrol.AudioPatrolComp.FinishInteruption();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"CastleEnemyDeath";
		AnimRequest.MoveSpeed = ToyPatrol.MovementSpeed;
 		AnimRequest.WantedVelocity = TripDirection;
		ToyPatrol.RequestLocomotion(AnimRequest);
	}

	UFUNCTION()
	void HandleTrip(AHazeActor Actor, FVector Direction, float Duration)
	{
		ToyPatrol.SetCapabilityActionState(n"Tripped", EHazeActionState::ActiveForOneFrame);
		ToyPatrol.SetCapabilityAttributeVector(n"TripDirection", Direction);
		ToyPatrol.SetCapabilityAttributeValue(n"TripDuration", Duration);
	}
}