import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.AnimNotifies.AnimNotify_PickupRotationStart;
import Peanuts.Outlines.Outlines;
import Vino.Pickups.PickupTags;
import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PickupActor;
import Vino.Movement.MovementSystemTags;
import Vino.PlayerHealth.PlayerRespawnComponent;

class UForcedPickupParams : UObject
{
	FName AttachBoneOverride = NAME_None;

	uint RequestFrame = 0;

	bool bPlayPickupAnimation = false;
	bool bAddPickupLocomotion = false;

	bool IsFresh()
	{
		return RequestFrame == Time::FrameNumber;
	}
}

// Called by PickupActor::CanPlayerPickup()
bool PlayerCanPickUp(AHazePlayerCharacter PlayerCharacter)
{
	if(PlayerCharacter.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
		return false;

	UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
	if(!PlayerPickupComponent.bPlayerCanPickUp)
		return false;

	return !PlayerPickupComponent.IsHoldingObject() && !PlayerPickupComponent.bPlayerIsStandingInPutdownVolume;
}

// Called by PickupActor on BeginPlay
void SetupPickupInteractionCallback(AHazePlayerCharacter PlayerCharacter, FOnInteractionComponentActivated& OnInteractionComponentActivated)
{
	UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
	OnInteractionComponentActivated.AddUFunction(PlayerPickupComponent, n"OnPickUpIntent");
}

class UPlayerPickupComponent : UActorComponent 
{
	UPROPERTY()
	UHazeCapabilitySheet PickupCapabilitySheet = Asset("/Game/Blueprints/Pickups/CapabilitySheets/PlayerPickups_Sheet.PlayerPickups_Sheet");

	UPROPERTY(Category = "Player Death Hax")
	const UMaterialInterface DisintegrablePlayerMaterial = Asset("/Game/MasterMaterials/Char_Player.Char_Player");


	UPROPERTY()
	FPickupAction OnPickedUpEvent;

	UPROPERTY()
	FPickupAction OnPutDownEvent;
 
	UPROPERTY()
	FPickupAction OnThrownEvent;

	UPROPERTY()
	FPlayerPickupIntent OnPlayerWantsToPickUpActorEvent;

	bool bPlayerCanPickUp = true;
	bool bPlayerCanPutDown = true;

	FPlayerWantsToPutdown OnPlayerWantsToPutdownActorEvent;
	FForceDropRequested OnForceDropRequestedEvent;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;
	UHazeTriggerUserComponent TriggerUserComponent;
	UPlayerRespawnComponent PlayerRespawnComponent;

	// Actor that is currently selected to be picked up.
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APickupActor CurrentPickup;

	UPickupDataAsset CurrentPickupDataAsset;

	// Set by APlayerPutdownTrigger
	bool bPlayerIsStandingInPutdownVolume;

	private bool bIsHoldingObject;
	private bool bIsHoldingThrowableObject;

	// Audio stuff, set by ForceDrop()
	private bool bShouldSkipPlayingPutdownSound;

	UForcedPickupParams ForcedPickupParams = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwner());
		MovementComponent = UHazeMovementComponent::Get(Owner);
		TriggerUserComponent = UHazeTriggerUserComponent::Get(Owner);
		PlayerRespawnComponent = UPlayerRespawnComponent::Get(Owner);

		// Setup player dissolve death delegate
		UPlayerRespawnComponent::Get(PlayerOwner).OnPlayerDissolveStarted.BindUFunction(this, n"OnPlayerDissolveStarted");

		// Add pickup capabilities
		PlayerOwner.AddCapabilitySheet(PickupCapabilitySheet, EHazeCapabilitySheetPriority::Interaction, PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		// Release pickup actor on reset
		if(CurrentPickup != nullptr && (bIsHoldingThrowableObject || bIsHoldingObject))
		{
			APickupActor Pickup = CurrentPickup;
			LetGo(FPickupAction(), FPickupAction());
			Pickup.Reset(PlayerOwner);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickUpIntent(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		// Important because both players are bound to the same callback
		if(PlayerOwner != PlayerCharacter)
			return;

		// Fill-in pickup params struct
		FPickupParams PickupParams;
		PickupParams.PickupActor = Cast<APickupActor>(InteractionComponent.Owner);
		if(ForcedPickupParams != nullptr && ForcedPickupParams.IsFresh())
		{
			PickupParams.bPlayPickupAnimation = ForcedPickupParams.bPlayPickupAnimation;
			PickupParams.bAddPickupLocomotion = ForcedPickupParams.bAddPickupLocomotion;
			PickupParams.AttachBone = ForcedPickupParams.AttachBoneOverride;
		}

		// Delete object
		ForcedPickupParams = nullptr;

		if(PickupParams.AttachBone == NAME_None)
			PickupParams.AttachBone = PickupParams.PickupActor.AttachmentBoneName;

		// Fire Pickup intent event, PickupCapability listens to it
		OnPlayerWantsToPickUpActorEvent.Broadcast(PlayerCharacter, PickupParams);
	}

	// Called by player PickupCapability
	void PrepareForPickup(APickupActor PickupActor)
	{
		// Set current pickup actor
		CurrentPickup = PickupActor;

		// Set current pickup data asset
		CurrentPickupDataAsset = CurrentPickup.GetPlayerPickupDataAsset(PlayerOwner);
	}

	void PickUp(APickupActor PickupActor, FName AttachmentBone, bool bApplyLocomotionAsset = true)
	{
		ensure(PickupActor != nullptr);
		if(CurrentPickup != PickupActor)
			CurrentPickup = PickupActor;

		// Detach, in case pickup actor is attached to somethin'
		CurrentPickup.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		// Attach object to player, but keep world rotation
		CurrentPickup.RootComponent.AttachToComponent(PlayerOwner.Mesh, AttachmentBone, EAttachmentRule::KeepWorld);
		CurrentPickup.SetActorLocation(PlayerOwner.Mesh.GetSocketLocation(AttachmentBone));

		if(bApplyLocomotionAsset)
			PlayerOwner.AddLocomotionAsset(CurrentPickupDataAsset.CarryLocomotion, this);

		bIsHoldingObject = true;
		bIsHoldingThrowableObject = CurrentPickup.bCanBeThrown;

		if(CurrentPickupDataAsset.MovementSettings != nullptr)
			PlayerOwner.ApplySettings(CurrentPickupDataAsset.MovementSettings, CurrentPickup);

		// Add outline to pickup mesh
		AddMeshToPlayerOutline(CurrentPickup.Mesh, PlayerOwner, this);

		// Add carry capability sheet (used for blocking other capabilities and shiet)
		PlayerOwner.AddCapabilitySheet(CurrentPickup.CarryCapabilitySheet, EHazeCapabilitySheetPriority::Interaction, CurrentPickup);

		// Fire event
		OnPickedUpEvent.Broadcast(PlayerOwner, CurrentPickup);
		CurrentPickup.OnPickedUpEvent.Broadcast(PlayerOwner, CurrentPickup);

		// Only trigger components with this tag will be able to activate while player is holding somethin
		TriggerUserComponent.SetTriggerRequiredTag(n"Pickup");
	}

	// Called by putdown capability
	void PutDown()
	{
		UMeshComponent MeshComp = UMeshComponent::Get(CurrentPickup);
		if(MeshComp == nullptr)
		{
			Warning(Owner.Name + " wants to put down actor " + CurrentPickup.Name + " without even holding it!");
			return;
		}

		LetGo(OnPutDownEvent, CurrentPickup.OnPutDownEvent);
	}

	// Called by throw capability
	void ThrowRelease()
	{
		if(CurrentPickup == nullptr)
		{
			Warning("PickupComponent::OnThrown() - " + PlayerOwner.GetName() + " trying to throw null object!");
			return;
		}

		// Remove pickup carry capability sheet
		PlayerOwner.RemoveCapabilitySheet(CurrentPickup.CarryCapabilitySheet, CurrentPickup);

		// Cleanup
		LetGo(OnThrownEvent, CurrentPickup.OnThrownEvent);
	}

	void LetGo(FPickupAction& LetGoEvent, FPickupAction& PickupActorLetGoEvent)
	{
		// Stahp using pickup locomotion asset
		PlayerOwner.ClearLocomotionAssetByInstigator(this);

		// Remove movement settings
		PlayerOwner.ClearSettingsByInstigator(CurrentPickup);

		// Remove outline from pickup mesh
		RemoveMeshFromPlayerOutline(CurrentPickup.Mesh, this);

		// Dettach pickupable
		CurrentPickup.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		// Fire let go event
		LetGoEvent.Broadcast(PlayerOwner, CurrentPickup);
		PickupActorLetGoEvent.Broadcast(PlayerOwner, CurrentPickup);

		// Clean trigger user component's tag
		TriggerUserComponent.SetTriggerRequiredTag(NAME_None);

		// Cleanup
		CurrentPickup = nullptr;
		bIsHoldingObject = false;
		bIsHoldingThrowableObject = false;
	}

	// If bPlayPickupAnimation is true, pickup locomotion will be used regardless of bUsePickupLocomotion's value
	UFUNCTION()
	void ForcePickUp(APickupActor PickupActor, bool bPlayPickUpAnimation = true,  bool bAddPickupLocomotion = true, FName AttachOverride = NAME_None)
	{
		if(IsHoldingObject())
		{
			Warning("PickupActor::ForcePlayerToPickup() - " + PlayerOwner.Name + " is already holding pickup actor " + CurrentPickup.Name);
			return;
		}

		if(PickupActor == nullptr)
		{
			Warning("PickupActor::ForcePlayerToPickup() - PickupActor must be a valid object");
			return;
		}

		if(PickupActor.IsPickedUp())
			return;

		// Create forced pickup params object
		ForcedPickupParams = Cast<UForcedPickupParams>(NewObject(this, UForcedPickupParams::StaticClass(), n"ForcePickupParams", true));
		ForcedPickupParams.bPlayPickupAnimation = bPlayPickUpAnimation;
		ForcedPickupParams.bAddPickupLocomotion = bAddPickupLocomotion;
		ForcedPickupParams.AttachBoneOverride = AttachOverride;
		ForcedPickupParams.RequestFrame = Time::FrameNumber;

		// Poke pickup actor's interaction component to activate
		// PickupActor.InteractionComponent.StartActivating(PlayerOwner);

		// Do what the pickup's interaction component normally would do
		PickupActor.OnPlayerWantsToPickUp(PickupActor.InteractionComponent, PlayerOwner);
		OnPickUpIntent(PickupActor.InteractionComponent, PlayerOwner);
	}

	// Crumbed putdown. Cancels pickup; character will drop object immediately (no animation) if bPlayPutdownAnimation is set
	UFUNCTION(Category = "Pickup")
	void ForceDrop(bool bPlayPutdownAnimation, bool bShouldPlayPutdownSound = true)
	{
		if(!HasControl())
			return;

		// Bail if is already force dropping or if player is not holding anythin'
		if(!IsHoldingObject())
			return;

		// Store play putdown sound value
		bShouldSkipPlayingPutdownSound = !bShouldPlayPutdownSound;

		// PutdownStarterCapability will take care of the rest
		OnForceDropRequestedEvent.Broadcast(FForceDropParams(bPlayPutdownAnimation));
	}

	// Crumbed putdown. Plays animation and puts down pickupable at location *not compatible with PutdownInPlace*
	UFUNCTION(Category = "Pickup")
	void ForceDropAtLocation(FVector WorldLocation, bool bMovePlayerNextToLocation, bool bShouldPlayPutdownSound = true)
	{
		if(!HasControl())
			return;

		// Bail if is already force dropping or if player is not holding anythin'
		if(!IsHoldingObject())
			return;

		// Store play putdown sound value
		bShouldSkipPlayingPutdownSound = !bShouldPlayPutdownSound;

		// PutdownStarterCapability will take care of the rest
		OnForceDropRequestedEvent.Broadcast(FForceDropParams(WorldLocation, bMovePlayerNextToLocation, true));
	}

	// Crumbed putdown. Like ForceDropAtLocation but overrides pickup yaw axis (forward vector) *not compatible with PutdownInPlace*
	UFUNCTION(Category = "Pickup")
	void ForceDropAtLocationWithRotation(FVector WorldLocation, FRotator WorldRotation, bool bMovePlayerNextToLocation, bool bShouldPlayPutdownSound = true)
	{
		if(!HasControl())
			return;

		// Bail if is already force dropping or if player is not holding anythin'
		if(!IsHoldingObject())
			return;

		// Store play putdown sound value
		bShouldSkipPlayingPutdownSound = !bShouldPlayPutdownSound;

		// PutdownStarterCapability will take care of the rest
		OnForceDropRequestedEvent.Broadcast(FForceDropParams(WorldLocation, WorldRotation, bMovePlayerNextToLocation, true));
	}

	// Use when the call to this is networked and we don't want player to do a normal put down (i.e. drop (and teleport pickup away) off camera)
	UFUNCTION(Category = "Pickup")
	void ForceDropInstant_Local_NoAnim()
	{
		// Bail if is already force dropping or if player is not holding anythin'
		if(!IsHoldingObject())
			return;

		// Remove pickup capability sheet and drop that shiet
		PlayerOwner.RemoveCapabilitySheet(CurrentPickup.CarryCapabilitySheet, CurrentPickup);
		PutDown();
	}

	bool CanPutDown()
	{
		if(!IsHoldingObject())
			return false;

		if(!bPlayerCanPutDown)
			return false;

		if(IsPuttingDownObject())
			return false;

		if(CurrentPickup == nullptr)
			return false;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Sprint))
			return false;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return false;

		// Don't put shit down in anti-gravity situationer
		if(!PlayerOwner.MovementWorldUp.IsNear(FVector::UpVector, 0.01f))
			return false;

		if(PlayerRespawnComponent.bIsRespawning)
			return false;

		// Don't force putdown while player is still picking up
		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupCapability))
			return false;

		return true;
	}

	UFUNCTION()
	void SetAllowPickUp(bool bValue)
	{
		bPlayerCanPickUp = bValue;
	}

	UFUNCTION()
	bool GetAllowPickUp() const
	{
		return bPlayerCanPickUp;
	}

	UFUNCTION()
	void SetAllowPutDown(bool bValue)
	{
		bPlayerCanPutDown = bValue;
	}

	UFUNCTION()
	bool GetAllowPutDown() const
	{
		return bPlayerCanPutDown;
	}

	UFUNCTION()
	bool IsHoldingObject() const
	{
		return bIsHoldingObject;
	}

	UFUNCTION()
	bool IsHoldingThrowableObject() const
	{
		return bIsHoldingThrowableObject;
	}

	UFUNCTION()
	bool IsPickingUpObject() const
	{
		return PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupCapability);
	}

	UFUNCTION()
	bool IsPuttingDownObject() const
	{
		return PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability);
	}

	EPickupType GetPickupType()
	{
		return CurrentPickupDataAsset.PickupType;
	}

	bool ConsumeShouldPlayPutdownSound()
	{
		bool bShouldPlayPutdownSound = !bShouldSkipPlayingPutdownSound;
		bShouldSkipPlayingPutdownSound = false;

		return bShouldPlayPutdownSound;
	}

	UFUNCTION()
	bool CurrentPickupIsOfType(UClass& PickupClass) const
	{
		if(CurrentPickup == nullptr)
			return false;

		if(!CurrentPickup.IsA(PickupClass))
			return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerDissolveStarted(AHazePlayerCharacter Player)
	{
		if(Player != PlayerOwner)
			return;

		if(CurrentPickup == nullptr)
			return;

		CurrentPickup.DissolvePickupWithPlayer(DisintegrablePlayerMaterial);
	}
}