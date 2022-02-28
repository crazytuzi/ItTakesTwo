import Vino.Pickups.PickupGlobals;
import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PickupTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Pickups.PickupDataAsset;
import Vino.Pickups.Throw.MoveProjectileAlongCurveComponent;
import Vino.Trajectory.TrajectoryDrawer;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Rice.Materials.MaterialStatics;

import bool PlayerCanPickUp(AHazePlayerCharacter) from "Vino.Pickups.PlayerPickupComponent";
import void SetupPickupInteractionCallback(AHazePlayerCharacter, FOnInteractionComponentActivated&) from "Vino.Pickups.PlayerPickupComponent";
import Vino.PlayerHealth.PlayerHealthComponent;

event void FPickupAction(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor);
event void FPlayerPickupIntent(AHazePlayerCharacter PlayerCharacter, FPickupParams PickupParams);

struct FPickupParams
{
	APickupActor PickupActor = nullptr;
	
	FName AttachBone = NAME_None;

	bool bPlayPickupAnimation = true;
	bool bAddPickupLocomotion = true;

	void Reset()
	{
		PickupActor = nullptr;

		AttachBone = NAME_None;

		bPlayPickupAnimation = true;
		bAddPickupLocomotion = true;
	}
}

struct FPickupMeshInfo
{
	UMeshComponent MeshComponent = nullptr;
	TArray<UMaterialInterface> OriginalMeshMaterials;

	FPickupMeshInfo(UMeshComponent Mesh)
	{
		MeshComponent = Mesh;
		OriginalMeshMaterials = Mesh.Materials;
	}

	void ReparentMaterials(const UMaterialInterface& DisintegrablePlayerMaterial)
	{
		MaterialStatics::ReparentMeshMaterialsToCharacterMaterial(MeshComponent, DisintegrablePlayerMaterial);
	}

	void RestoreMeshMaterials()
	{
		for(int i = 0; i < MeshComponent.Materials.Num(); i++)
			MeshComponent.SetMaterial(i, OriginalMeshMaterials[i]);
	}
}

enum EPickupMeshType
{
	Static,
	Skeletal
};

enum EPickupColliderType
{
	Box,
	Sphere,
	Capsule
};

