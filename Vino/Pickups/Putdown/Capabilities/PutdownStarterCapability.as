import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.PickupActor;
import Vino.Tutorial.TutorialStatics;

class UPutdownStarterCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
    default CapabilityTags.Add(PickupTags::PutdownStarterCapability);

    default TickGroup = ECapabilityTickGroups::ReactionMovement;
    default TickGroupOrder = 14;

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	AHazePlayerCharacter PlayerOwner;
    UPlayerPickupComponent PickupComponent;
	UHazeMovementComponent MovementComponent;

	FForceDropParams ForceDropParams;
	bool bForceDropped;

	bool bShowingPutdownPrompt;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        PickupComponent = UPlayerPickupComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);

		// Bind force drop event
		PickupComponent.OnForceDropRequestedEvent.AddUFunction(this, n"OnForceDropRequested");
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComponent.CanPutDown())
			return EHazeNetworkActivation::DontActivate;

		if(bForceDropped && !ForceDropParams.bShouldPlayAnimation)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!MovementComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(bForceDropped)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComponent.CurrentPickup.bPlayerIsAllowedToPutDown)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		FPutdownParams PutdownParams = MakePutdownParams(Cast<APickupActor>(PickupComponent.CurrentPickup));
		PackSyncPutdownParams(PutdownParams, SyncParams);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		FPutdownParams PutdownParams;
		UnpackSyncPutdownParams(PutdownParams, ActivationParams);

		// Trigger event with synched putdown params
		// This event should be heard by all the different putdown capabilities
		PickupComponent.OnPlayerWantsToPutdownActorEvent.Broadcast(PutdownParams);
    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(PickupComponent == nullptr || PickupComponent.CurrentPickup == nullptr)
		{
			if(bShowingPutdownPrompt)
				RemoveCancelPromptByInstigator(PlayerOwner, this);

			return;
		}

		if(ShouldShowPutdownPrompt())
		{
			if(bShowingPutdownPrompt)
				return;

			ShowCancelPromptWithText(PlayerOwner, this, NSLOCTEXT("PickupSystem", "PutDownPrompt", "Put Down"));
			bShowingPutdownPrompt = true;
		}
		else if(bShowingPutdownPrompt)
		{
			RemoveCancelPromptByInstigator(PlayerOwner, this);
			bShowingPutdownPrompt = false;
		}
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return EHazeNetworkDeactivation::DeactivateLocal;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveCancelPromptByInstigator(PlayerOwner, this);

		ForceDropParams = FForceDropParams();
		bForceDropped = false;
	}

	FPutdownParams MakePutdownParams(const APickupActor& CurrentPickup)
	{
		FPutdownParams PutdownParams;

		if(bForceDropped)
		{
			// Activate cancel capability if player was forced to drop without animation
			if(!ForceDropParams.bShouldPlayAnimation)
			{
				PutdownParams.PutdownType = EPutdownType::Cancelled;
				return PutdownParams;
			}

			// Check if this is a 'ForceDropAtLocation', handle and return params
			if(ForceDropParams.OverrideParams.bUsePutdownLocation)
			{
				PutdownParams.PutdownType = EPutdownType::Ground;
				PutdownParams.PutdownLocation = ForceDropParams.OverrideParams.PutdownLocation;
				PutdownParams.PlayerTargetPutdownRotation = (ForceDropParams.OverrideParams.PutdownLocation - PlayerOwner.ActorLocation).Rotation();
				PutdownParams.OverrideParams = ForceDropParams.OverrideParams;

				return PutdownParams;
			}
		}

		if(CurrentPickup.bPutDownInPlace)
		{
			CalculateInPlacePlayerPutdownRotation(CurrentPickup, PutdownParams);
		}
		else
		{
			CalculatePlayerPutdownRotation(CurrentPickup, PutdownParams);
		}

		return PutdownParams;
	}

	void CalculatePlayerPutdownRotation(const APickupActor& CurrentPickup, FPutdownParams& PutdownParams)
	{
		bool bPutdownIsValid = false;

		FVector PickupableZExtents = FVector(0.f, 0.f, CurrentPickup.PickupExtents.Z);
		FVector ActorForwardVector = Owner.GetActorForwardVector();
		FRotator PutdownPlayerTargetRotation = Owner.ActorForwardVector.Rotation();

		// Get alignment bone position at last frame
		FTransform PutdownTransform;
		const UAnimSequence PutdownSequence = PickupComponent.CurrentPickupDataAsset.PutDownAnimation;
		Animation::GetAnimAlignBoneTransform(PutdownTransform, PutdownSequence, PutdownSequence.SequenceLength);

		// Fill rotation-collision trace params
		FHazeTraceParams PutDownTrace;
		PutDownTrace.InitWithMovementComponent(CurrentPickup.MovementComponent);
		PutDownTrace.IgnoreActor(Owner);
		PutDownTrace.IgnoreActor(CurrentPickup);

		// Now create trace for ledge testing
		FHazeTraceParams LedgeTrace;
		LedgeTrace.InitWithMovementComponent(CurrentPickup.MovementComponent);
		LedgeTrace.SetToLineTrace();
		LedgeTrace.IgnoreActor(PlayerOwner);
		LedgeTrace.IgnoreActor(PlayerOwner.OtherPlayer);
		LedgeTrace.IgnoreActor(CurrentPickup);

		// Stores location for putdown capability to consume (nom nom)
		FVector PutdownLocation;

		float DeltaYaw = 40.f;
		float CurrentYaw = 0.f;

		// Big pickup actors will sometimes yield false level collisions
		float ZBias = 0.6f; 

		// Test and rotate until we stop overlapping
		bool bActorIsOverlapping = true;
		while(CurrentYaw < 360.f)
		{
			FVector RotationVector = PutdownPlayerTargetRotation.RotateVector(PutdownTransform.Translation + CurrentPickup.GetPutdownPlayerDistanceOffset());

			PutDownTrace.From = CurrentPickup.GetActorLocation() + PickupableZExtents;
			PutDownTrace.To = Owner.GetActorLocation() + RotationVector + PickupableZExtents + MovementComponent.WorldUp * ZBias;

			// Some animations don't zero out pitch, fix that and just use code target rotation for now
			// PutDownTrace.ShapeRotation = (PutdownTransform.Rotator() + PutdownPlayerTargetRotation).Quaternion();
			PutDownTrace.ShapeRotation = PutdownPlayerTargetRotation.Quaternion();

			FHazeHitResult HitResult;
			bActorIsOverlapping = PutDownTrace.Trace(HitResult);

			// Test for ledge gaps -we don't want to throw something down the abyss
			if(!bActorIsOverlapping)
			{
				LedgeTrace.From = PutDownTrace.To - PickupableZExtents * 2.f + MovementComponent.WorldUp * 10.f;
				LedgeTrace.To = LedgeTrace.From - MovementComponent.WorldUp * 20.f;

				LedgeTrace.Trace(HitResult);

				// It's safe to putdown if we found floor
				if(HitResult.bBlockingHit)
				{
					PutdownLocation = HitResult.ImpactPoint;
					bPutdownIsValid = true;
					break;
				}
			}

			// Rotate forward vector dz degrees
			ActorForwardVector = ActorForwardVector.RotateAngleAxis(DeltaYaw, FVector::UpVector);
			PutdownPlayerTargetRotation = ActorForwardVector.Rotation();
			CurrentYaw += DeltaYaw;
		}

		if(bPutdownIsValid)
		{
			PutdownParams.PutdownType = EPutdownType::Ground;
			PutdownParams.PlayerTargetPutdownRotation = PutdownPlayerTargetRotation;
			PutdownParams.PutdownLocation = PutdownLocation;
		}
	}

	void CalculateInPlacePlayerPutdownRotation(const APickupActor& CurrentPickup, FPutdownParams& PutdownParams)
	{
		bool bPutdownIsValid = false;

		FRotator PutdownPlayerTargetRotation;

		FVector ActorForwardVector = Owner.GetActorForwardVector();
		PutdownPlayerTargetRotation = ActorForwardVector.Rotation();

		FHazeLocomotionTransform LocomotionRootDelta;
		PickupComponent.CurrentPickupDataAsset.PutDownInPlaceAnimation.ExtractTotalRootMotion(LocomotionRootDelta);

		// Ignore current pickupable
		FHazeTraceParams PutDownTrace;
		PutDownTrace.InitWithMovementComponent(MovementComponent);
		PutDownTrace.IgnoreActor(PickupComponent.CurrentPickup);
		PutDownTrace.From = Owner.ActorLocation;

		// Create trace structure for ledge testing
		FHazeTraceParams LedgeTrace;
		LedgeTrace.InitWithMovementComponent(PlayerOwner.MovementComponent);
		LedgeTrace.SetToLineTrace();
		LedgeTrace.IgnoreActor(PlayerOwner);
		LedgeTrace.IgnoreActor(PlayerOwner.OtherPlayer);
		LedgeTrace.IgnoreActor(CurrentPickup);

		// LedgeTrace.DebugDrawTime = 3.f;

		float DeltaYaw = 30.f;
		float CurrentYaw = 0.f;

		FHazeHitResult HitResult;

		// Test and rotate until we stop overlapping
		bool bActorIsOverlapping = true;
		while(CurrentYaw < 360)
		{
			PutDownTrace.To = Owner.GetActorLocation() + PutdownPlayerTargetRotation.RotateVector(LocomotionRootDelta.DeltaTranslation);
			bActorIsOverlapping = PutDownTrace.Trace(HitResult);

			// Check if player would overlap with something when stepping backward
			if(!bActorIsOverlapping)
			{
				// Test also for player not being grounded after putdown
				LedgeTrace.From = PutDownTrace.To - PlayerOwner.MovementWorldUp * PlayerOwner.MovementComponent.CollisionShape.CapsuleHalfHeight;
				LedgeTrace.To = LedgeTrace.From - PlayerOwner.MovementWorldUp * 10.f;

				LedgeTrace.Trace(HitResult);
				if(HitResult.bBlockingHit)
				{
					bPutdownIsValid = true;
					break;
				}
			}

			// Rotate forward vector dz degrees
			ActorForwardVector = ActorForwardVector.RotateAngleAxis(DeltaYaw, FVector::UpVector);
			PutdownPlayerTargetRotation = ActorForwardVector.Rotation();
			CurrentYaw += DeltaYaw;
		}

		if(bPutdownIsValid)
		{
			PutdownParams.PutdownType = EPutdownType::GroundInPlace;
			PutdownParams.PlayerTargetPutdownRotation = PutdownPlayerTargetRotation;
		}
	}

	void PackSyncPutdownParams(const FPutdownParams& PutdownParams, FCapabilityActivationSyncParams& SyncParams) const
	{
		SyncParams.AddNumber(n"PutdownType", PutdownParams.PutdownType);
		SyncParams.AddVector(n"PlayerTargetPutdownRotation", PutdownParams.PlayerTargetPutdownRotation.Vector());
		SyncParams.AddVector(n"PutdownLocation", PutdownParams.PutdownLocation);

		SyncParams.AddStruct(n"OverrideParams", PutdownParams.OverrideParams);
	}

	void UnpackSyncPutdownParams(FPutdownParams& PutdownParams, const FCapabilityActivationParams& SyncParams)
	{
		PutdownParams.PutdownType = EPutdownType(SyncParams.GetNumber(n"PutdownType"));
		PutdownParams.PlayerTargetPutdownRotation = SyncParams.GetVector(n"PlayerTargetPutdownRotation").Rotation();
		PutdownParams.PutdownLocation = SyncParams.GetVector(n"PutdownLocation");

		SyncParams.GetStruct(n"OverrideParams", PutdownParams.OverrideParams);
	}

	bool ShouldShowPutdownPrompt() const
	{
		if(!PickupComponent.CurrentPickup.bPlayerIsAllowedToPutDown)
			return false;

		if(!PickupComponent.CanPutDown())
			return false;

		if(!MovementComponent.IsGrounded())
			return false;

		return true;
	}

	// Fired by PlayerPickupComponent whenever player is instructed to force drop
	UFUNCTION(NotBlueprintCallable)
	void OnForceDropRequested(FForceDropParams InForceDropParams)
	{
		bForceDropped = true;
		ForceDropParams = InForceDropParams;
	}
}