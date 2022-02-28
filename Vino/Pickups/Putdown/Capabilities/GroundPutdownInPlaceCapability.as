import Vino.Pickups.Putdown.Capabilities.PutdownCapabilityBase;

class UGroundPutdownInPlaceCapability : UPutdownCapabilityBase
{
	default CapabilityTags.Add(PickupTags::PutdownGroundInPlaceCapability);

	bool bPutdownAnimationEnded;
	bool bIsRotatingTowardsPutdownLocation;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(ActivePutdownParams.PutdownType != EPutdownType::GroundInPlace)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		PutdownSequence = PickupComponent.CurrentPickupDataAsset.PutDownInPlaceAnimation;
		bPutdownAnimationEnded = false;

		// Don't change player rotation if we can put object down 
        if(ActivePutdownParams.PlayerTargetPutdownRotation.IsNearlyZero())
        {
            PlayPutdownAnimation();
            return;
        }

        // Starts lerping player rotation towards clear putdown space
        MovementComponent.SetTargetFacingRotation(ActivePutdownParams.PlayerTargetPutdownRotation.GetNormalized(), ActiveMovementSettings.GroundRotationSpeed * 1.2f);
        bIsRotatingTowardsPutdownLocation = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMovement = MovementComponent.MakeFrameMovement(PickupTags::PutdownGroundInPlaceCapability);
		FrameMovement.FlagToMoveWithDownImpact();
		FrameMovement.ApplyGravityAcceleration();
        FrameMovement.ApplyTargetRotationDelta();

		// Don't request shit for one frame to allow previous SM to transition
		if(ActiveDuration > 0.f)
		{
			FHazeRequestLocomotionData LocomotionRequest;
			LocomotionRequest.AnimationTag = n"Movement";
			PlayerOwner.RequestLocomotion(LocomotionRequest);
		}

		if(bIsRotatingTowardsPutdownLocation)
		{
			// Check if player is already facing the desired rotation
			float TargetDotForward = MovementComponent.GetTargetFacingRotation().GetForwardVector().DotProduct(Owner.GetActorForwardVector());
			if(FMath::IsNearlyEqual(TargetDotForward, 1.0f, 0.01f))
			{
				bIsRotatingTowardsPutdownLocation = false;
				PlayPutdownAnimation();
			}
		}
		else
		{
			FHazeLocomotionTransform LocomotionRootTransform;
			PlayerOwner.RequestRootMotion(DeltaTime, LocomotionRootTransform);
			FrameMovement.ApplyRootMotion(LocomotionRootTransform);
		}

        MovementComponent.Move(FrameMovement);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bPutdownAnimationEnded)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnbindAnimNotifyDelegate(UAnimNotify_Pickup::StaticClass(), PutDownNotify);
		Super::OnDeactivated(DeactivationParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnAnimationEnded() override
	{
		bPutdownAnimationEnded = true;
	}
}