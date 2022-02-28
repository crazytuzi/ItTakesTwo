import Vino.Pickups.PickupActor;
import Vino.Pickups.Putdown.Capabilities.PutdownCapabilityBase;
import Vino.Trajectory.TrajectoryStatics;

class UGroundPutdownCapability : UPutdownCapabilityBase
{
    default CapabilityTags.Add(PickupTags::PutdownGroundCapability);

	FThrownActorReachedTarget ObjectPlacedOnFloorDelegate;

	FVector PlayerLocationOverride;
	float PlayerMoveSpeed;
	const float PlayerMoveDuration = 0.1f;

    float PutdownSpeed = 7.0f;
    float RotationSpeed = 5.0f;

    bool bPutdownAnimationEnded;
    bool bIsRotatingTowardsPutdownLocation;

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        if(ActivePutdownParams.PutdownType != EPutdownType::Ground)
	        return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        Super::OnActivated(ActivationParams);

        bPutdownAnimationEnded = false;

		PutdownSequence = PickupComponent.CurrentPickupDataAsset.PutDownAnimation;

        StartFacingPutdownDirection();

		// Calculate necessary info if this was a force drop with player movement
		if(ActivePutdownParams.OverrideParams.bMovePlayerNextToPutdownLocation)
		{
			PlayerLocationOverride = ActivePutdownParams.PutdownLocation - ActivePutdownParams.PlayerTargetPutdownRotation.ForwardVector.GetSafeNormal() * GetIdealDistanceFromPutdownLocation();
			PlayerMoveSpeed = PlayerOwner.ActorLocation.Distance(PlayerLocationOverride) / PlayerMoveDuration;
		}
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return bPutdownAnimationEnded ? EHazeNetworkDeactivation::DeactivateLocal : EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		PlayerOwner.UnbindAnimNotifyDelegate(UAnimNotify_Pickup::StaticClass(), PutDownNotify);
		Super::OnDeactivated(DeactivationParams);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
         // Check if player is already facing the desired rotation
        float TargetDotForward = MovementComponent.GetTargetFacingRotation().GetForwardVector().DotProduct(Owner.GetActorForwardVector());
		if(bIsRotatingTowardsPutdownLocation)
		{
			if(FMath::IsNearlyEqual(TargetDotForward, 1.0f, 0.01f))
			{
				bIsRotatingTowardsPutdownLocation = false;
				PlayPutdownAnimation();
			}
		}

		// Move with ground
        FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(n"Putdown");
		MoveData.FlagToMoveWithDownImpact();
		MoveData.ApplyGravityAcceleration();
        MoveData.ApplyTargetRotationDelta();

		if(ActivePutdownParams.OverrideParams.bMovePlayerNextToPutdownLocation)
		{
			float SmoothAlpha = FMath::Min(ActiveDuration, PlayerMoveDuration) / PlayerMoveDuration;
			float SmoothMultiplier = FMath::Max(0.2f, FMath::Sin(SmoothAlpha * 3.1416f));

			FVector MoveVector = PlayerLocationOverride - PlayerOwner.ActorLocation;
			FVector DeltaMove = MoveVector.GetSafeNormal() * PlayerMoveSpeed * SmoothMultiplier * DeltaTime;
			MoveData.ApplyDelta(DeltaMove);
		}

		// Don't request shit for one frame to allow previous SM to transition
		if(ActiveDuration > 0.f)
		{
			FHazeRequestLocomotionData LocomotionRequest;
			LocomotionRequest.AnimationTag = n"Movement";
			PlayerOwner.RequestLocomotion(LocomotionRequest);
		}

        MovementComponent.Move(MoveData);
    }

    void StartFacingPutdownDirection()
    {
        // Don't change player rotation if we can put object down 
        if(ActivePutdownParams.PlayerTargetPutdownRotation.IsNearlyZero())
        {
            PlayPutdownAnimation();
            return;
        }

        // Starts lerping player rotation towards clear putdown space
        MovementComponent.SetTargetFacingRotation(ActivePutdownParams.PlayerTargetPutdownRotation.GetNormalized(), ActiveMovementSettings.GroundRotationSpeed);
        bIsRotatingTowardsPutdownLocation = true;
    }

	float GetIdealDistanceFromPutdownLocation()
	{
		FTransform AlignBoneTransform;
		Animation::GetAnimAlignBoneTransform(AlignBoneTransform, PickupComponent.CurrentPickupDataAsset.PutDownAnimation, PickupComponent.CurrentPickupDataAsset.PutDownAnimation.PlayLength);
		return AlignBoneTransform.GetTranslation().Size();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnObjectPlacedOnFloor(AActor Actor, FVector LastTracedVelocity, FHitResult HitResult, bool bIsControlThrow)
	{
		APickupActor PickupActor = Cast<APickupActor>(Actor);
		PickupActor.OnPlacedOnFloorEvent.Broadcast(PlayerOwner, PickupActor);
		ObjectPlacedOnFloorDelegate.Unbind(this, n"OnObjectPlacedOnFloor");
	}

    UFUNCTION(NotBlueprintCallable)
    void OnAnimationEnded() override
    {
		if(!IsActive())
			return;

        bPutdownAnimationEnded = true;
    }
}