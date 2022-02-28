import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

class UToyPatrolIdleAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ToyPatrolIdle");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	AToyPatrol ToyPatrol;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		ToyPatrol = Cast<AToyPatrol>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ToyPatrol.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::DontActivate;
	
		return EHazeNetworkActivation::ActivateLocal; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ToyPatrol.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate; 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.WantedWorldFacingRotation = ToyPatrol.ActorQuat;
		AnimRequest.WantedWorldTargetDirection = ToyPatrol.ActorForwardVector;
		AnimRequest.AnimationTag = n"Movement";

		ToyPatrol.RequestLocomotion(AnimRequest);
	}
}