UCLASS(hidecategories="Rendering Collision Replication Input")
class APickupActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	UPROPERTY(Category = "Mesh")
	EPickupMeshType PickupMeshType;

	UPROPERTY(Category = "Mesh", meta = (EditCondition = "PickupMeshType == EPickupMeshType::Static", EditConditionHides))
	UStaticMesh StaticPickupMesh;

	UPROPERTY(Category = "Mesh", meta = (EditCondition = "PickupMeshType == EPickupMeshType::Skeletal", EditConditionHides))
	USkeletalMesh SkeletalPickupMesh;

	UPROPERTY(Category = "Mesh")
	bool bCastShadow = true;

	UPROPERTY(Category = "Mesh", meta = (EditCondition = "bCastShadow", EditConditionHides))
	EShadowPriority MeshShadowPriority = EShadowPriority::GameplayElement;

	// The pickup mesh will be attached to this component
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PickupRoot;

	// Attached to pickup root on ConstructionScript
	UPROPERTY(NotEditable)
	UMeshComponent Mesh;


	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;


	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UShapeComponent CollisionShape;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComponent.UpdateSettings.OptimalCount = 2;


	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;
	default TrajectoryDrawer.TickingGroup = ETickingGroup::TG_LastDemotable;
	default TrajectoryDrawer.PrimaryComponentTick.bStartWithTickEnabled = false;


	UPROPERTY(Category = "PickupCollision")
	EPickupColliderType CollisionShapeType = EPickupColliderType::Box;

	UPROPERTY(DisplayName = "Local Offset Fix", Category = "PickupCollision")
	FVector ColliderLocalOffsetFix = FVector::ZeroVector;

	UPROPERTY(DisplayName = "Extents Fix", Category = "PickupCollision", meta=(EditCondition="CollisionShapeType == EPickupColliderType::Box", EditConditionHides))
	FVector ColliderExtentsFix = FVector::ZeroVector;

	UPROPERTY(DisplayName = "Radius Fix", Category = "PickupCollision", meta=(EditCondition="CollisionShapeType == EPickupColliderType::Sphere || CollisionShapeType == EPickupColliderType::Capsule", EditConditionHides))
	float ColliderRadiusFix = 0.f;

	UPROPERTY(DisplayName = "Height Fix", Category = "PickupCollision", meta=(EditCondition="CollisionShapeType == EPickupColliderType::Capsule", EditConditionHides))
	float ColliderHeightFix = 0.f;


	// Pickup data asset (contains information like locomotion, blend space stuff and such)
	UPROPERTY(DisplayName = "Cody Pickup Data Asset")
	UPickupDataAsset PickupCodyDataAsset = Asset("/Game/Blueprints/Pickups/CharacterDataAssets/DA_PickupSmall_Cody.DA_PickupSmall_Cody");

	// Pickup data asset (contains information like locomotion, blend space stuff and such)
	UPROPERTY(DisplayName = "May Pickup Data Asset")
	UPickupDataAsset PickupMayDataAsset = Asset("/Game/Blueprints/Pickups/CharacterDataAssets/DA_PickupSmall_May.DA_PickupSmall_May");


	UPROPERTY()
	bool bCanBePickedUpWhenStandingOn = false;

	UPROPERTY(Category = "CharacterExclusivity")
    bool bCodyCanPickUp = true;

    UPROPERTY(Category = "CharacterExclusivity")
    bool bMayCanPickUp = true;


	// Carry stuff //////////////////////////////////////
	// If left blank, the default capability sheet for big pickups will be used
	UPROPERTY(Category = "Carry")
	UHazeCapabilitySheet CarryCapabilitySheet = Asset("/Game/Blueprints/Pickups/CapabilitySheets/PickupBig_Carry_BlockingSheet.PickupBig_Carry_BlockingSheet");

	// Pickupable will be attached to this joint/bone
	const FName AttachmentBoneName = n"Align";

	// Carry offset
	UPROPERTY(Category = "Carry", DisplayName = "Cody Carry Local Offset")
	FTransform PickupOffsetCody = FTransform::Identity;

	// Carry offset
	UPROPERTY(Category = "Carry", DisplayName = "May Carry Local Offset")
	FTransform PickupOffsetMay = FTransform::Identity;


	// Putdown stuff //////////////////////////////////
	// Whether player can manually putdown the actor
	UPROPERTY(Category = "Putdown")
	bool bPlayerIsAllowedToPutDown = true;

	UPROPERTY(Category = "Putdown")
	bool bShouldAttachToFloor = true;

	// Should player putdown the object where he's standing and step backwards
	UPROPERTY(Category = "Putdown")
	bool bPutDownInPlace = false;

	// Can be positive or negative; offset to distance from player to putdown location
	UPROPERTY(Category = "Putdown", meta = (EditCondition = "!bPutDownInPlace"))
	float PutdownDistanceOffset = 0.f;


	// Throw stuff //////////////////////////////////
	UPROPERTY(Category = "Throwing")
	bool bCanBeThrown = false;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	EPickupThrowType ThrowType = EPickupThrowType::Controlled;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	bool bStartAimingWhenPickedUp = false;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	bool bDrawAimTrajectory = true;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	bool bHoldToChargeThrow = true;

	UPROPERTY(Category = "Throwing", DisplayName = "Instant Throw Force", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	float BaseThrowForce = 1600.f;

	UPROPERTY(Category = "Throwing", DisplayName = "Max Charged Throw Force", meta = (EditCondition = "bCanBeThrown && bHoldToChargeThrow", EditConditionHides))
	float MaxChargedThrowForce = 4000.f;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown && bHoldToChargeThrow", EditConditionHides))
	float ChargeDuration = 1.2f;

	UPROPERTY(Category = "Throwing", meta = (EditCondition = "bCanBeThrown", EditConditionHides))
	UHazeCameraSpringArmSettingsDataAsset AimCameraSpringArmSettings = Asset("/Game/Blueprints/Pickups/Camera/AimingCameraSettings/DA_CameraSpringArmSettings_PickupAim.DA_CameraSpringArmSettings_PickupAim");


	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PickUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PutDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlacedOnFloorAudioEvent;


	// Actor blueprint events /////////////////////////////////
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnPickedUp(AHazePlayerCharacter Player) { }

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnPutDown(AHazePlayerCharacter Player) { }

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnThrown(AHazePlayerCharacter Player) { }

	UFUNCTION(BlueprintEvent)
	void OnCollisionAfterThrow(FVector Force, FHitResult HitResult) {  }


	// Actor code events /////////////////////////////////////
	UPROPERTY()
	FPickupAction OnPickedUpEvent;

	UPROPERTY()
	FPickupAction OnPutDownEvent;
 
	UPROPERTY()
	FPickupAction OnThrownEvent;

	UPROPERTY()
	FPickupAction OnPlacedOnFloorEvent;

	UPROPERTY()
	FPickupThrowCollisionEvent OnCollisionAfterThrowEvent;

	UPROPERTY()
	FPickupActionNoParams OnStoppedMovingAfterThrowEvent;


	// Used to revert materials after player respawn
	TArray<FPickupMeshInfo> MeshInfoList;


	UPickupThrowParams ThrowParams;

	private bool bIsPickedUp = false;
	float MeshMass;

	// Used by the pickup's offset and rotation lerper capabilities
	FPickupRotationLerp OnPickupRotationLerpRequestedEvent;
	FPickupOffsetLerp OnPickupOffsetLerpRequestedEvent;

	// Original fallback data
	FName OriginalCollisionProfile;
	FQuat OriginalPickupRootRelativeRotation;
	bool bOriginalSimulatePhysicsFlag;

	AActor OriginalAttachActor;
	FTransform OriginalWorldTransform;
	FTransform OriginalRelativeTransform;

	FVector PickupExtents;
	float PickupRadius;

    // Holds reference to 'the hand that rocks the cradle' when object is held
    AHazePlayerCharacter HoldingPlayer = nullptr;

	// Player will move to pickup actor's location before picking up (instead of using align bone to prepare for pickup)
	bool bShouldPlayerStandAtActorLocationAfterPickup = false;	// Maybe upropertize?

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(PickupMeshType == EPickupMeshType::Static)
		{
			UStaticMeshComponent StaticMeshComponent = UStaticMeshComponent::GetOrCreate(this, n"PickupStaticMesh");
			StaticMeshComponent.SetStaticMesh(StaticPickupMesh);
			Mesh = StaticMeshComponent;
		}
		else
		{
			UHazeSkeletalMeshComponentBase SkeletalMeshComponent = UHazeSkeletalMeshComponentBase::GetOrCreate(this, n"PickupSkeletalMesh");
			SkeletalMeshComponent.SetSkeletalMesh(SkeletalPickupMesh);
			Mesh = SkeletalMeshComponent;
		}

		Mesh.SetEnableGravity(false);
		Mesh.AttachToComponent(PickupRoot);
		Mesh.SetRelativeScale3D(FVector::OneVector);

		CreateCollisionShape();

		Mesh.SetCullDistance(Editor::GetDefaultCullingDistance(Mesh) * CullDistanceMultiplier);

		// Mesh lighting stuff
		Mesh.SetCastShadow(bCastShadow);
		Mesh.ShadowPriority = MeshShadowPriority;
	}

	void CreateCollisionShape()
	{
		FVector Origin;
		System::GetComponentBounds(Mesh, Origin, PickupExtents, PickupRadius);
		PickupExtents += ColliderExtentsFix;
		PickupRadius += ColliderRadiusFix;
		float PickupHeight = PickupExtents.Z + ColliderHeightFix;

		PickupExtents /= PickupRoot.WorldScale;
		PickupRadius /= PickupRoot.WorldScale.Size();

		switch(CollisionShapeType)
		{
			case EPickupColliderType::Box:
				CollisionShape = UBoxComponent::GetOrCreate(this, n"BoxCollider");
				Cast<UBoxComponent>(CollisionShape).SetBoxExtent(PickupExtents);
				break;

			case EPickupColliderType::Sphere:
				CollisionShape = USphereComponent::GetOrCreate(this, n"SphereCollider");
				Cast<USphereComponent>(CollisionShape).SetSphereRadius(PickupRadius);

				break;

			case EPickupColliderType::Capsule:
				CollisionShape = UCapsuleComponent::GetOrCreate(this, n"CapsuleCollider");
				Cast<UCapsuleComponent>(CollisionShape).SetCapsuleSize(PickupRadius, PickupHeight);
				break;
		}

		CollisionShape.AttachToComponent(Mesh);
		CollisionShape.SetRelativeScale3D(FVector::OneVector);
		CollisionShape.SetRelativeLocation(ColliderLocalOffsetFix + FVector::UpVector * PickupExtents.Z);

		CollisionShape.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		CollisionShape.SetCollisionProfileName(n"IgnorePlayerCharacter");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!ensure(PickupCodyDataAsset != nullptr))
		{
			Warning("PickupDataAsset for Cody is NULL in " + Name + " pickup actor");
			return;
		}

		if(!ensure(PickupMayDataAsset != nullptr))
		{
			Warning("PickupDataAsset for May is NULL in " + Name + " pickup actor");
			return;
		}

		SetupInteractionComponent();

		// Ignore player when moving around
		for(AHazePlayerCharacter PlayerCharacter : Game::GetPlayers())
			Mesh.IgnoreActorWhenMoving(PlayerCharacter, true);

		// Bind placed on floor delegate
		OnPlacedOnFloorEvent.AddUFunction(this, n"OnPlacedOnFloor");

		// Setup delegate for handling bouncing
		OnCollisionAfterThrowEvent.AddUFunction(this, n"OnCollisionAfterThrowDelegate");

		FillOriginalParams();

		// Initialize movement component
		ChangeActorWorldUp(ActorUpVector);
		MovementComponent.Setup(CollisionShape);

		MovementComponent.StartIgnoringActor(Game::Cody);
		MovementComponent.StartIgnoringActor(Game::May);

		// Add pickup actor's capabilities
		AddCapability(n"PickupOffsetLerpCapability");
		AddCapability(n"PickupRotationLerpCapability");
		AddCapability(n"PickupFloorAttacherCapability");
		AddCapability(n"PickupGroundPutdownCapability");
		AddCapability(n"PickupThrowUnrealPhysicsCapability");
		AddCapability(n"PickupThrowControlledAirTravelCapability");

		// Save original mesh materials
		MeshInfoList.Empty();
		for(UActorComponent MeshComponent : GetComponentsByClass(UMeshComponent::StaticClass()))
			MeshInfoList.Add(FPickupMeshInfo(Cast<UMeshComponent>(MeshComponent)));
	}

	// Called by PlayerPickupComponent's OnResetComponent in case this guy is picked up
	void Reset(AHazePlayerCharacter PlayerCharacter)
	{
		CleanupAfterPutdown();
		HoldingPlayer = nullptr;

		if(OriginalAttachActor == nullptr)
		{
			SetActorTransform(OriginalWorldTransform);
		}
		else
		{
			AttachToActor(OriginalAttachActor);
			SetActorRelativeTransform(OriginalRelativeTransform);
		}

		ReEnableInteractionComponent(PlayerCharacter);
		RestoreMeshMaterials();
	}

	UFUNCTION(NotBlueprintCallable)
	protected bool CanPlayerPickUp(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		// Duh
		if(bIsPickedUp)
			return false;

		// Don't attempt to pickup if player is still doing something pickupy
		if(PlayerCharacter.IsAnyCapabilityActive(PickupTags::PickupSystem))
			return false;

		// Check with PlayerPickupComponent
		if(!PlayerCanPickUp(PlayerCharacter))
			return false;

		// Don't pickup if actor is still being lerped onto putdown transform
		if(IsAnyCapabilityActive(PickupTags::PickupSystem))
			return false;

		// Check character-specific flags
		if(!(PlayerCharacter.IsCody() ? bCodyCanPickUp : bMayCanPickUp))
			return false;

		// Can't pickup when airborne
		if(!UHazeMovementComponent::Get(PlayerCharacter).IsGrounded())
			return false;

		// Don't pickup if player is standing on actor and it is not allowed
		if(IsPlayerStandingOnMe(PlayerCharacter) && !bCanBePickedUpWhenStandingOn)
		 	return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerWantsToPickUp(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		// Switch control side to match player's
		SetControlSide(PlayerCharacter);

		// Disable interaction component for now
		// Interaction component needs to be re-enabled manually, if not thrown. PutdownCapabilityBase will do this when deactivated.
		InteractionComponent.Disable(n"ActorPickedUp");
	}

	// Called by player PickupCapability
	void PrepareForPickup(AHazePlayerCharacter PlayerCharacter)
	{
		// Setup delegates and fire pickup intent event; PickupCapability listens to such event
		SetPickupEventDelegates();

        // Turn off collisions with player to mitigate crazy clip physics
        Mesh.SetCollisionProfileName(n"IgnorePlayerCharacter");
        Mesh.SetSimulatePhysics(false);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		bIsPickedUp = true;
		HoldingPlayer = Player;

		// Could me set to player's up vector, but putdown rotation tests would need to be tweaked
		ChangeActorWorldUp(Player.MovementWorldUp);

		OnPickedUp(Player);

		Player.PlayerHazeAkComp.HazePostEvent(PickUpAudioEvent);

		AddTickPrerequisiteActor(Player);

		// Subscribe to respawn event
		UPlayerRespawnComponent::Get(Player).OnPlayerDissolveCompleted.AddUFunction(this, n"OnHoldingPlayerRespawn");

		// Upgrade shadow priority
		Mesh.HazeSetShadowPriority(EShadowPriority::Player);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		CleanupAfterPutdown();
		OnPutDown(Player);

		Player.PlayerHazeAkComp.HazePostEvent(PutDownAudioEvent);

		// Unbind respawn event
		UPlayerRespawnComponent::Get(Player).OnPlayerDissolveCompleted.Unbind(this, n"OnHoldingPlayerRespawn");

		HoldingPlayer = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnThrownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		CleanupAfterPutdown();

		// Re-enable interaction component
		ReEnableInteractionComponent(Player);

		OnThrown(Player);
		HoldingPlayer = nullptr;
	}

	// Will fire only when throw is EPickupThrowType::Controlled
	UFUNCTION(NotBlueprintCallable)
	protected void OnCollisionAfterThrowDelegate(FVector LastTracedVelocity, FHitResult HitResult)
	{
		// Relay to BP event
		OnCollisionAfterThrow(LastTracedVelocity, HitResult);
	}

	// Useful for getting things back to normal once object is put down
	private void FillOriginalParams()
	{
		FVector Origin;
		System::GetComponentBounds(Mesh, Origin, PickupExtents, PickupRadius);

		OriginalCollisionProfile = Mesh.GetCollisionProfileName();
		OriginalPickupRootRelativeRotation = PickupRoot.RelativeRotation.Quaternion();
		bOriginalSimulatePhysicsFlag = Mesh.IsSimulatingPhysics();

		// Eman TODO: Fix this gross mess!
		// Can't get mass if physics simulation is off
		// save attach parent just in case
		OriginalAttachActor = GetAttachParentActor();
		OriginalRelativeTransform = RootComponent.GetRelativeTransform();

		Mesh.SetSimulatePhysics(true);
		MeshMass = Mesh.GetMass();
		Mesh.SetSimulatePhysics(bOriginalSimulatePhysicsFlag);

		// pickup mesh' got dettached from parent because of physics poop... 
		// Restore attachment!
		if(OriginalAttachActor != nullptr)
		{
			AttachToActor(OriginalAttachActor, NAME_None, EAttachmentRule::KeepWorld);
			SetActorRelativeTransform(OriginalRelativeTransform);
		}

		// Restore mesh attachment
		Mesh.AttachToComponent(PickupRoot);

		// Save original transform info
		OriginalWorldTransform = ActorTransform;
	}

	private void SetupInteractionComponent()
	{
		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.Delegate.BindUFunction(this, n"CanPlayerPickUp");
		InteractionComponent.AddTriggerCondition(n"CanPlayerPickUp", TriggerCondition);

		// Bind activation delegates
		InteractionComponent.OnActivated.AddUFunction(this, n"OnPlayerWantsToPickUp");
		SetupPickupInteractionCallback(Game::GetCody(), InteractionComponent.OnActivated);
		SetupPickupInteractionCallback(Game::GetMay(), InteractionComponent.OnActivated);
	}

	private void SetPickupEventDelegates()
	{
		OnPickedUpEvent.AddUFunction(this, n"OnPickedUpDelegate");
		OnPutDownEvent.AddUFunction(this, n"OnPutDownDelegate");
		OnThrownEvent.AddUFunction(this, n"OnThrownDelegate");
	}

	private void ClearPickupEventDelegates()
	{
		OnPickedUpEvent.Unbind(this, n"OnPickedUpDelegate");
		OnPutDownEvent.Unbind(this, n"OnPutDownDelegate");
		OnThrownEvent.Unbind(this, n"OnThrownDelegate");
	}

	void SetMovementEnabled(bool bEnabled)
	{
		MovementComponent.SetActive(bEnabled);
		CollisionShape.SetActive(bEnabled);
	}

	// Will be nullptr if pickup is a static mesh
	UFUNCTION(BlueprintPure)
	UHazeSkeletalMeshComponentBase GetSkeletalPickupMeshComponent()
	{
		if(Mesh == nullptr)
			return nullptr;

		return Cast<UHazeSkeletalMeshComponentBase>(Mesh);
	}

	// Will be nullptr if pickup is a skeletal mesh
	UFUNCTION(BlueprintPure)
	UStaticMeshComponent GetStaticPickupMeshComponent()
	{
		if(Mesh == nullptr)
			return nullptr;

		return Cast<UStaticMeshComponent>(Mesh);
	}

	void SetPickupThrowParams(FVector ThrowVelocity, FVector Gravity, float Time, FPickupThrowCollisionEvent PickupThrowCollisionEvent)
	{
		ThrowParams = Cast<UPickupThrowParams>(NewObject(this, UPickupThrowParams::StaticClass()));
		ThrowParams.OnPickupThrowCollision = PickupThrowCollisionEvent;
		ThrowParams.ThrowVelocity = ThrowVelocity;
		ThrowParams.Gravity = Gravity;
		ThrowParams.Time = Time;
	}

	UFUNCTION()
	void StopPickupFlightAfterThrow()
	{
		// Handle legacy way
		UMoveProjectileAlongCurveComponent CurveMove = UMoveProjectileAlongCurveComponent::Get(this);
		if(CurveMove != nullptr)
			CurveMove.Abort();

		// Deactivate pickup's flight capability
		SetCapabilityActionState(PickupTags::AbortPickupFlight, EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	bool IsPickedUp()
	{
		return bIsPickedUp;
	}

	FVector GetPutdownPlayerDistanceOffset() const
	{
		return FVector(PutdownDistanceOffset, 0.f, 0.f);
	}

	FTransform GetPlayerPickupOffset(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ? PickupOffsetCody : PickupOffsetMay;
	}

	bool IsPlayerStandingOnMe(AHazePlayerCharacter PlayerCharacter)
	{
		UHazeMovementComponent PlayerMovementComponent = UHazeMovementComponent::Get(PlayerCharacter);
		return PlayerMovementComponent.GetDownHit().Actor == this;
	}
	
	void CleanupAfterPutdown()
	{
		bIsPickedUp = false;
		ClearPickupEventDelegates();

		// Restore shadow priority
		Mesh.HazeSetShadowPriority(MeshShadowPriority);
	}

	UPickupDataAsset GetPlayerPickupDataAsset(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ? PickupCodyDataAsset : PickupMayDataAsset;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlacedOnFloor(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		// Restore original collision profile
		// Eman TODO: Maybe test for actors overlapping before enabling?
		Mesh.SetCollisionProfileName(OriginalCollisionProfile);
        Mesh.SetSimulatePhysics(bOriginalSimulatePhysicsFlag);
		Mesh.SetPhysicsLinearVelocity(FVector::ZeroVector);
		Mesh.SetPhysicsAngularVelocityInDegrees(FVector::ZeroVector);

		ReEnableInteractionComponent(PlayerCharacter);

		RemoveTickPrerequisiteActor(PlayerCharacter);

		UHazeAkComponent::HazePostEventFireForget(PlacedOnFloorAudioEvent, PickupActor.GetActorTransform());
	}

	// If networked, wait for remote side to be done and enable
	protected void ReEnableInteractionComponent(AHazePlayerCharacter PlayerCharacter)
	{
		// Re-enable interaction component
		if(!Network::IsNetworked())
			InteractionComponent.Enable(n"ActorPickedUp");
		else if(!PlayerCharacter.HasControl())
			NetEnableInteractionComponent();
	}

	UFUNCTION(NetFunction)
	private void NetEnableInteractionComponent()
	{
		InteractionComponent.Enable(n"ActorPickedUp");
	}

	void ApplyPickupLocationOffset(FPickupOffsetLerpParams OffsetLerpParams)
	{
		OnPickupOffsetLerpRequestedEvent.Broadcast(OffsetLerpParams);
	}

	void LerpToRotation(FPickupRotationLerpParams RotationLerpParams)
	{
		OnPickupRotationLerpRequestedEvent.Broadcast(RotationLerpParams);
	}

	// Switch to disintegrable material (for player death reasons)
	void DissolvePickupWithPlayer(const UMaterialInterface& DisintegrablePlayerMaterial)
	{
		for(FPickupMeshInfo MeshInfo : MeshInfoList)
			MeshInfo.ReparentMaterials(DisintegrablePlayerMaterial);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHoldingPlayerRespawn(AHazePlayerCharacter Player)
	{
		// Don't restore materials if player started dying again while dissolve was still playing
		if(UPlayerRespawnComponent::Get(Player).bIsRespawning || UPlayerHealthComponent::Get(Player).bIsDead)
			return;

		RestoreMeshMaterials();
	}

	void RestoreMeshMaterials()
	{
		for(FPickupMeshInfo MeshInfo : MeshInfoList)
			MeshInfo.RestoreMeshMaterials();
	}
}