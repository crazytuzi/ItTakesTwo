import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledPlayerEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledPlayerEnter);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;
	UBoatsledComponent BoatsledComponent;

	FVector TargetLocation;
	FHazeAcceleratedVector AcceleratedLocation;

	FQuat TargetRotation;
	FHazeAcceleratedQuat AcceleratedRotation;

	const float AccelerationDuration = 0.1f;

	float EnterAnimationEndStamp;

	bool bMovingTowardsBoatsled;
	bool bEnterAnimationIsDone;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsPlayerEnteringBoatsled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetLocation = BoatsledComponent.Boatsled.PlayerEnterAnimationOffset.WorldLocation;
		AcceleratedLocation.SnapTo(PlayerOwner.ActorLocation);

		TargetRotation = BoatsledComponent.Boatsled.ActorRotation.Quaternion();
		AcceleratedRotation.SnapTo(PlayerOwner.ActorRotation.Quaternion());

		bMovingTowardsBoatsled = true;
		EnterAnimationEndStamp = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Create frame movement
		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(BoatsledTags::BoatsledPlayerEnter);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideCollisionProfile(n"NoCollision");

		if(bMovingTowardsBoatsled)
		{
			// Move player towards socket
			FVector MoveDelta = AcceleratedLocation.AccelerateTo(TargetLocation, AccelerationDuration, DeltaTime) - PlayerOwner.ActorLocation;
			MoveData.ApplyDelta(MoveDelta);

			// Rotate towards boatsled
			FQuat Rotation = AcceleratedRotation.AccelerateTo(TargetRotation, AccelerationDuration, DeltaTime);
			MoveData.SetRotation(Rotation);

			// Request locomotion
			if(PlayerOwner.Mesh.CanRequestLocomotion())
			{
				FHazeRequestLocomotionData LocomotionRequest;
				LocomotionRequest.AnimationTag = FeatureName::Movement;
				PlayerOwner.RequestLocomotion(LocomotionRequest);
			}

			// Play enter animation when we're done 
			if(ActiveDuration >= AccelerationDuration)
			{
				PlayEnterAnimation(BoatsledComponent.Boatsled.GetEnterAnimation(PlayerOwner));
				PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(TargetRotation.Rotator(), AccelerationDuration);
				bMovingTowardsBoatsled = false;
			}
		}
		else
		{
			FHazeLocomotionTransform RootMotion;
			PlayerOwner.RequestRootMotion(DeltaTime, RootMotion);
			MoveData.ApplyRootMotion(RootMotion);
		}

		// Move!
		MovementComponent.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveDuration >= EnterAnimationEndStamp)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Stop frozen enter animation and commence das waiting
		PlayerOwner.StopAllSlotAnimations(0.f);
		BoatsledComponent.SetStateLocal(EBoatsledState::WaitingForOtherPlayer);

		// Reset mesh offset rotation
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime(0.f);

		// Cleanup
		bMovingTowardsBoatsled = false;
		bEnterAnimationIsDone = false;
	}

	void PlayEnterAnimation(UAnimSequence& EnterAnimation)
	{
		EnterAnimationEndStamp = ActiveDuration + EnterAnimation.PlayLength;
		PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), EnterAnimation, bPauseAtEnd = true, BlendTime = 0.1f);
	}
}