import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

class UToyPatrolPauseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ToyPatrolPause");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AToyPatrol ToyPatrol;
	UConnectedHeightSplineFollowerComponent SplineFollowerComp;
	float UnpauseTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		ToyPatrol = Cast<AToyPatrol>(Owner);
		SplineFollowerComp = UConnectedHeightSplineFollowerComponent::Get(Owner);

		SplineFollowerComp.OnReachedSplineEnd.AddUFunction(this, n"HandleReachedSplineEnd");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"ToyPatrolPause"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds >= UnpauseTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		// ToyPatrol.BlockCapabilities(n"ToyPatrolIdle", this);
		ToyPatrol.BlockCapabilities(n"ToyPatrolMovement", this);

		UnpauseTime = Time::GameTimeSeconds + ToyPatrol.PauseDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		// ToyPatrol.UnblockCapabilities(n"ToyPatrolIdle", this);
		ToyPatrol.UnblockCapabilities(n"ToyPatrolMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// FHazeRequestLocomotionData AnimRequest;
		// AnimRequest.WantedWorldFacingRotation = ToyPatrol.ActorQuat;
		// AnimRequest.WantedWorldTargetDirection = ToyPatrol.ActorForwardVector;
		// AnimRequest.AnimationTag = n"Movement";

		// ToyPatrol.RequestLocomotion(AnimRequest);
	}

	UFUNCTION()
	void HandleReachedSplineEnd(bool bForward)
	{
		ToyPatrol.SetCapabilityActionState(n"ToyPatrolPause", EHazeActionState::ActiveForOneFrame);
	}
}