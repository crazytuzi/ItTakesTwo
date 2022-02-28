import Vino.Pickups.PickupActor;
import Vino.Trajectory.TrajectoryStatics;

// This capability assumes that movement is enabled on pickup actor (see PickupActor::SetMovementEnabled())
class UPickupGroundPutdownCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupGroundPutdownCapability);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	APickupActor PickupOwner;
	UHazeMovementComponent MovementComponent;
	UHazeCrumbComponent CrumbComponent;

	AHazePlayerCharacter PreviousHoldingPlayer;

	FHazeAcceleratedQuat AcceleratedPickupRootRotation;

	FQuat InitialRotation;
	FQuat PutdownRotationOverride;

	FVector PutdownLocation;

	float RotationTime;
	float InitialDistanceToPutdownLocation;

	bool bHasSnappedInitialRotation;
	bool bShouldOverrideActorRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupOwner = Cast<APickupActor>(Owner);
		MovementComponent = PickupOwner.MovementComponent;
		CrumbComponent = PickupOwner.CrumbComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(PickupTags::PickupGroundPutdown))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		// Get blackboard reference set by PickupOwner when letting go
		UObject PreviousHoldingPlayerObject;
		ConsumeAttribute(n"PreviousHoldingPlayer", PreviousHoldingPlayerObject);
		SyncParams.AddObject(n"PreviousHoldingPlayer", PreviousHoldingPlayerObject);

		// Get putdown location
		ConsumeAttribute(PickupTags::PickupGroundPutdownLocation, PutdownLocation);
		SyncParams.AddVector(PickupTags::PickupGroundPutdownLocation, PutdownLocation);

		// Consume rotation override (if any)
		FVector RotationOverride;
		if(ConsumeAttribute(PickupTags::PickupGroundPutdownRotationOverride, RotationOverride))
		{
			SyncParams.AddActionState(n"ShouldOverrideActorRotation");
			SyncParams.AddVector(PickupTags::PickupGroundPutdownRotationOverride, RotationOverride);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Get crumbed params
		PreviousHoldingPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"PreviousHoldingPlayer"));
		PutdownLocation = ActivationParams.GetVector(PickupTags::PickupGroundPutdownLocation);
		if(bShouldOverrideActorRotation = ActivationParams.GetActionState(n"ShouldOverrideActorRotation"))
			PutdownRotationOverride = ActivationParams.GetVector(PickupTags::PickupGroundPutdownRotationOverride).ToOrientationQuat();

		// In case this is some anti-gravity pickup (weird up putdowns not supported)
		PickupOwner.ChangeActorWorldUp(PreviousHoldingPlayer.MovementWorldUp);

		// Calculate velocity to reach point
		FOutCalculateVelocity TrajectoryInfo = CalculateParamsForPathWithHeight(PickupOwner.ActorLocation, PutdownLocation, MovementComponent.GravityMagnitude, PickupOwner.PickupRadius * (PickupOwner.bPutDownInPlace ? 0.05f : 0.5f), WorldUp = MovementComponent.WorldUp);

		// Add inherited velocity to throw if player is standing on mobile ground
		FVector InheritedVelocity;
		FVector RelativeLocationOnGround;
		UPrimitiveComponent GroundComponent;
		UHazeMovementComponent PlayerMovementComponent = UHazeMovementComponent::Get(PreviousHoldingPlayer);
		if(PlayerMovementComponent.GetCurrentMoveWithComponent(GroundComponent, RelativeLocationOnGround))
			InheritedVelocity = PlayerMovementComponent.ActualVelocity;

		// Set initial throw velocity
		MovementComponent.SetVelocity(TrajectoryInfo.Velocity + InheritedVelocity);

		// Set the time we'll take to rotate pickup actor
		RotationTime = TrajectoryInfo.Time * 0.8f;

		// Used only on first frame after moving the actor -see accelerator snap
		InitialRotation = PickupOwner.PickupRoot.RelativeTransform.TransformRotation(PickupOwner.ActorRotation.Quaternion()) * PickupOwner.OriginalPickupRootRelativeRotation;

		// Used to calculate rotation speed
		InitialDistanceToPutdownLocation = PickupOwner.ActorLocation.Distance(PutdownLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(PickupTags::PickupSystem);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			// Add gravity and apply verocity
			FVector Velocity = MovementComponent.Velocity + MovementComponent.Gravity * DeltaTime;
			MoveData.ApplyVelocity(Velocity);

			// Rotate actor towards override, in case there is one
			if(bShouldOverrideActorRotation)
			{
				MovementComponent.SetTargetFacingRotation(PutdownRotationOverride, (InitialDistanceToPutdownLocation / RotationTime));
				MoveData.ApplyTargetRotationDelta();
			}
			// Face actor towards velocity if there is no putdown rotation override
			else
			{
				MoveData.SetRotation(Velocity.ToOrientationQuat());
			}

			// Move and leave crumb
			MovementComponent.Move(MoveData);
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);

			MovementComponent.Move(MoveData);
		}

		// Rotate mesh after actor has moved
		TickRotation(DeltaTime);
	}

	void TickRotation(float DeltaTime)
	{
		// Eman NOTE: Snapping rotation before moving the actor for at least one frame doesn't seem to work. WHY?! ='(
		if(!bHasSnappedInitialRotation)
		{
			AcceleratedPickupRootRotation.SnapTo(PickupOwner.OriginalPickupRootRelativeRotation * PickupOwner.ActorRotation.Quaternion().Inverse() * InitialRotation);
			bHasSnappedInitialRotation = true;
		}

		// Rotate pickup actor to settle rotation
		AcceleratedPickupRootRotation.AccelerateTo(PickupOwner.OriginalPickupRootRelativeRotation, RotationTime, DeltaTime);
		PickupOwner.PickupRoot.SetRelativeRotation(AcceleratedPickupRootRotation.Value);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MovementComponent.DownHit.bBlockingHit && MovementComponent.DownHit.Component.HasTag(n"Walkable"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		SyncParams.AddVector(n"ActorLocation", Owner.ActorLocation);
		SyncParams.AddVector(n"ActorRotation", Owner.ActorRotation.Vector());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// There can be a remote transform desync under extreme ass network- ensure witaj!
		PickupOwner.SetActorLocation(DeactivationParams.GetVector(n"ActorLocation"));
		PickupOwner.SetActorRotation(DeactivationParams.GetVector(n"ActorRotation").Rotation());

		// Feuer!
		PickupOwner.OnPlacedOnFloorEvent.Broadcast(PreviousHoldingPlayer, PickupOwner);

		// Clear rotation
		PickupOwner.PickupRoot.SetRelativeRotation(PickupOwner.OriginalPickupRootRelativeRotation);

		// Cleanup
		PreviousHoldingPlayer = nullptr;
		AcceleratedPickupRootRotation.SnapTo(FQuat::Identity);
		InitialRotation = FQuat::Identity;
		PutdownRotationOverride = FQuat::Identity;
		RotationTime = 0.f;
		InitialDistanceToPutdownLocation = 0.f;
		bHasSnappedInitialRotation = false;
		bShouldOverrideActorRotation = false;
	}
}