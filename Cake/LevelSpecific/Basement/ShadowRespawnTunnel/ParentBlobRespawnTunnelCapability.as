import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobRespawnTunnelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"ParentBlob");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default CapabilityDebugCategory = n"ParentBlob";

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	AParentBlob ParentBlob;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"Respawning"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"Respawning"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		UMovementSettings::SetActorMaxFallSpeed(Owner, 8000.f, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.SetTargetFacingDirection(Owner.ActorForwardVector);
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		UMovementSettings::ClearActorMaxFallSpeed(Owner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"RespawnTunnel");
		FrameMove.ApplyActorVerticalVelocity();
		FrameMove.ApplyGravityAcceleration();
		MoveComp.Move(FrameMove);

		ParentBlob.SendAnimationRequest(FrameMove, n"RespawnTunnel");
	}
}