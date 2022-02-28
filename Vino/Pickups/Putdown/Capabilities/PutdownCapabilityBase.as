import Vino.Pickups.PlayerPickupComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.AnimNotifies.AnimNotify_Pickup;
import Vino.Pickups.PickupTags;
import Vino.Pickups.PickupActor;

class UPutdownCapabilityBase : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PutdownCapability);

    default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 15;

	default CapabilityDebugCategory = PickupTags::PickupSystem;

    AHazePlayerCharacter PlayerOwner;
    UPlayerPickupComponent PickupComponent;
    UHazeMovementComponent MovementComponent;

    APickupActor PutdownActor;

	UMovementSettings ActiveMovementSettings;

	UAnimSequence PutdownSequence;
	FHazeAnimNotifyDelegate PutDownNotify;

	UHazeCapabilitySheet CarryCapabilitySheet;

	FPutdownParams ActivePutdownParams;

	FVector PlayerInitialLocation;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        PickupComponent = UPlayerPickupComponent::Get(Owner);
        MovementComponent = UHazeMovementComponent::Get(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);

		// Bind player wants to putdown event
		PickupComponent.OnPlayerWantsToPutdownActorEvent.AddUFunction(this, n"OnPlayerWantsToPutdown");
    }

	// Must be called by inherited class!
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PutdownActor = Cast<APickupActor>(PickupComponent.CurrentPickup);
		CarryCapabilitySheet = Cast<APickupActor>(PickupComponent.CurrentPickup).CarryCapabilitySheet;

		BlockCapabilitiesBeforePutdown();

		PlayerInitialLocation = PlayerOwner.ActorLocation;

		// Remove pickup capability sheet
		PlayerOwner.RemoveCapabilitySheet(CarryCapabilitySheet, PutdownActor);
	}

	// Must be called by inherited class!
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Clean putdown
		ActivePutdownParams.Reset();

		// Unblock capabilities and clear putdown actor
		UnblockCapabilitiesAfterPutdown();
		PutdownActor = nullptr;
	}

    void PlayPutdownAnimation()
    {
        FHazeAnimationDelegate OnBlendOut;
        OnBlendOut.BindUFunction(this, n"OnAnimationEnded");

        FHazePlaySlotAnimationParams PutdownAnimationParams;
        PutdownAnimationParams.Animation = PutdownSequence;

        PutDownNotify.BindUFunction(this, n"OnObjectPutDown");

        PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendOut, PutdownAnimationParams);
        PlayerOwner.BindOrExecuteOneShotAnimNotifyDelegate(PutdownSequence, UAnimNotify_Pickup::StaticClass(), PutDownNotify);
    }

    UFUNCTION()
    void OnObjectPutDown(AHazeActor HazeActor, UHazeSkeletalMeshComponentBase SkeletalMeshComponent, UAnimNotify AnimNotify) 
	{
		// Save reference to pickupable and let go
		APickupActor PickupActor = PickupComponent.CurrentPickup;
		PickupComponent.PutDown();

		// Control side will leave a delegate crumb
		if(!HasControl())
			return;

		// Set all data for pickup actor's ground putdown capability
		PickupActor.SetCapabilityActionState(PickupTags::PickupGroundPutdown, EHazeActionState::ActiveForOneFrame);
		PickupActor.SetCapabilityAttributeVector(PickupTags::PickupGroundPutdownLocation, GetLocationForPutdown(PickupActor));
		PickupActor.SetCapabilityAttributeObject(n"PreviousHoldingPlayer", PlayerOwner);

		if(ActivePutdownParams.OverrideParams.bUsePutdownRotation)
			PickupActor.SetCapabilityAttributeVector(PickupTags::PickupGroundPutdownRotationOverride, ActivePutdownParams.OverrideParams.PutdownRotation.Vector());
	}

	UFUNCTION(NotBlueprintCallable)
	void OnObjectPutdownCrumb(const FHazeDelegateCrumbData& CrumbData) { /* virtual */ }

    UFUNCTION(NotBlueprintCallable)
    void OnAnimationEnded() { /* virtual */ }

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerWantsToPutdown(FPutdownParams PutdownParams)
	{
		ActivePutdownParams = PutdownParams;
	}

	FVector GetLocationForPutdown(const APickupActor& PickupActor)
	{
		// Put down where player is standing
		if(PickupActor.bPutDownInPlace)
			return PlayerInitialLocation;

		UPrimitiveComponent CurrentGround;
		FVector LocationRelativeToGround;
		if(MovementComponent.GetCurrentMoveWithComponent(CurrentGround, LocationRelativeToGround))
		{
			// Rotate align bone and add offset
			FTransform PutdownTransform;
			Animation::GetAnimAlignBoneTransform(PutdownTransform, PutdownSequence, PutdownSequence.SequenceLength);
			return PlayerOwner.GetActorLocation() + PlayerOwner.GetActorRotation().RotateVector(PutdownTransform.Translation + PickupActor.GetPutdownPlayerDistanceOffset());
		}
		else
		{
			// Player's ground is not moving, use absolute location
			return ActivePutdownParams.PutdownLocation;
		}
	}

    void BlockCapabilitiesBeforePutdown()
    {
        PlayerOwner.BlockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.BlockCapabilities(PickupTags::PickupCapability, this);
        PlayerOwner.BlockCapabilities(PickupTags::PickupThrowCapability, this);

        PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
        PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
    }

    void UnblockCapabilitiesAfterPutdown()
    {
        PlayerOwner.UnblockCapabilities(PickupTags::PutdownStarterCapability, this);
        PlayerOwner.UnblockCapabilities(PickupTags::PickupCapability, this);
        PlayerOwner.UnblockCapabilities(PickupTags::PickupThrowCapability, this);

        PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
        PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
    }
}