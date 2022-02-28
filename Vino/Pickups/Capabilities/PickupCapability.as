import Vino.Pickups.AnimNotifies.AnimNotify_Pickup;
import Vino.Pickups.PickupActor;
import Vino.Pickups.PickupTags;
import Vino.Pickups.PlayerPickupComponent;

class UPickupCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
    default CapabilityTags.Add(PickupTags::PickupCapability);

    default TickGroup = ECapabilityTickGroups::BeforeMovement;

    AHazePlayerCharacter PlayerOwner;

	UHazeMovementComponent MovementComponent;
    UPlayerPickupComponent PlayerPickupComponent;

	FPickupParams PickupParams;

	FHazeAnimNotifyDelegate PickedUpNotify;

	FQuat AlignRotation;
	float AlignRotationSpeed;

	bool bPickupAnimationEnded;
	bool bPlayerWantsToPickUpActor;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
        PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);

		// Bind pickup intent event
		PlayerPickupComponent.OnPlayerWantsToPickUpActorEvent.AddUFunction(this, n"OnPlayerWantsToPickUpActor");
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(PickupParams.PickupActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		// Sync pickup params in case crumbs come out of order
		SyncParams.AddStruct(n"PickupParams", PickupParams);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        BlockCapabilities();
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		ActivationParams.GetStruct(n"PickupParams", PickupParams);

		PickupParams.PickupActor.PrepareForPickup(PlayerOwner);
		PlayerPickupComponent.PrepareForPickup(PickupParams.PickupActor);

		if(PickupParams.bPlayPickupAnimation)
		{
        	PlayPickupAnimation();
		}
		else
		{
			OnObjectPickedUp(PlayerOwner, PlayerOwner.Mesh, nullptr);
			OnPickupRotationReadyToAlign(PlayerOwner, PlayerOwner.Mesh, nullptr);
			bPickupAnimationEnded = true;
		}

		// Player will rotate using these params
		FTransform IdealPlayerTransform = GetIdealPlayerTransformForPickUp();
		AlignRotation = IdealPlayerTransform.Rotation;
		AlignRotationSpeed = FMath::Sqrt(PlayerOwner.ActorRotation.GetManhattanDistance(IdealPlayerTransform.Rotator()) * 2.f);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MovementComponent.CanCalculateMovement())
			return;

		if(bPickupAnimationEnded)
			return;

		// Move with ground
		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(PickupTags::PickupCapability);
		MoveData.FlagToMoveWithDownImpact();
		MoveData.ApplyGravityAcceleration();

		// Move towards align location if player hasn't picked-up actor
		if(!PickupParams.PickupActor.IsPickedUp())
		{
			FVector PlayerToAlign = GetIdealPlayerTransformForPickUp().Location - PlayerOwner.ActorLocation;
			FVector MoveDelta = PlayerToAlign * DeltaTime * 10.f;
			MoveData.ApplyDelta(MoveDelta);
		}

		// Start rotating towards constrained aim vector if necessary-
		// this this capability will be active after player has picked up actor
		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupConstrainedAimCapability))
			AlignRotation = GetAttributeVector(PickupTags::PickupConstrainedAimStartForward).ToOrientationQuat();

		// Rotate towards pickup
		MovementComponent.SetTargetFacingRotation(AlignRotation, AlignRotationSpeed);
		MoveData.ApplyTargetRotationDelta();

		// Don't request shit for one frame to allow previous SM to transition
		if(ActiveDuration > 0.f)
		{
			FHazeRequestLocomotionData LocomotionRequest;
			LocomotionRequest.AnimationTag = n"Movement";
			PlayerOwner.RequestLocomotion(LocomotionRequest);
		}

		// Go go go!
		MovementComponent.Move(MoveData);
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        return bPickupAnimationEnded ? EHazeNetworkDeactivation::DeactivateUsingCrumb : EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		PlayerOwner.UnbindAnimNotifyDelegate(UAnimNotify_Pickup::StaticClass(), PickedUpNotify);
        UnblockCapabilities();

		// Cleanup
		PickupParams.Reset();
		AlignRotation = FQuat::Identity;
		AlignRotationSpeed = 0.f;
		bPickupAnimationEnded = false;
    }

	FTransform GetIdealPlayerTransformForPickUp()
	{
		FVector IdealLocation = FVector::ZeroVector;
		if(PickupParams.PickupActor.bShouldPlayerStandAtActorLocationAfterPickup)
		{
			IdealLocation = PickupParams.PickupActor.ActorLocation;
		}
		else
		{
			// Get ideal distance from player to pickup
			FTransform AlignBoneTransform;
			Animation::GetAnimAlignBoneTransform(AlignBoneTransform, PickupParams.PickupActor.GetPlayerPickupDataAsset(PlayerOwner).PickupAnimation);
			float IdealDistanceFromPickupable = AlignBoneTransform.GetTranslation().Size();

			// Get player location
			FVector PlayerToPickupable = (PickupParams.PickupActor.GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal();
			IdealLocation = PickupParams.PickupActor.GetActorLocation() - PlayerToPickupable * IdealDistanceFromPickupable;
		}

		// Get player rotation
		FRotator IdealRotation = (PickupParams.PickupActor.GetActorLocation() - PlayerOwner.GetActorLocation()).GetSafeNormal().ToOrientationRotator();

		// Return transform
		return FTransform(IdealRotation, IdealLocation);
	}

    void PlayPickupAnimation()
    {
        FHazeAnimationDelegate OnBlendOut;
		if(HasControl())
        	OnBlendOut.BindUFunction(this, n"OnPickupAnimationEnded");

        FHazePlaySlotAnimationParams PickupAnimationParams;
        PickupAnimationParams.Animation = PlayerPickupComponent.CurrentPickupDataAsset.PickupAnimation;

        PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendOut, PickupAnimationParams);
		if(HasControl())
		{
        	PickedUpNotify.BindUFunction(this, n"OnObjectPickedUp");
        	PlayerOwner.BindOrExecuteOneShotAnimNotifyDelegate(PlayerPickupComponent.CurrentPickupDataAsset.PickupAnimation, UAnimNotify_Pickup::StaticClass(), PickedUpNotify);
		}

		// We'll lerp to object's ideal carry rotation when notify fires
		PlayerOwner.BindOneShotAnimNotifyDelegate(UAnimNotify_PickupRotationStart::StaticClass(), FHazeAnimNotifyDelegate(this, n"OnPickupRotationReadyToAlign"));
    }

    UFUNCTION(NotBlueprintCallable)
    void OnObjectPickedUp(AHazeActor HazeActor, UHazeSkeletalMeshComponentBase SkeletalMeshComponent, UAnimNotify AnimNotify)
    {
		if(!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"PickupActor", PickupParams.PickupActor);
		if(PickupParams.bAddPickupLocomotion)
			CrumbParams.AddActionState(n"bAddPickupLocomotion");

		// Crumbify event to render pickup function a bit safer during intense lag
		UHazeCrumbComponent::Get(PlayerOwner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnObjectPickedUp"), CrumbParams);
    }

    UFUNCTION(NotBlueprintCallable)
	void Crumb_OnObjectPickedUp(FHazeDelegateCrumbData CrumbData)
	{
		APickupActor Pickup = Cast<APickupActor>(CrumbData.GetObject(n"PickupActor"));
        PlayerPickupComponent.PickUp(Pickup, PickupParams.AttachBone, CrumbData.GetActionState(n"bAddPickupLocomotion"));
	}

	// Lerps pickupable to align rotation; run during a 'start pickup rotation' notify
	UFUNCTION(NotBlueprintCallable)
	void OnPickupRotationReadyToAlign(AHazeActor HazeActor, UHazeSkeletalMeshComponentBase SkeletalMeshComponent, UAnimNotify AnimNotify)
	{
		if(!HasControl())
			return;

		// Actor reference can be null if for some reason there is a force drop request while player is still picking up
		if(PlayerPickupComponent.CurrentPickup == nullptr)
			return;

		// Crumbify event to render pickup function a bit safer during intense lag
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"PickupActor", PlayerPickupComponent.CurrentPickup);
		UHazeCrumbComponent::Get(PlayerOwner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnPickupRotationReadyToAlign"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnPickupRotationReadyToAlign(FHazeDelegateCrumbData CrumbData)
	{
		APickupActor Pickup = Cast<APickupActor>(CrumbData.GetObject(n"PickupActor"));

		// Start lerping current object rotation to align rotation and add rotation offset while we're at it
		Pickup.LerpToRotation(FPickupRotationLerpParams(FQuat::Identity + Pickup.GetPlayerPickupOffset(PlayerOwner).GetRotation(), 10.f, false));

		// Lerp location to align offset
		Pickup.ApplyPickupLocationOffset(FPickupOffsetLerpParams(PlayerOwner));
	}

    UFUNCTION(NotBlueprintCallable)
    void OnPickupAnimationEnded()
    {
		if(!IsActive())
			return;

        bPickupAnimationEnded = true;
    }

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerWantsToPickUpActor(AHazePlayerCharacter PlayerCharacter, FPickupParams ActivePickupParams)
	{
		PickupParams = ActivePickupParams;
		PlayerOwner.SetCapabilityActionState(n"HasPendingPickup", EHazeActionState::ActiveForOneFrame);
	}

    void BlockCapabilities()
    {
        PlayerOwner.BlockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.BlockCapabilities(PickupTags::PickupThrowCapability, this);

        PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
        PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
    }

    void UnblockCapabilities()
    {
        PlayerOwner.UnblockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.UnblockCapabilities(PickupTags::PickupThrowCapability, this);

        PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
        PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
    }
}