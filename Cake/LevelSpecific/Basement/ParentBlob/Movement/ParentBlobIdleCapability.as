import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobIdleCapability : UHazeCapability
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
		if (MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::ActivateLocal;
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Idle");
		if (HasControl())
		{
			FrameMove.ApplyTargetRotationDelta();
			FrameMove.ApplyActorVerticalVelocity();
			FrameMove.ApplyGravityAcceleration();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveComp.Move(FrameMove);
		ParentBlob.SendAnimationRequest(FrameMove, n"Movement");
	}
};