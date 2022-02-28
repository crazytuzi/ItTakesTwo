import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.InteractionComponent;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledJumpParams;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledEventComponent;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledCollisionSolver;
import Peanuts.Movement.DefaultCharacterRemoteCollisionSolver;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeTownVOBank;

#if EDITOR
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledRideGate;
#endif

import void InitializeBoatsledComponent(ABoatsled, AHazePlayerCharacter) from "Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent";

#if EDITOR
	enum EBoatsledPlayer
	{
		None,
		May,
		Cody
	};
#endif

class ABoatsled : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.bDepenetrateOutOfOtherMovementComponents = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;


	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffsetComponent;

	// Boatsled's movement component collision shape
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USphereComponent SphereCollider;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USkeletalMeshComponent MeshComponent;

	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	USceneComponent LeftSkiVFXOrigin;

	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	USceneComponent RightSkiVFXOrigin;

	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	UCapsuleComponent PlayerCollisionCapsule;


	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Totem")
	USceneComponent PlayerEnterAnimationOffset;
	default PlayerEnterAnimationOffset.SetRelativeLocation(FVector(0, 0, 0));

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;

	UPROPERTY()
	UHazeCapabilitySheet BoatsledCapabilitySheet;


	// Eman TODO: Maybe provide an array with all of them tracks
	UPROPERTY(EditInstanceOnly, Category = "Boatsled Track", DisplayName = "Boatsled Track Actor")
	AHazeActor BoatsledTrack;


	UPROPERTY(EditInstanceOnly)
	ABoatsled OtherBoatsled;

	UPROPERTY(Category = "Curves")
	UCurveFloat SteerControlCurve;

	UPROPERTY(Category = "Curves")
	UCurveFloat AccelerationCurve;

	UPROPERTY(Category = "Curves")
	UCurveFloat PushStartAccelerationCurve;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent FrontRightSki;
	
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent FrontLeftSki;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent RearRightSki;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent RearLeftSki;


	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	USpotLightComponent SpotLightLarge;


	float OriginalSpotLightIntensity;


	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor FinishSequence;


	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> PushStartCameraShake;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSpringArmSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset PushStartSpringArmSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset TunnelCameraSpringArmSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset ChimneyFallthroughSpringArmSettings;

	UPROPERTY(Category = "Camera")
	UCurveFloat TunnelCameraYawCurve;


	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComponent;


	UPROPERTY(Category = "Animations | Cody")
	UHazeLocomotionStateMachineAsset LocomotionStateMachineAssetCody;

	UPROPERTY(Category = "Animations | Cody")
	UAnimSequence EnterAnimationCody;

	UPROPERTY(Category = "Animations | Cody")
	UAnimSequence ExitAnimationCody;


	UPROPERTY(Category = "Animations | May")
	UHazeLocomotionStateMachineAsset LocomotionStateMachineAssetMay;

	UPROPERTY(Category = "Animations | May")
	UAnimSequence EnterAnimationMay;

	UPROPERTY(Category = "Animations | May")
	UAnimSequence ExitAnimationMay;


	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	UNiagaraComponent BoostEffect;
	default BoostEffect.bAutoActivate = false;

	UPROPERTY()
	const float MaxSpeed = 3200.f;

	UPROPERTY()
	const float SteerSpeed = 50.f;


	UPROPERTY(Category = "Rubber banding")
	bool bRubberBandingEnabled = true;

	UPROPERTY(EditDefaultsOnly, Category = "Rubber banding")
	float MaxRubberbandDistance = 3000.f;

	// This is the multiplier that will be applied to all movement
	UPROPERTY(EditDefaultsOnly, Category = "Rubber banding")
	float RubberbandBoostMultiplier = 1.5f;


	// Used by BoatsledCameraCapability, used to offset the focus on spline point of interest along spline distance
	UPROPERTY()
	const float SplinePointOfInterestDistanceFromBoatsled = 4000.f;

	// Player using the boatsled, valid as soon as sled is interacted with
	private AHazePlayerCharacter Boatsledder;

	// Used to network pivot transform by tunnel's end
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothTunnelPivotLocation;
	default SmoothTunnelPivotLocation.NumberOfSyncsPerSecond = 10.f;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothTunnelPivotRotation;
	default SmoothTunnelPivotRotation.NumberOfSyncsPerSecond = 10.f;


	// Holds boatsled's most generic events
	UPROPERTY(DefaultComponent)
	UBoatsledEventComponent BoatsledEventHandler;


	UPROPERTY(Category = "Force Feedback", EditDefaultsOnly)
	UForceFeedbackEffect CollisionRumble;

	UPROPERTY(Category = "Force Feedback", EditDefaultsOnly)
	UForceFeedbackEffect JumpStartRumble;

	UPROPERTY(Category = "Force Feedback", EditDefaultsOnly)
	UForceFeedbackEffect LandingRumble;


	UPROPERTY(Category = "Audio")
	USnowGlobeTownVOBank VOBank;


	UMaterialInstanceDynamic DynamicHeadlampMaterialInstance;
	FLinearColor OriginalBoatsledMaterialEmissive;

	const FName CollisionProfile = n"IgnoreOnlyPawn";
	default SphereCollider.SetCollisionProfileName(CollisionProfile);

	bool bPlayerStoppedSledding;
	bool bOtherPlayerStoppedSledding;

	// Level blueprint will set this when it's ready for sledding
	private bool bReadyForRide;

	UFUNCTION(BlueprintEvent)
	void OnBoatsledJumped(FVector Velocity) { }

	UFUNCTION(BlueprintEvent)
	void OnBoatsledLanded(FVector Velocity) { }

	UFUNCTION(BlueprintEvent)
	void OnBoatsledReachedMaxSpeed() { }

	UFUNCTION(BlueprintEvent)
	void OnBoatsledLostMaxSpeed() { }

	UFUNCTION(BlueprintEvent)
	void OnWhaleSleddingStarted() { }

	UFUNCTION(BlueprintEvent)
	void OnWhaleSleddingFinished() { }


