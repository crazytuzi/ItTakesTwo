import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimationDataComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Camera.Actors.KeepInViewCameraActor;
import Cake.LevelSpecific.PlayRoom.VOBanks.GoldbergVOBank;

event void FOnPlayerMountedSwing(AHazePlayerCharacter PlayerCharacter);
event void FOnPlayerReleasedSwing(AHazePlayerCharacter PlayerCharacter);
event void FOnBothPlayersEvent();
event void FOnMarbleEvent();
event void FOnMarbleShitThrowEvent(AHazePlayerCharacter PlayerCharacter, ATrapezeActor Trapeze);

class ATrapezeActor : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	ATrapezeActor OtherTrapeze;

	// Holds reference to marble in scene
	UPROPERTY()
	ATrapezeMarbleActor Marble;

	UPROPERTY(EditInstanceOnly)
	bool bIsCatchingEnd = false;

	UPROPERTY(meta = (MakeEditWidget))
	private FVector TargetDispenser = FVector(-1538.f, 20.f, -508.f);

	UPROPERTY(meta = (EditCondition = "bIsCatchingEnd"))
	AHazeActor KeepInViewActor;


	UPROPERTY(Category = "Camera")
	AKeepInViewCameraActor TrapezeCameraActor;

	UPROPERTY()
	AHazePlayerCharacter InteractingPlayer;

	UPROPERTY(Category = "Animation")
	FName CatchSocketName = n"RightAttach";

	UPROPERTY(Category = "Animation|Cody")
	UAnimSequence EnterSequenceCody;

	UPROPERTY(Category = "Animation|Cody")
	UAnimSequence EnterWithMarbleSequenceCody;

	UPROPERTY(Category = "Animation|Cody")
	UAnimSequence ExitSequenceCody;

	UPROPERTY(Category = "Animation|Cody")
	UAnimSequence ExitWithMarbleSequenceCody;

	UPROPERTY(Category = "Animation|Cody", DisplayName = "Locomotion SM")
	UHazeLocomotionStateMachineAsset LocomotionStateMachineAssetCody;

	UPROPERTY(Category = "Animation|May")
	UAnimSequence EnterSequenceMay;

	UPROPERTY(Category = "Animation|May")
	UAnimSequence EnterWithMarbleSequenceMay;

	UPROPERTY(Category = "Animation|May")
	UAnimSequence ExitSequenceMay;

	UPROPERTY(Category = "Animation|May")
	UAnimSequence ExitWithMarbleSequenceMay;

	UPROPERTY(Category = "Animation|May", DisplayName = "Locomotion SM")
	UHazeLocomotionStateMachineAsset LocomotionStateMachineAssetMay;


	UPROPERTY(Category = "MarbleThrow")
	float ThrowForce = 60000.f;

	UPROPERTY(Category = "MarbleThrow")
	float ThrowPitch = 50.f;


	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartSwingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopSwingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ForwardsDirectionEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BackwardsDirectionEvent;

	UPROPERTY(Category = "Audio")
	const float PanningValue = 0.f;


	UPROPERTY(Category = "Audio | Barks | Cody", DisplayName = "Catch Fail Event")
	FName CatchFailCodyVOEventName = n"FoghornDBPlayRoomCircusTrapezeFailedCatchMay";

	UPROPERTY(Category = "Audio | Barks | Cody", DisplayName = "Throw Fail Event")
	FName ThrowFailCodyVOEventName = n"FoghornDBPlayRoomCircusTrapezeFailMay";

	UPROPERTY(Category = "Audio | Barks | May", DisplayName = "Catch Fail Event")
	FName CatchFailMayVOEventName = n"FoghornDBPlayRoomCircusTrapezeFailedCatchCody";

	UPROPERTY(Category = "Audio | Barks | May", DisplayName = "Throw Fail Event")
	FName ThrowFailMayVOEventName = n"FoghornDBPlayRoomCircusTrapezeFailCody";


	UPROPERTY(EditDefaultsOnly)
	UGoldbergVOBank VOBank;


	UPROPERTY()
	UCurveFloat ResetLerpSpeedCurve;


	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopeBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPhysicsConstraintComponent PhysicsConstraintComponent;
	
	UPROPERTY(DefaultComponent, Attach = RopeBase)
	USceneComponent RopeBaseLeft;

	UPROPERTY(DefaultComponent, Attach = RopeBaseLeft)
	USplineComponent RopeLeft;

	UPROPERTY(DefaultComponent, Attach = RopeLeft)
	USplineMeshComponent RopeLeftMesh;

	UPROPERTY(DefaultComponent, Attach = RopeBase)
	USceneComponent RopeBaseRight;

	UPROPERTY(DefaultComponent, Attach = RopeBaseRight)
	USplineComponent RopeRight;

	UPROPERTY(DefaultComponent, Attach = RopeRight)
	USplineMeshComponent RopeRightMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SwingMesh;

	UPROPERTY(DefaultComponent, Attach = SwingMesh)
	USceneComponent PlayerPositionInSwing;

	UPROPERTY(DefaultComponent, Attach = SwingMesh)
	UInteractionComponent InteractionComponent;
	default InteractionComponent.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = SwingMesh)
	UInteractionComponent PickupInteractionComponent;
	default PickupInteractionComponent.MovementSettings.InitializeSmoothTeleport();
	default PickupInteractionComponent.ActivationSettings.ActivationTag = n"Pickup";


	UPROPERTY(Category = "Events")
	FOnPlayerMountedSwing OnPlayerMountedSwingEvent;

	UPROPERTY(Category = "Events")
	FOnPlayerReleasedSwing OnPlayerReleasedSwingEvent;

	UPROPERTY(Category = "Events")
	FOnBothPlayersEvent OnBothPlayersSwingingEvent;

	UPROPERTY(Category = "Events")
	FOnMarbleEvent OnMarbleCaughtEvent;

	UPROPERTY(Category = "Events")
	FOnMarbleShitThrowEvent OnMarbleShitThrowEvent;

	UPROPERTY()
	UHazeCapabilitySheet TrapezeCapabilitySheet;


	UPROPERTY()
	const float Length = 750.f;

	const float MaximumSwingAmplitude = 10.f;

	// Holds information for ABP
	UTrapezeAnimationDataComponent AnimationDataComponent;

	AHazePlayerCharacter PlayerOnSwing;
	UTrapezeComponent PlayerTrapezeComponent;

	FRotator RopeRotation;

	FQuat SwingLerpStart;
	float SwingLerpAlpha = 1.f;

	float OriginalSwingLinearDamping;

	bool bTrapezeSectionCleared = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ConstructSplineMesh();
		
		// Copy interaction component's properties into the pickup one
		PickupInteractionComponent.RelativeTransform = InteractionComponent.RelativeTransform;

		PickupInteractionComponent.bStartDisabled = InteractionComponent.bStartDisabled;
		PickupInteractionComponent.StartDisabledReason = InteractionComponent.StartDisabledReason;
		PickupInteractionComponent.ExclusiveMode = InteractionComponent.ExclusiveMode;

		PickupInteractionComponent.ActionVolume = InteractionComponent.ActionVolume;
		PickupInteractionComponent.ActionShape = InteractionComponent.ActionShape;
		PickupInteractionComponent.ActionShapeTransform = InteractionComponent.ActionShapeTransform;

		PickupInteractionComponent.FocusVolume = InteractionComponent.FocusVolume;
		PickupInteractionComponent.FocusShape = InteractionComponent.FocusShape;
		PickupInteractionComponent.FocusShapeTransform = InteractionComponent.FocusShapeTransform;

		PickupInteractionComponent.Visuals = InteractionComponent.Visuals;
		PickupInteractionComponent.Visuals.VisualOffset = InteractionComponent.Visuals.VisualOffset;
		PickupInteractionComponent.bUseLazyTriggerShapes = InteractionComponent.bUseLazyTriggerShapes;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bTrapezeSectionCleared = false;
		SetupInteractionComponent();

		// Ignore parent's scale (SwingMesh)
		InteractionComponent.SetAbsolute(bNewAbsoluteScale = true);
		PickupInteractionComponent.SetAbsolute(bNewAbsoluteScale = true);
		PlayerPositionInSwing.SetAbsolute(bNewAbsoluteScale = true);

		// Set maxmimum trapeze amplitude
		SetMaxSwingAmplitude(MaximumSwingAmplitude);

		// Save velocity damping variable
		OriginalSwingLinearDamping = SwingMesh.GetLinearDamping();

		// Set delegates
		OnPlayerMountedSwingEvent.AddUFunction(this, n"OnPlayerMountedSwing");
		OnPlayerReleasedSwingEvent.AddUFunction(this, n"OnPlayerReleasedSwing");
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update ropes' rotation if player is using trapeze
		if(PlayerOnSwing != nullptr)
		{
			RopeRotation.Pitch = GetCurrentAmplitude();
			RopeBase.SetRelativeRotation(RopeRotation);		
		}
		// Lerp trapeze back to origin if player just left it
		else if(SwingIsLerpingToRestPosition())
		{
			SwingLerpAlpha += DeltaSeconds * 2.f;
			RopeBase.SetRelativeRotation(FQuat::FastLerp(SwingLerpStart, FQuat::Identity, ResetLerpSpeedCurve.GetFloatValue(SwingLerpAlpha)));
		}
	}

	void SetupInteractionComponent()
	{
		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.Delegate.BindUFunction(this, n"CanPlayerInteract");
		InteractionComponent.AddTriggerCondition(n"PlayerCanInteract", TriggerCondition);
		PickupInteractionComponent.AddTriggerCondition(n"PlayerCanInteract", TriggerCondition);

		InteractionComponent.OnActivated.AddUFunction(this, n"OnPlayerInteractionStarted");
		PickupInteractionComponent.OnActivated.AddUFunction(this, n"OnPlayerInteractionStarted");
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInteract(UHazeTriggerComponent TriggerComponet, AHazePlayerCharacter PlayerCharacter)
	{
		// Don't allow if there is a marble nearby and player hasn't picked it up
		TArray<AActor> OverlappingActors;
		PlayerCharacter.GetOverlappingActors(OverlappingActors, ATrapezeMarbleActor::StaticClass());
		if(OverlappingActors.Num() > 0)
		{
			// There will only be one of these
			UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
			if(PlayerPickupComponent.CurrentPickup != OverlappingActors[0])
				return false;
		}

		// Don't allow interaction if player is already swingin'
		return !PlayerCharacter.IsAnyCapabilityActive(TrapezeTags::Trapeze) &&	
				PlayerOnSwing == nullptr &&
			   !SwingIsLerpingToRestPosition();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		// Add trapeze interaction component in case it doesn't exist yet
		PlayerTrapezeComponent = UTrapezeComponent::GetOrCreate(PlayerCharacter);
		AnimationDataComponent = UTrapezeAnimationDataComponent::GetOrCreate(PlayerCharacter);

		//Audio Panning
		HazeAkComponent.SetRTPCValue("Rtpc_Goldberg_Circus_Trapeze_Panning", PanningValue);

		// Wakey wakey trapeze component
		PlayerTrapezeComponent.Initialize(this, TrapezeCapabilitySheet, GetTargetDispenserLocation());

		// Cleanup movement crumbs and block movement synchronization
		if(Network::IsNetworked() && HasControl())
		{
			PlayerCharacter.CleanupCurrentMovementTrail();
			PlayerCharacter.BlockMovementSyncronization(this);
		}

		InteractionComponent.Disable(n"PlayerTrapezeInteraction");
		PickupInteractionComponent.Disable(n"PlayerTrapezeInteraction");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerMountedSwing(AHazePlayerCharacter PlayerCharacter)
	{
		PlayerOnSwing = PlayerCharacter;
		EnableSwingPhysics();

		InteractingPlayer = PlayerCharacter;

		// Set locomotion asset
		PlayerCharacter.AddLocomotionAsset(GetLocomotionStateMachineAsset(PlayerCharacter), this);

		// Activate swing capability
		UTrapezeComponent::Get(PlayerCharacter).SetPlayerIsOnSwing(true);

		// Check if other player is already on swing
		if(OtherTrapeze.PlayerOnSwing != nullptr)
		{
			OnBothPlayersSwingingEvent.Broadcast();
			OtherTrapeze.OnBothPlayersSwingingEvent.Broadcast();
		}

		HazeAudio::SetPlayerPanning(HazeAkComponent, PlayerCharacter);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerReleasedSwing(AHazePlayerCharacter PlayerCharacter)
	{
		DisableSwingPhysics();

		AnimationDataComponent.Reset();

		InteractingPlayer = nullptr;

		//Audio Panning Reset
		HazeAkComponent.SetRTPCValue("Rtpc_Goldberg_Circus_Trapeze_Panning", 0.f);

		// Re-enable crumb synch
		if(Network::IsNetworked() && HasControl())
			PlayerCharacter.UnblockMovementSyncronization(this);

		// Re-enable interaction component
		InteractionComponent.EnableAfterFullSyncPoint(n"PlayerTrapezeInteraction");
		PickupInteractionComponent.EnableAfterFullSyncPoint(n"PlayerTrapezeInteraction");

		// Lerp swing back to origin
		SwingLerpAlpha = 0.f;
		SwingLerpStart = RopeBase.GetRelativeTransform().GetRotation();

		// Cleanup
		PlayerOnSwing = nullptr;
		PlayerTrapezeComponent = nullptr;
	}

	void EnableSwingPhysics()
	{
		if(SwingMesh.AttachParent == nullptr)
			return;

		SwingMesh.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld);
		SwingMesh.SetSimulatePhysics(true);
		PhysicsConstraintComponent.SetConstrainedComponents(Cast<UPrimitiveComponent>(RopeBase), NAME_None, SwingMesh, NAME_None);
	}

	void DisableSwingPhysics()
	{
		PhysicsConstraintComponent.SetConstrainedComponents(nullptr, NAME_None, nullptr, NAME_None);
		SwingMesh.SetSimulatePhysics(false);
		SwingMesh.AttachToComponent(RopeBase, NAME_None, EAttachmentRule::KeepWorld);

		// Reset swing mesh's relative location in case physics offset it
		SwingMesh.SetRelativeLocation(FVector(0.f, 0.f, -FMath::Abs(Length)));
	}

	bool SwingIsLerpingToRestPosition()
	{
		return SwingLerpAlpha < 1.f;
	}

	float GetCurrentAmplitude() property
	{
		return PhysicsConstraintComponent.GetCurrentSwing2();
	}

	float GetAbsoluteAmplitude() property
	{
		return FMath::Abs(GetCurrentAmplitude());
	}

	void SetMaxSwingAmplitude(float Amplitude) property
	{
		PhysicsConstraintComponent.SetAngularSwing2Limit(EAngularConstraintMotion::ACM_Limited, Amplitude);
	}

	void ResetSwingLinearDamping()
	{
		SwingMesh.SetLinearDamping(OriginalSwingLinearDamping);
	}

	float GetNormalizedSpeed() property
	{
		return Math::Saturate(SwingMesh.ComponentVelocity.Size() / 1000.f);
	}

	FVector GetTargetDispenserLocation() property
	{
		return ActorTransform.TransformPosition(TargetDispenser);
	}

	UFUNCTION()
	void TrapezeSectionCleared()
	{
		InteractionComponent.Disable(n"TrapezeCleared");
		PickupInteractionComponent.Disable(n"TrapezeCleared");

		bTrapezeSectionCleared = true;
	}

	UHazeLocomotionStateMachineAsset GetLocomotionStateMachineAsset(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ? LocomotionStateMachineAssetCody : LocomotionStateMachineAssetMay;
	}

	UAnimSequence GetEnterSequence(AHazePlayerCharacter PlayerCharacter)
	{
		if(PlayerTrapezeComponent.PlayerHasMarble())
			return PlayerCharacter.IsCody() ? EnterWithMarbleSequenceCody : EnterWithMarbleSequenceMay;
		else
			return PlayerCharacter.IsCody() ? EnterSequenceCody : EnterSequenceMay;
	}

	UAnimSequence GetExitSequence(AHazePlayerCharacter PlayerCharacter)
	{
		if(PlayerTrapezeComponent.PlayerHasMarble())
			return PlayerCharacter.IsCody() ? ExitWithMarbleSequenceCody : ExitWithMarbleSequenceMay;
		else
			return PlayerCharacter.IsCody() ? ExitSequenceCody : ExitSequenceMay;
	}

	void ConstructSplineMesh()
	{
		FVector RopeStart, RopeEnd;
		FVector TangentStart, TangentEnd;

		SwingMesh.SetRelativeLocation(FVector(0.f, 0.f, -FMath::Abs(Length)));

		RopeLeft.ClearSplinePoints();
		RopeLeft.AddSplinePoint(FVector::ZeroVector, ESplineCoordinateSpace::Local);
		RopeLeft.AddSplinePoint(FVector(0.f, 3.f, SwingMesh.GetRelativeTransform().Location.Z), ESplineCoordinateSpace::Local);

		RopeLeft.GetLocationAndTangentAtSplinePoint(0, RopeStart, TangentStart, ESplineCoordinateSpace::Local);
		RopeLeft.GetLocationAndTangentAtSplinePoint(1, RopeEnd, TangentEnd, ESplineCoordinateSpace::Local);
		RopeLeftMesh.SetStartAndEnd(RopeStart, TangentStart, RopeEnd, TangentEnd, true);
		
		RopeRight.ClearSplinePoints();
		RopeRight.AddSplinePoint(FVector::ZeroVector, ESplineCoordinateSpace::Local, true);
		RopeRight.AddSplinePoint(FVector(0.f, -3.f, SwingMesh.GetRelativeTransform().Location.Z), ESplineCoordinateSpace::Local);

		RopeRight.GetLocationAndTangentAtSplinePoint(0, RopeStart, TangentStart, ESplineCoordinateSpace::Local);
		RopeRight.GetLocationAndTangentAtSplinePoint(1, RopeEnd, TangentEnd, ESplineCoordinateSpace::Local);
		RopeRightMesh.SetStartAndEnd(RopeStart, TangentStart, RopeEnd, TangentEnd, true);
	}
}