#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "EditorDev")
	ABoatsledRideGate RideGate;

	UPROPERTY(EditInstanceOnly, Category = "EditorDev")
	EBoatsledPlayer StartWithPlayerInteracting = EBoatsledPlayer::None;

	// Won't work if starting before gate
	UPROPERTY(EditInstanceOnly, Category = "EditorDev")
	bool bSkipWaitAndPushStart = false;

	UPROPERTY(EditInstanceOnly, Category = "EditorDev", DisplayName = "Start with State", Meta = (EditCondition = "bSkipWaitAndPushStart", EditConditionHides))
	EBoatsledState StartState = EBoatsledState::HalfPipeSledding;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(MovementComponent == nullptr)
			return;

		if(World == nullptr)
			return;

		if(BoatsledTrack == nullptr)
			return;

		// Get boatsled's ground normal
		FVector GroundNormal;
		if(!GetGroundNormal(GroundNormal))
			return;

		// Get spline's rotation info
		UHazeSplineComponent TrackSpline = UHazeSplineComponent::Get(BoatsledTrack, n"HazeGuideSpline");
		float DistanceAlongSpline = TrackSpline.GetDistanceAlongSplineAtWorldLocation(GetActorLocation());
		FVector SplineVector = TrackSpline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		// Rotate boatsled on track
		FQuat Rotation = Math::MakeQuatFromXZ(SplineVector, GroundNormal.GetSafeNormal());
		SetActorRotation(Rotation);
	}

	UFUNCTION(CallInEditor)
	void LevelSledToTrack()
	{
		// Set boatsled height relative to track to match movement component when starting the move
		if(!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
		{
			FHitResult HitResult;
			if(System::SphereTraceSingle(SphereCollider.WorldLocation, SphereCollider.WorldLocation * ActorUpVector * MeshComponent.RelativeLocation.Z, SphereCollider.SphereRadius, ETraceTypeQuery::TraceTypeQuery1, false, TArray<AActor>(), EDrawDebugTrace::None, HitResult, true) && HitResult.Actor == BoatsledTrack && HitResult.bBlockingHit)
				AddActorWorldOffset(ActorUpVector * (HitResult.PenetrationDepth + HitResult.Distance + MeshOffsetComponent.RelativeLocation.Z));
		}
	}

	bool GetGroundNormal(FVector& OutAverageNormal)
	{
		OutAverageNormal = FVector::ZeroVector;

		FHitResult HitResult;

		FVector NormalSum;
		FVector MovementComponentNormal = MovementComponent.DownHit.Normal;
		if(MovementComponentNormal != FVector::ZeroVector)
			NormalSum += MovementComponentNormal;

		TArray<USceneComponent> BoatsledSkis;
		BoatsledSkis.Add(FrontLeftSki);
		BoatsledSkis.Add(FrontRightSki);
		BoatsledSkis.Add(RearLeftSki);
		BoatsledSkis.Add(RearRightSki);

		// Gotta trace and get normals from all four skis
		for(USceneComponent Ski : BoatsledSkis)
		{
			System::LineTraceSingle(Ski.GetWorldLocation(), Ski.GetWorldLocation() - MeshComponent.UpVector * 100.f, ETraceTypeQuery::TraceTypeQuery2, false, TArray<AActor>(), EDrawDebugTrace::None, HitResult, true);

			if(HitResult.bBlockingHit && HitResult.Actor != nullptr && HitResult.Actor.Name.ToString().Contains("BoatsledTrack"))
				NormalSum += HitResult.Normal;
		}

		if(NormalSum.IsZero())
			return false;

		OutAverageNormal = NormalSum.GetSafeNormal();

		return true;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Setting up movement component's collision resets its rotation, restore rotation afterwards!
		FRotator BoatsledRotation = ActorRotation;
		MovementComponent.Setup(SphereCollider);
		MovementComponent.UseCollisionSolver(UBoatsledCollisionSolver::StaticClass(), UDefaultCharacterRemoteCollisionSolver::StaticClass());
		SetActorRotation(BoatsledRotation);

		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.Delegate.BindUFunction(this, n"PlayerCanInteract");

		InteractionComponent.AddTriggerCondition(n"PlayerCanInteract", TriggerCondition);
		InteractionComponent.OnActivated.AddUFunction(this, n"OnPlayerInteractionStarted");

		// Save original light params
		OriginalSpotLightIntensity = SpotLightLarge.Intensity;
		DynamicHeadlampMaterialInstance = MeshComponent.CreateDynamicMaterialInstance(1);
		OriginalBoatsledMaterialEmissive = DynamicHeadlampMaterialInstance.GetVectorParameterValue(n"Emissive Tint");

		// Turn off headlamp
		SpotLightLarge.SetVisibility(false);
		DynamicHeadlampMaterialInstance.SetVectorParameterValue(n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.5f));

#if EDITOR
		SetReadyForRide();
		if(StartWithPlayerInteracting != EBoatsledPlayer::None)
			InteractionComponent.StartActivating(StartWithPlayerInteracting == EBoatsledPlayer::Cody ? Game::GetCody() : Game::GetMay());
#endif
	}

	// Used as a watchdog for when boatsled capabilities stop consuming crumbs for some reason
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CurrentBoatsledder == nullptr)
			return;

		if(!Network::IsNetworked())
			return;

		if(HasControl())
			return;

		if(CrumbComponent.CrumbTrailLength > CrumbComponent.UpdateSettings.OptimalCount * 2)
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, FHazeActorReplicationFinalized());
	}

	UFUNCTION()
	void SetReadyForRide()
	{
		bReadyForRide = true;
	}

	UFUNCTION()
	bool PlayerCanInteract(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		if(!bReadyForRide)
			return false;

		if(Boatsledder != nullptr)
			return false;

		if(PlayerCharacter.IsAnyCapabilityActive(BoatsledTags::Boatsled))
			return false;

		return true;
	}

	UFUNCTION()
	void OnPlayerInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		InteractionComponent.Deactivate();

		Boatsledder = PlayerCharacter;

		// Initialize system
		InitializeBoatsledComponent(this, PlayerCharacter);

		// Initialize and bind ride-end delegates
		BoatsledEventHandler.OnPlayerStoppedSledding.AddUFunction(this, n"OnPlayerStoppedSledding");
		if(OtherBoatsled != nullptr)
			OtherBoatsled.BoatsledEventHandler.OnPlayerStoppedSledding.AddUFunction(this, n"OnOtherPlayerStoppedSledding");

		// Bind other delegates
		BoatsledEventHandler.OnBoatsledWhaleSleddingStarted.AddUFunction(this, n"OnBoatsledWhaleSleddingStarted");

		// Fire interaction start event
		BoatsledEventHandler.OnBoatsledInteractionStarted.Broadcast();

	#if EDITOR
		if(bSkipWaitAndPushStart)
		{
			BoatsledEventHandler.OnStartLightMark.Broadcast(4);
			if(RideGate != nullptr)
				RideGate.Open();
		}
	#endif
	}

	UFUNCTION()
	void OnPlayerStoppedSledding(AHazePlayerCharacter PlayerCharacter)
	{
		Boatsledder = nullptr;
		bPlayerStoppedSledding = true;
		if(bOtherPlayerStoppedSledding)
			LeaveBothPlayersStoppedCrumb();
	}

	UFUNCTION()
	void OnOtherPlayerStoppedSledding(AHazePlayerCharacter PlayerCharacter)
	{
		bOtherPlayerStoppedSledding = true;
		if(bPlayerStoppedSledding)
			LeaveBothPlayersStoppedCrumb();
	}

	void LeaveBothPlayersStoppedCrumb()
	{
		bPlayerStoppedSledding = false;
		bOtherPlayerStoppedSledding = false;

		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"OnBothPlayersStoppedSleddingCrumb"), FHazeDelegateCrumbParams());
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBothPlayersStoppedSleddingCrumb(const FHazeDelegateCrumbData& CrumbData)
	{
		BoatsledEventHandler.OnBothPlayersStoppedSledding.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBoatsledWhaleSleddingStarted()
	{
		OnWhaleSleddingStarted();
	}

	void ToggleHeadlamp(bool bValue)
	{
		CurrentBoatsledder.SetCapabilityActionState(bValue ? BoatsledTags::SwitchHeadlampOn : BoatsledTags::SwitchHeadlampOff, EHazeActionState::ActiveForOneFrame);
	}

	void CleanAfterUse()
	{
		Boatsledder = nullptr;
		bPlayerStoppedSledding = false;
		bOtherPlayerStoppedSledding = false;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetCurrentBoatsledder() property
	{
		return Boatsledder;
	}

	UAnimSequence GetEnterAnimation(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ? EnterAnimationCody : EnterAnimationMay;
	}

	UAnimSequence GetExitAnimation(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ? ExitAnimationCody : ExitAnimationMay;
	}

	UHazeLocomotionStateMachineAsset GetLocomotionStateMachineAsset(AHazePlayerCharacter PlayerCharacter)
	{
		return PlayerCharacter.IsCody() ?
			LocomotionStateMachineAssetCody :
			LocomotionStateMachineAssetMay;
	}
}