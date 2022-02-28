import Cake.LevelSpecific.Shed.Vacuum.VacuumableComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumStatics;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumPlayerAnimationDataAsset;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseAnimationDataAsset;
import Vino.Interactions.InteractionComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHub;
import Vino.Movement.MovementSystemTags;

event void FOnLaunchedFromHose(AHazePlayerCharacter Player, AVacuumHoseActor Hose, EVacuumMountLocation Location);
event void FOnObjectLaunchedFromHose(AHazeActor Actor);
event void FOnEnteredHose(AHazePlayerCharacter Player);
event void FHoseMountEvent(AHazePlayerCharacter Player);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AVacuumHoseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent BaseComponent;

	UPROPERTY(DefaultComponent, Attach = BaseComponent)
	UHazeSplineComponent RefSplineComponent;

	UPROPERTY(DefaultComponent, Attach = BaseComponent)
	UHazeSplineComponent MainSplineComponent;
#if EDITOR
	default MainSplineComponent.SetEditorSelectedSplineSegmentColor(FLinearColor::Black);
	default MainSplineComponent.SetEditorUnselectedSplineSegmentColor(FLinearColor::Black);
	default MainSplineComponent.bVisualizeSpline = false;
#endif

	UPROPERTY(DefaultComponent, Attach = BaseComponent)
	USceneComponent FrontAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = BaseComponent)
	USceneComponent BackAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	USceneComponent FrontLaunchLocation;
	default FrontLaunchLocation.RelativeLocation = FVector(300.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	USceneComponent BackLaunchLocation;
	default BackLaunchLocation.RelativeLocation = FVector(300.f, 0.f, 0.f);
	
	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	USphereComponent FrontEntrance;
	default FrontEntrance.SphereRadius = 70.f;
	default FrontEntrance.RelativeLocation = FVector(150.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	USphereComponent BackEntrance;
	default BackEntrance.SphereRadius= 70.f;
	default BackEntrance.RelativeLocation = FVector(150.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UInteractionComponent FrontInteractionComp;

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UInteractionComponent BackInteractionComp;
	
	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UCapsuleComponent FrontCapsule;
	default FrontCapsule.CapsuleRadius = 70.f;
	default FrontCapsule.CapsuleHalfHeight = FrontCapsuleLength;
	default FrontCapsule.RelativeRotation = FRotator(-90,0,0);
	default FrontCapsule.RelativeLocation = FVector(150.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UCapsuleComponent BackCapsule;
	default BackCapsule.CapsuleRadius = 70.f;
	default BackCapsule.CapsuleHalfHeight = BackCapsuleLength;
	default BackCapsule.RelativeRotation = FRotator(-90,0,0);
	default BackCapsule.RelativeLocation = FVector(150.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = FrontCapsule)
	UArrowComponent FrontArrow;
	default FrontArrow.SetArrowColor(FLinearColor::Green);
	default FrontArrow.RelativeScale3D = FVector(3.f, 3.f, 3.f);

	UPROPERTY(DefaultComponent, Attach = BackCapsule)
	UArrowComponent BackArrow;
	default BackArrow.SetArrowColor(FLinearColor::LucBlue);
	default BackArrow.RelativeScale3D = FVector(3.f, 3.f, 3.f);

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UNiagaraComponent FrontSuckEffect;

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UNiagaraComponent FrontBlowEffect;

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UNiagaraComponent BackSuckEffect;

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UNiagaraComponent BackBlowEffect;

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UHazeAkComponent FrontHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UHazeAkComponent BackHazeAkComp;

	// No Rtpc's or postevents will be done.
	UPROPERTY(Category = "Audio")
	bool bUseAudioComponents = true;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnEnterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnExitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeforeExitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnInteractVacuumEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnExitVacuumEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartBlowOrSuckVacuumFrontEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBlowOrSuckVacuumFrontEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartBlowOrSuckVacuumBackEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBlowOrSuckVacuumBackEvent;

	//UPROPERTY(Category = "Audio Events")
	//UAkAudioEvent ChangeBlowOrSuckDirectionEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SuckUpObjectEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BlowOutObjectEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ControllableVacuumImpactFrontEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ControllableVacuumImpactBackEvent;

	UPROPERTY(Category = "Music Events")
	UAkAudioEvent OnEnterMusicEvent;

	UPROPERTY(Category = "Music Events")
	UAkAudioEvent OnExitMusicEvent;

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UStaticMeshComponent FrontFace;
	default FrontFace.RelativeRotation = FRotator(0,180,0);
	default FrontFace.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default FrontFace.LightmapType = ELightmapType::ForceVolumetric;

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UStaticMeshComponent BackFace;
	default BackFace.RelativeRotation = FRotator(0,180,0);
	default BackFace.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default BackFace.LightmapType = ELightmapType::ForceVolumetric;

	UPROPERTY(DefaultComponent, Attach = FrontAttachmentPoint)
	UHazeSkeletalMeshComponentBase SkeletalFrontFace;
	default SkeletalFrontFace.AnimationMode = EAnimationMode::AnimationSingleNode;
	default SkeletalFrontFace.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(DefaultComponent, Attach = BackAttachmentPoint)
	UHazeSkeletalMeshComponentBase SkeletalBackFace;
	default SkeletalBackFace.AnimationMode = EAnimationMode::AnimationSingleNode;
	default SkeletalBackFace.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.f;

	UPROPERTY(Category = "ArtistStuff")
	bool bDestroySelf = false;

	UPROPERTY()
	bool bTickActive = true;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UStaticMesh HoseMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UPhysicalMaterial PhysMat;

	UPROPERTY(NotEditable, Category = "Setup")
	TArray<USphereComponent> CollisionSpheres;

	UPROPERTY(NotEditable, Category = "Setup")
	TArray<USplineMeshComponent> SplineMeshes;

	UPROPERTY(NotEditable, Category = "Setup")
	TArray<UPhysicsConstraintComponent> PhysicsConstraints;
	
	UPROPERTY(NotEditable, Category = "Setup")
	TArray<USphereComponent> IntermediateCollisionSpheres;
	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UStaticMesh NoFaceMesh;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UStaticMesh FunnelMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	UHazeCapabilitySheet ExhaustSheet;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<UCameraShakeBase> GoingThroughHoseCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	UForceFeedbackEffect SuckUpObjectForceFeedback;

	UPROPERTY(Category = "Animation", EditDefaultsOnly)
	UVacuumPlayerAnimationDataAsset MayAnimations;

	UPROPERTY(Category = "Animation", EditDefaultsOnly)
	UVacuumPlayerAnimationDataAsset CodyAnimations;

	UPROPERTY(Category = "Animation", EditDefaultsOnly)
	UVacuumHoseAnimationDataAsset HoseAnimations;

	TArray<AHazeActor> ActorsAtFrontExhaust;
	TArray<AHazeActor> ActorsAtBackExhaust;
	
	UPROPERTY(NotVisible)
	TArray<AHazeActor> ActorsInHose;

	UPROPERTY(NotVisible)
	TArray<AHazeActor> BulgingActors;

	UPROPERTY(NotVisible)
	TArray<float> DistancesInHose;
	
	float CollisionSphereRadius = 100.f;

	UPROPERTY(Category = "Properties")
	float FrontCapsuleLength = 600.f;

	UPROPERTY(Category = "Properties")
	float BackCapsuleLength = 600.f;

	UPROPERTY(Category = "Properties")
	float LaunchForce = 2000.f;

	UPROPERTY(Category = "Properties")
	float DefaultExhaustForce = 5000.f;
	
	UPROPERTY(Category = "Properties")
	float DefaultSpeedThroughHose = 2000.f;

	float CurrentForce;

	UPROPERTY(NotVisible)
	FExhaustDistanceMultiplierRange ExhaustMultiplierRange;
	default ExhaustMultiplierRange.Min = 0.f;
	default ExhaustMultiplierRange.Max = 2.f;

	UPROPERTY(Category = "Properties")
	FStaticRange StaticRange;
	
	UPROPERTY(Category = "Properties")
	EVacuumMode FrontVacuumMode;

	UPROPERTY(Category = "Properties")
	bool bFrontMountable = true;

	UPROPERTY(Category = "Properties")
	bool bBackMountable = true;
	
	UPROPERTY(Category = "Properties")
	EVacuumHeadType FrontHeadType;

	UPROPERTY(Category = "Properties")
	bool bOverrideLaunch = false;

	UPROPERTY(Category = "Properties")
	EVacuumHeadType BackHeadType;

	UPROPERTY(Category = "Properties")
	float LaunchMoveSpeed = 1700.f;

	UPROPERTY(Category = "Properties")
	bool bWalkable = false;

	UPROPERTY(Category = "Properties")
	AVacuumHub TargetHub;

	UPROPERTY(Category = "Properties")
	bool bDisableLaunchOnImpact = true;

	UPROPERTY(Category = "Properties")
	bool bSetEntranceSizeAndOffsetAutomatically = true;

	UPROPERTY(Category = "Animation")
	float StopSpinningTime = -1.f;

	UPROPERTY(Category = "Animation")
	float ForwardRotationSpeed = 2.f;

	UPROPERTY(Category = "Animation")
	float SideRotationSpeed = 1.f;

	UPROPERTY(Category = "Animation")
	bool bSkipStart = false;

	UPROPERTY(Category = "Camera")
	FHazePointOfInterest PointOfInterestSettings;
	default PointOfInterestSettings.FocusTarget.LocalOffset = FVector(3000.f, 0.f, 0.f);
	default PointOfInterestSettings.Blend.BlendTime = 1.f;

	UPROPERTY(Category = "Camera")
	float IdealDistance = 1000.f;

	UPROPERTY(Category = "Camera")
	bool bLockMinDistance = true;
	
	UPROPERTY(Category = "Camera")
	float MountedIdealDistanceOverride;
	
	UPROPERTY(Category = "Properties")
	bool bLookForVacuumableComponents = true;

	UPROPERTY(Category = "Physics")
	float LinearDamping = 1.f;

	UPROPERTY(Category = "Physics")
	float AngularDamping = 1.f;

	UPROPERTY(Category = "Physics")
	float Swing1Limit = 10.f;

	UPROPERTY(Category = "Physics")
	float Swing2Limit = 10.f;

	UPROPERTY(Category = "Physics")
	float TwistLimit = 10.f;

	UPROPERTY(Category = "Physics")
	float LinearMotionLimit = 0.f;

	UPROPERTY(Category = "Physics")
	FVacuumControlMaximumForces MaximumFrontForces;
	default MaximumFrontForces.HorizontalMax = 3000.f;
	default MaximumFrontForces.VerticalMax = 3000.f;

	UPROPERTY(Category = "Physics")
	FVacuumControlMaximumForces MaximumBackForces;
	default MaximumBackForces.HorizontalMax = 3000.f;
	default MaximumBackForces.VerticalMax = 3000.f;

	float CurrentSpeedThroughHose;

	UPROPERTY(Category = "Debug")
	bool bShowArrows = false;

	UPROPERTY(Category = "Debug")
	bool bShowCollisionSpheres = false;

	UPROPERTY(Category = "Debug")
	bool bShowCapsules = false;

	UPROPERTY(Category = "Debug")
	bool bVisualizeDisabledSpheres = true;

	UPROPERTY(NotVisible)
	AHazePlayerCharacter FrontPlayer;
	UPROPERTY(NotVisible)
	AHazePlayerCharacter BackPlayer;

	FTimerHandle FrontTimer;
	FTimerHandle BackTimer;

	FVector CurrentFrontForces;
	FVector CurrentBackForces;

	FTransform CurrentFrontTransform;
	FTransform CurrentBackTransform;

	UPROPERTY()
	FOnLaunchedFromHose OnLaunchedFromHose;

	UPROPERTY()
	FOnObjectLaunchedFromHose OnObjectLaunchedFromHose;

	UPROPERTY()
	FOnEnteredHose OnEnteredHose;

	UPROPERTY()
	FHoseMountEvent OnHoseMounted;

	UPROPERTY()
	FHoseMountEvent OnHoseDismounted;

	UPROPERTY()
	bool bTellOtherPlayerToEnter = true;

	UPROPERTY(Category = "BossFight", NotVisible)
	bool bStunned = false;

	UPROPERTY(Category = "BossFight")
	bool bGenerateOverlapEvents = false;

	TArray<UMaterialInstanceDynamic> MaterialInstances;

	bool bMaterialInstancesReset = false;
	bool bPhysicsSimulationToggledOn = false;

	UPROPERTY()
	bool bBossHose = false;

	bool bStunnedMhLocked = false;

	UPROPERTY()
	bool bPlayLaunchBarks = false;

	UPROPERTY()
	bool bUseShadows = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bDestroySelf)
		{
			DestroyActor();
		}

		if (!bTickActive)
			SetActorTickEnabled(false);

		FrontEntrance.OnComponentBeginOverlap.AddUFunction(this, n"EnterFrontEntrance");
		BackEntrance.OnComponentBeginOverlap.AddUFunction(this, n"EnterBackEntrance");
		FrontCapsule.OnComponentBeginOverlap.AddUFunction(this, n"EnterFrontCapsule");
		FrontCapsule.OnComponentEndOverlap.AddUFunction(this, n"ExitFrontCapsule");
		BackCapsule.OnComponentBeginOverlap.AddUFunction(this, n"EnterBackCapsule");
		BackCapsule.OnComponentEndOverlap.AddUFunction(this, n"ExitBackCapsule");

		if (bUseAudioComponents) 
		{
			FrontHazeAkComp.HazePostEvent(StartBlowOrSuckVacuumFrontEvent);
			BackHazeAkComp.HazePostEvent(StartBlowOrSuckVacuumBackEvent);
		}

		UpdateForceDirections();

		UpdateFaceMH();

		SetupInteractionComponents();

		CurrentFrontTransform = GetFirstCollisionSphere().GetWorldTransform();
		CurrentBackTransform = GetLastCollisionSphere().GetWorldTransform();

		CreateMaterialInstances();

		if (bFrontMountable)
		{
			FirstCollisionSphere.SetNotifyRigidBodyCollision(true);
			FirstCollisionSphere.OnComponentHit.AddUFunction(this, n"FrontFloorImpact");
		}

		if (bBackMountable)
		{
			LastCollisionSphere.SetNotifyRigidBodyCollision(true);
			LastCollisionSphere.OnComponentHit.AddUFunction(this, n"BackFloorImpact");
		}

		if (bBossHose)
		{
			CollisionSpheres[0].SetSimulatePhysics(false);
			CollisionSpheres[1].SetSimulatePhysics(false);
			CollisionSpheres[2].SetSimulatePhysics(false);
			CollisionSpheres[3].SetSimulatePhysics(false);

			CollisionSpheres[16].SetSimulatePhysics(false);
			CollisionSpheres[17].SetSimulatePhysics(false);
		}
	}

	UFUNCTION()
	void EnableHose()
	{
		if (!IsActorDisabled())
			return;

		EnableActor(nullptr);
	}

	UFUNCTION()
	void FrontFloorImpact(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
	{
		if (bUseAudioComponents) 
			TriggerImpactSound(HitComponent, EVacuumMountLocation::Front);
	}

	UFUNCTION()
	void BackFloorImpact(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
	{
		if (bUseAudioComponents) 
			TriggerImpactSound(HitComponent, EVacuumMountLocation::Back);
	}

	void TriggerImpactSound(UPrimitiveComponent HitComp, EVacuumMountLocation ExhaustLocation)
	{
		float ImpactVelocity = HitComp.ComponentVelocity.Z;
		if (ImpactVelocity <= 70.f)
			return;

		float ImpactIntensity = FMath::GetMappedRangeValueClamped(FVector2D(70.f, 200.f), FVector2D(0.f, 1.f), ImpactVelocity);
		//Print("" + ImpactIntensity, 2.f);

		if (ExhaustLocation == EVacuumMountLocation::Front && FrontHazeAkComp.IsGameObjectRegisteredWithWwise())
		{
			FrontHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Impact_Intensity_Front", ImpactIntensity);
			FrontHazeAkComp.HazePostEvent(ControllableVacuumImpactFrontEvent);
		}
		else if(BackHazeAkComp.IsGameObjectRegisteredWithWwise())
		{
			BackHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Impact_Intensity_Back", ImpactIntensity);
			BackHazeAkComp.HazePostEvent(ControllableVacuumImpactBackEvent);
		}
	}

	void CreateMaterialInstances()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			UMaterialInstanceDynamic Instance = SplineMesh.CreateDynamicMaterialInstance(0, nullptr);
			MaterialInstances.Add(Instance);
		}
	}

	void AddBulgingActor(AHazeActor Actor)
	{
		BulgingActors.Add(Actor);
	}

	void RemoveBulgingActor(AHazeActor Actor)
	{
		BulgingActors.RemoveSwap(Actor);
	}

	void UpdateMaterialInstances()
	{
		if (BulgingActors.Num() != 0)
		{
			bMaterialInstancesReset = false;

			for (UMaterialInstanceDynamic Instance : MaterialInstances)
			{
				for (AHazeActor Actor : BulgingActors)
				{
					int ActorIndex = BulgingActors.FindIndex(Actor);
					FName ParameterName;

					if (ActorIndex < 3)
					{
						FVector Location = Actor.ActorLocation;
						FLinearColor Color = FLinearColor(Location.X, Location.Y, Location.Z, 80.f);

						Instance.SetVectorParameterValue(GetHoseBulgeParameterName(ActorIndex), Color);
						
						float Strength = 80.f;
						Instance.SetVectorParameterValue(n"Strengths", FLinearColor(Strength, Strength, Strength, Strength));
					}
				}
			}
		}

		else if (!bMaterialInstancesReset)
		{
			ResetMaterialInstances();
		}
	}

	void ResetMaterialInstances()
	{
		bMaterialInstancesReset = true;

		for (UMaterialInstanceDynamic Instance : MaterialInstances)
		{
			for (int Index = 0, Count = 3; Index < Count; ++ Index)
			{
				Instance.SetVectorParameterValue(GetHoseBulgeParameterName(Index), FLinearColor::Black);
			}
		}
	}

	FName GetHoseBulgeParameterName(int Index)
	{
		FName ParameterName;

			if (Index == 0)
				ParameterName = n"Item0";
			else if (Index == 1)
				ParameterName = n"Item1";
			else if (Index == 2)
				ParameterName = n"Item2";
			else if (Index == 3)
				ParameterName = n"Item3";

		return ParameterName;
	}

	UFUNCTION()
	void OnFrontTriggerActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		FrontPlayer = Player;
		FrontInteractionComp.Disable(n"FrontSeatOccupied");
		if(ActorsAtFrontExhaust.Contains(Player))
			ActorsAtFrontExhaust.Remove(Player);

		MountHose(Player, EVacuumMountLocation::Front, FrontAttachmentPoint);

		FHazePointOfInterest PoISettings;
		PoISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PoISettings.FocusTarget.WorldOffset = FrontAttachmentPoint.WorldLocation + (FrontAttachmentPoint.ForwardVector * 2500.f);
		PoISettings.Duration = 0.75f;
		PoISettings.Blend.BlendTime = 1.f;
		Player.ApplyPointOfInterest(PoISettings, this);

		if(FrontPlayer.HasControl())
			StartFrontTimer();
			
		if (bUseAudioComponents && OnInteractVacuumEvent != nullptr)
			FrontHazeAkComp.HazePostEvent(OnInteractVacuumEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnBackTriggerActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		BackPlayer = Player;
		BackInteractionComp.Disable(n"BackSeatOccupied");
		if(ActorsAtBackExhaust.Contains(Player))
			ActorsAtBackExhaust.Remove(Player);

		MountHose(Player, EVacuumMountLocation::Back, BackAttachmentPoint);

		FHazePointOfInterest PoISettings;
		PoISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PoISettings.FocusTarget.WorldOffset = BackAttachmentPoint.WorldLocation + (BackAttachmentPoint.ForwardVector * 2500.f);
		PoISettings.Duration = 0.75f;
		PoISettings.Blend.BlendTime = 1.f;
		Player.ApplyPointOfInterest(PoISettings, this);
		
		if(BackPlayer.HasControl())
			StartBackTimer();

		if (bUseAudioComponents && OnInteractVacuumEvent != nullptr)
			BackHazeAkComp.HazePostEvent(OnInteractVacuumEvent);
	}
	
	void MountHose(AHazePlayerCharacter Player, EVacuumMountLocation MountLocation, USceneComponent AttachmentPoint)
	{	
		Player.SetCapabilityAttributeObject(n"Hose", this);
    	Player.SetCapabilityAttributeNumber(n"MountLocation", MountLocation);
    	Player.SetCapabilityActionState(n"InteractedWithVacuum", EHazeActionState::Active);

		MountLocation == EVacuumMountLocation::Back ? ResumeBackMH() : ResumeFrontMH();

		OnHoseMounted.Broadcast(Player);
	}

	UFUNCTION()
	void DismountHose(EVacuumMountLocation MountLocation)
	{
		if(MountLocation == EVacuumMountLocation::Front)
		{
			OnHoseDismounted.Broadcast(FrontPlayer);
			FrontPlayer = nullptr;
			CurrentFrontForces = FVector::ZeroVector;
			StopFrontTimer();
			ResumeFrontMH();

			if (bUseAudioComponents && OnExitVacuumEvent != nullptr)
				FrontHazeAkComp.HazePostEvent(OnExitVacuumEvent);
		}
		else
		{
			OnHoseDismounted.Broadcast(BackPlayer);
			BackPlayer = nullptr;
			CurrentBackForces = FVector::ZeroVector;
			StopBackTimer();
			ResumeBackMH();

			if (bUseAudioComponents && OnExitVacuumEvent != nullptr)
				BackHazeAkComp.HazePostEvent(OnExitVacuumEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!IsHoseStatic())
		{
			UpdateHoseSplineRuntime();
			ApplyForces();
			UpdateFrontTransform(DeltaTime);
			UpdateBackTransform(DeltaTime);
			UpdatePhysicsSimulationToggle();
		}

		if(ActorsAtFrontExhaust.Num() != 0)
			MoveActorsAtExhaust(DeltaTime, FrontCapsule, ActorsAtFrontExhaust, 0);

		if(ActorsAtBackExhaust.Num() != 0)
			MoveActorsAtExhaust(DeltaTime, BackCapsule, ActorsAtBackExhaust, GetLastMainSplineIndex());

		UpdateMaterialInstances();

		MoveActorsInHose(DeltaTime);

		UpdateAudioParameters();
	}

	void UpdatePhysicsSimulationToggle()
	{
		if (bBossHose)
			return;

		float MinDistanceToPlayer = FMath::Min(
			Game::Cody.GetDistanceTo(this),
			Game::May.GetDistanceTo(this)
		);

		bool bPhysicsShouldBeOn = (MinDistanceToPlayer < 5000.f) && !IsActorDisabled();
		if (bPhysicsShouldBeOn != bPhysicsSimulationToggledOn)
		{
			for (int Index = 0, Count = GetNumberOfSpheres() + 1; Index < Count; ++ Index)
			{
				if (Index < StaticRange.Min || Index + 1> StaticRange.Max)
					CollisionSpheres[Index].SetSimulatePhysics(bPhysicsShouldBeOn);
			}

			bPhysicsSimulationToggledOn = bPhysicsShouldBeOn;
		}
	}

	void UpdateFrontTransform(float DeltaTime)
	{
		if(FrontPlayer != nullptr && !FrontPlayer.HasControl())
		{
			FVector TargetLocation = CurrentFrontTransform.Location;
			FRotator TargetRotation = CurrentFrontTransform.Rotator();
			GetFirstCollisionSphere().SetWorldLocation(FMath::VInterpTo(GetFirstCollisionSphere().GetWorldLocation(), TargetLocation, DeltaTime, 0.5f));
			GetFirstCollisionSphere().SetWorldRotation(FMath::RInterpTo(GetFirstCollisionSphere().GetWorldRotation(), TargetRotation, DeltaTime, 0.5f));
			FrontPlayer.Mesh.SetWorldRotation(FrontAttachmentPoint.GetWorldRotation());
		}
	}

	void UpdateBackTransform(float DeltaTime)
	{
		if(BackPlayer != nullptr && !BackPlayer.HasControl())
		{
			FVector TargetLocation = CurrentBackTransform.Location;
			FRotator TargetRotation = CurrentBackTransform.Rotator();
			GetLastCollisionSphere().SetWorldLocation(FMath::VInterpTo(GetLastCollisionSphere().GetWorldLocation(), TargetLocation, DeltaTime, 0.5f));
			GetLastCollisionSphere().SetWorldRotation(FMath::RInterpTo(GetLastCollisionSphere().GetWorldRotation(), TargetRotation, DeltaTime, 0.5f));
			BackPlayer.Mesh.SetWorldRotation(BackAttachmentPoint.GetWorldRotation());
		}
	}

	void UpdateForces(FVector2D StickInput, EVacuumMountLocation CurrentMountLocation)
	{
		switch(CurrentMountLocation)
		{
		case EVacuumMountLocation::Front:
			if(FrontPlayer !=nullptr)
			{
				FrontPlayer.Mesh.SetWorldRotation(FrontAttachmentPoint.GetWorldRotation());
				
				FVector HorizontalDirection = MainSplineComponent.GetRightVectorAtSplinePoint(0, ESplineCoordinateSpace::World) * StickInput.X;
				FVector HorizontalForce  = HorizontalDirection * -MaximumFrontForces.HorizontalMax;
				FVector TotalForce = FVector(HorizontalForce.X, HorizontalForce.Y, StickInput.Y * MaximumFrontForces.VerticalMax);

				CurrentFrontForces = TotalForce;
			}
		break;
		case EVacuumMountLocation::Back:
			if(BackPlayer != nullptr)
			{
				BackPlayer.Mesh.SetWorldRotation(BackAttachmentPoint.GetWorldRotation());

				FVector HorizontalDirection = MainSplineComponent.GetRightVectorAtSplinePoint(GetLastMainSplineIndex(), ESplineCoordinateSpace::World) * StickInput.X;
				FVector HorizontalForce  = HorizontalDirection * MaximumBackForces.HorizontalMax;
				FVector TotalForce = FVector(HorizontalForce.X, HorizontalForce.Y, StickInput.Y * MaximumBackForces.VerticalMax);

				CurrentBackForces = TotalForce;
			}
		break;
		}
	}

	void StartFrontTimer()
	{
		FrontTimer = System::SetTimer(this, n"SetFrontForces", 0.1f, true);
	}

	void StopFrontTimer()
	{
		System::ClearAndInvalidateTimerHandle(FrontTimer);
	}

	void StartBackTimer()
	{
		BackTimer = System::SetTimer(this, n"SetBackForces", 0.1f, true);
	}

	void StopBackTimer()
	{
		System::ClearAndInvalidateTimerHandle(BackTimer);
	}

	UFUNCTION()
	void SetFrontForces()
	{
		if(FrontPlayer != nullptr && FrontPlayer.HasControl())
		{
			NetUpdateFrontForces(CurrentFrontForces, GetFirstCollisionSphere().GetWorldTransform());
		}
	}

	UFUNCTION()
	void SetBackForces()
	{
		if(BackPlayer != nullptr && BackPlayer.HasControl())
		{
			NetUpdateBackForces(CurrentBackForces, GetLastCollisionSphere().GetWorldTransform());
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdateFrontForces(FVector Force, FTransform Transform)
	{
		CurrentFrontForces = Force;
		CurrentFrontTransform = Transform;
	}

	UFUNCTION(NetFunction)
	void NetUpdateBackForces(FVector Force, FTransform Transform)
	{
		CurrentBackForces = Force;
		CurrentBackTransform = Transform;
	}

	void ApplyForces()
	{	
		if(GetFirstCollisionSphere().IsSimulatingPhysics() && CurrentFrontForces != FVector::ZeroVector)
		{
			GetFirstCollisionSphere().AddForce(CurrentFrontForces, bAccelChange = true);
		}

		if(GetLastCollisionSphere().IsSimulatingPhysics() && CurrentBackForces != FVector::ZeroVector)
		{
			GetLastCollisionSphere().AddForce(CurrentBackForces, bAccelChange = true);
		}
	}

	TArray<int> SplinePointsAffected;
	bool UpdateHoseSplineRuntime()
	{
		bool bAnyPositionChange = false;
		SplinePointsAffected.Reset(10);

		// Detect if any collision spheres have moved at all
		for (int i = 0; i < StaticRange.Min; ++i)
		{
			FVector Location = CollisionSpheres[i].WorldLocation;
			FVector PrevLocation = MainSplineComponent.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World);
			if (!Location.Equals(PrevLocation, 0.5f))
			{
				MainSplineComponent.SetLocationAtSplinePoint(i, Location, ESplineCoordinateSpace::World, bUpdateSpline = false);
				SplinePointsAffected.AddUnique(i-1);
				SplinePointsAffected.AddUnique(i);
				SplinePointsAffected.AddUnique(i+1);
				bAnyPositionChange = true;
			}
		}

		for (int i = StaticRange.Max, Count = CollisionSpheres.Num(); i < Count; ++i)
		{
			FVector Location = CollisionSpheres[i].WorldLocation;
			FVector PrevLocation = MainSplineComponent.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World);
			if (!Location.Equals(PrevLocation, 0.5f))
			{
				MainSplineComponent.SetLocationAtSplinePoint(i, Location, ESplineCoordinateSpace::World, bUpdateSpline = false);
				SplinePointsAffected.AddUnique(i-1);
				SplinePointsAffected.AddUnique(i);
				SplinePointsAffected.AddUnique(i+1);
				bAnyPositionChange = true;
			}
		}

		// Update the spline only if any points have changed
		if (bAnyPositionChange)
			MainSplineComponent.UpdateSpline();

		// Update spline meshes that would have been affected by the change
		for (int i = 0, Count = SplinePointsAffected.Num(); i < Count; ++i)
		{
			int SplinePoint = SplinePointsAffected[i];
			if (!SplineMeshes.IsValidIndex(SplinePoint))
				continue;

			FVector StartLocation = MainSplineComponent.GetLocationAtSplinePoint(SplinePoint, ESplineCoordinateSpace::Local);
			FVector StartTangent = MainSplineComponent.GetTangentAtSplinePoint(SplinePoint, ESplineCoordinateSpace::Local);
			FVector EndLocation = MainSplineComponent.GetLocationAtSplinePoint(SplinePoint + 1, ESplineCoordinateSpace::Local);
			FVector EndTangent = MainSplineComponent.GetTangentAtSplinePoint(SplinePoint + 1, ESplineCoordinateSpace::Local);

			SplineMeshes[SplinePoint].SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);
		}

		// Update intermediate spheres that would have been affected by the change
		for (int i = 0, Count = SplinePointsAffected.Num(); i < Count; ++i)
		{
			int SplinePoint = SplinePointsAffected[i];
			if (!SplineMeshes.IsValidIndex(SplinePoint))
				continue;

			USphereComponent CollisionSphere = IntermediateCollisionSpheres[SplinePoint];
			CollisionSphere.SetWorldLocation(MainSplineComponent.GetLocationAtDistanceAlongSpline(((CollisionSphere.GetScaledSphereRadius()*SplinePoint)*2) + (CollisionSphereRadius), ESplineCoordinateSpace::World));
		}

		// Update scene components that stuff is attached to
		if (bAnyPositionChange)
			UpdateAttachmentPointPositions();

		return bAnyPositionChange;
	}

	void UpdateMainSpline()
	{
		MainSplineComponent.ClearSplinePoints();

		for (USphereComponent CollisionSphere : CollisionSpheres)
		{
			MainSplineComponent.AddSplinePoint(CollisionSphere.GetWorldLocation(), ESplineCoordinateSpace::World, true);
		}
	}
	
	void UpdateSplineMeshes()
	{       
		for (int Index = 0, Count = SplineMeshes.Num(); Index < Count; ++Index)
		{
			FVector StartLocation = MainSplineComponent.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			FVector StartTangent = MainSplineComponent.GetTangentAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			FVector EndLocation = MainSplineComponent.GetLocationAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);
			FVector EndTangent = MainSplineComponent.GetTangentAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);

			SplineMeshes[Index].SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);
		}
	}

	void UpdateAudioParameters()
	{
		float FrontBlow = FrontVacuumMode == EVacuumMode::Blow ? 1.f : 0.f;
		float BackBlow = FrontVacuumMode == EVacuumMode::Blow ? 0.f : 1.f;

		if (bUseAudioComponents) 
		{
			if(FrontHazeAkComp.IsGameObjectRegisteredWithWwise())
				FrontHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Controllable_BlowOrSuck", FrontBlow);
			if(BackHazeAkComp.IsGameObjectRegisteredWithWwise())
				BackHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Controllable_BlowOrSuck", BackBlow);			
		}

		//Print("Front BlowOrSuck: "+ FrontBlow);
		//Print("Front BlowOrSuck: "+ BackBlow);

		if (IsHoseStatic())
			return;

		FVector FrontVelocity = GetFirstCollisionSphere().GetPhysicsLinearVelocity();
		FVector BackVelocity = GetLastCollisionSphere().GetPhysicsLinearVelocity();

		float FrontNormVelocity = HazeAudio::NormalizeRTPC01(FrontVelocity.Size(), 10.f, 250.f);
		float ClampedFrontVelo = FMath::Clamp(FrontNormVelocity, 0.0f, 1.0f);

		float BackNormVelocity = HazeAudio::NormalizeRTPC01(BackVelocity.Size(), 10.f, 250.f);
		float ClampedBackVelo = FMath::Clamp(BackNormVelocity, 0.0f, 1.0f);
		
		if (bUseAudioComponents) 
		{
			if(FrontHazeAkComp.IsGameObjectRegisteredWithWwise())
				FrontHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Controllable_Velocity", ClampedFrontVelo);
			if(BackHazeAkComp.IsGameObjectRegisteredWithWwise())
				BackHazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Controllable_Velocity", ClampedBackVelo);
		}
		//Print("Front Velo: "+ ClampedFrontVelo);
		//Print("Back Velo: "+ BackVelocity.Size());
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterFrontCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor.HasControl())
		{
			if(ActorsInHose.Contains(Cast<AHazeActor>(OtherActor)) || ActorsAtFrontExhaust.Contains(Cast<AHazeActor>(OtherActor)) || OtherActor == FrontPlayer)
				return;
			
			if(IsActorValidVacuumTarget(OtherActor))
			{	
				NetAddActorToExhaust(Cast<AHazeActor>(OtherActor), EVacuumMountLocation::Front);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterBackCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor.HasControl())
		{
			if(ActorsInHose.Contains(Cast<AHazeActor>(OtherActor)) || ActorsAtBackExhaust.Contains(Cast<AHazeActor>(OtherActor)) || OtherActor == BackPlayer)
				return;

			if(IsActorValidVacuumTarget(OtherActor))
			{
				NetAddActorToExhaust(Cast<AHazeActor>(OtherActor), EVacuumMountLocation::Back);
			}
		}
	}
	
	UFUNCTION(NetFunction)
	void NetAddActorToExhaust(AHazeActor Actor, EVacuumMountLocation ExhaustLocation)
	{
		ExhaustLocation == EVacuumMountLocation::Front ? ActorsAtFrontExhaust.Add(Actor) : ActorsAtBackExhaust.Add(Actor);

		UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(Actor.GetComponentByClass(UVacuumableComponent::StaticClass()));
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player != nullptr)
		{
			//Player.AddCapabilitySheet(ExhaustSheet, EHazeCapabilitySheetPriority::Normal, this);

			// UHazeLocomotionStateMachineAsset HeadWindAsset = Player.IsCody() ? CodyAnimations.HeadWindAsset : MayAnimations.HeadWindAsset;
			// Player.AddLocomotionAsset(HeadWindAsset, this);
		}

		if(VacuumableComponent != nullptr && bLookForVacuumableComponents)
		{
			USceneComponent AttachmentPoint = ExhaustLocation == EVacuumMountLocation::Front ? FrontEntrance : BackEntrance;
			VacuumableComponent.StartVacuuming(AttachmentPoint);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitFrontCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if(OtherActor.HasControl())
		{
			if(!ActorsAtFrontExhaust.Contains(Cast<AHazeActor>(OtherActor)))
				return;

			NetRemoveActorFromExhaust(OtherActor, EVacuumMountLocation::Front);
		}
    }

	UFUNCTION(NotBlueprintCallable)
    void ExitBackCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if(OtherActor.HasControl())
		{
			if(!ActorsAtBackExhaust.Contains(Cast<AHazeActor>(OtherActor)))
				return;

			NetRemoveActorFromExhaust(OtherActor, EVacuumMountLocation::Back);
		}
    }

	UFUNCTION(NetFunction)
	void NetRemoveActorFromExhaust(AActor Actor, EVacuumMountLocation ExhaustLocation)
	{
		ExhaustLocation == EVacuumMountLocation::Front ? ActorsAtFrontExhaust.Remove(Cast<AHazeActor>(Actor)) : ActorsAtBackExhaust.Remove(Cast<AHazeActor>(Actor));

		UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(Actor.GetComponentByClass(UVacuumableComponent::StaticClass()));
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(VacuumableComponent != nullptr)
			VacuumableComponent.EndVacuuming();

		if(Player != nullptr)
		{
			//Player.RemoveCapabilitySheet(ExhaustSheet,this);

			// Player.ClearLocomotionAssetByInstigator(this);
		}
	}

	void MoveActorsAtExhaust(float DeltaTime, UCapsuleComponent Capsule, TArray<AHazeActor> Actors, int SplinePointIndex)
	{
		for (AHazeActor CurrentActor : Actors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurrentActor);
			
			if (Player != nullptr)
			{
				if (Player.IsAnyCapabilityActive(n"Vacuum"))
					return;
				
				UHazeMovementComponent MovementComponent = UHazeMovementComponent::GetOrCreate(Player);

				FVector ConstrainedHorizontalVelocity = Math::ConstrainVectorToPlane(MovementComponent.GetActualVelocity(), MovementComponent.WorldUp);
				float ConstrainedHorizontalVelocitySize = ConstrainedHorizontalVelocity.Size();

				FVector ConstrainedVerticalVelocity = Math::ConstrainVectorToDirection(MovementComponent.GetActualVelocity(), MovementComponent.WorldUp);
				float ConstrainedVerticalVelocitySize = ConstrainedVerticalVelocity.Size();
				float MovementDirection = ConstrainedVerticalVelocity.GetSafeNormal().DotProduct(MovementComponent.WorldUp);

				if(ConstrainedHorizontalVelocitySize > 2000 && MovementDirection > 0)
					return;

				if(ConstrainedHorizontalVelocitySize + ConstrainedVerticalVelocitySize > 2500)
					return;

				if(ConstrainedVerticalVelocitySize > 1500 && MovementDirection > 0)
					return;

				FVector ExhaustLocation = MainSplineComponent.GetLocationAtSplinePoint(SplinePointIndex,ESplineCoordinateSpace::World);
				float DistanceToExhaust = (Player.GetActorLocation() - ExhaustLocation).Size();
				DistanceToExhaust = FMath::Clamp(DistanceToExhaust, 1, DistanceToExhaust);

				float DistanceModifier = (Capsule.GetScaledCapsuleHalfHeight()/DistanceToExhaust);
				FMath::Clamp(DistanceModifier, ExhaustMultiplierRange.Min, ExhaustMultiplierRange.Max);
				
				FVector Force = FVector(MainSplineComponent.GetDirectionAtSplinePoint(SplinePointIndex, ESplineCoordinateSpace::World) * (CurrentForce * DistanceModifier));

				MovementComponent.AddImpulse(FVector(Force * DeltaTime));
			}

			UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(CurrentActor.GetComponentByClass(UVacuumableComponent::StaticClass()));

			if(VacuumableComponent != nullptr)
			{	
				FVector Direction = FVector(MainSplineComponent.GetDirectionAtSplinePoint(SplinePointIndex, ESplineCoordinateSpace::World));
				VacuumableComponent.TickVacuuming(Direction);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterFrontEntrance(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		if(OtherActor.HasControl())
		{
			if(OtherActor == FrontPlayer)
				return;

			if(!ActorsInHose.Contains(Cast<AHazeActor>(OtherActor)) && FrontVacuumMode == EVacuumMode::Suck)
			{
				UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(OtherActor.GetComponentByClass(UVacuumableComponent::StaticClass()));
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

				if((VacuumableComponent !=nullptr && bLookForVacuumableComponents && VacuumableComponent.bCanEnterVacuum) || Player != nullptr)
				{
					ActorsAtFrontExhaust.Remove(Cast<AHazeActor>(OtherActor));
					NetEnterHose(Cast<AHazeActor>(OtherActor), 0, EVacuumMountLocation::Front);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterBackEntrance(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		if(OtherActor.HasControl())
		{
			if(OtherActor == BackPlayer)
				return;

			if(!ActorsInHose.Contains(Cast<AHazeActor>(OtherActor)) && FrontVacuumMode == EVacuumMode::Blow)
			{
				UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(OtherActor.GetComponentByClass(UVacuumableComponent::StaticClass()));
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

				if((VacuumableComponent !=nullptr && bLookForVacuumableComponents && VacuumableComponent.bCanEnterVacuum) || Player != nullptr)
				{
					ActorsAtBackExhaust.Remove(Cast<AHazeActor>(OtherActor));
					NetEnterHose(Cast<AHazeActor>(OtherActor), GetMainSplineLength(), EVacuumMountLocation::Back);
				}
			}
		}
	}
	
	UFUNCTION(NetFunction)
	void NetEnterHose(AHazeActor Actor, float DistanceAlongSpline, EVacuumMountLocation ExhaustLocation)
	{
		FHazePlaySlotAnimationParams SuckInParams;
		SuckInParams.Animation = HoseAnimations.SuckInAnimation;
		SuckInParams.BlendTime = 0.1f;
			
		FHazeAnimationDelegate SuckInDelegate;

		switch(ExhaustLocation)
		{
		case EVacuumMountLocation::Front:
			ActorsAtFrontExhaust.Remove(Cast<AHazeActor>(Actor));
			SuckInDelegate.BindUFunction(this, n"ResumeFrontMH");
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), SuckInDelegate, SuckInParams);
		break;
		case EVacuumMountLocation::Back:
			ActorsAtBackExhaust.Remove(Cast<AHazeActor>(Actor));
			SuckInDelegate.BindUFunction(this, n"ResumeBackMH");
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), SuckInDelegate, SuckInParams);
		break;
		}

		AddBulgingActor(Actor);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player != nullptr)
		{	
			Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
			Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
			float StartDistance = ExhaustLocation == EVacuumMountLocation::Front ? 0.f : GetMainSplineLength();
			Player.SetCapabilityAttributeValue(n"StartDistance", StartDistance);
			Player.SetCapabilityAttributeObject(n"Hose", this);
			Player.SetCapabilityActionState(n"GoingThroughVacuum", EHazeActionState::Active);

			OnEnteredHose.Broadcast(Player);
			return;
		}

		UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(Actor.GetComponentByClass(UVacuumableComponent::StaticClass()));

		if(VacuumableComponent != nullptr)
		{
			ActorsInHose.Add(Actor);
			DistancesInHose.Add(DistanceAlongSpline);
			
			USceneComponent AttachmentPoint = ExhaustLocation == EVacuumMountLocation::Front ? FrontEntrance : BackEntrance;
			VacuumableComponent.EnterVacuum(AttachmentPoint);

			if (bUseAudioComponents && SuckUpObjectEvent != nullptr)
			{
				if (ExhaustLocation == EVacuumMountLocation::Front)
					FrontHazeAkComp.HazePostEvent(SuckUpObjectEvent);
				else
					BackHazeAkComp.HazePostEvent(SuckUpObjectEvent);
			}

			if (ExhaustLocation == EVacuumMountLocation::Front && FrontPlayer != nullptr)
				FrontPlayer.PlayForceFeedback(SuckUpObjectForceFeedback, false, true, n"SuckUpObject");
			else if (ExhaustLocation == EVacuumMountLocation::Back && BackPlayer != nullptr)
				BackPlayer.PlayForceFeedback(SuckUpObjectForceFeedback, false, true, n"SuckUpObject");
		}
	}

	UFUNCTION()
	void ReapplyPointOfInterest(AHazePlayerCharacter Player, FHazePointOfInterest Settings)
	{
		Player.ClearPointOfInterestByInstigator(this);
		if (Settings.FocusTarget.Actor != nullptr)
			Player.ApplyPointOfInterest(Settings, this, EHazeCameraPriority::Maximum);
	}

	void MoveActorsInHose(float DeltaTime)
	{
		if(ActorsInHose.Num() == 0)
			return;

		for (int Index = ActorsInHose.Num() - 1; Index >= 0; --Index)
		{
			AHazeActor Actor = ActorsInHose[Index];

			if(DistancesInHose[Index] > GetMainSplineLength() && FrontVacuumMode == EVacuumMode::Suck && Actor.HasControl())
			{
				NetLaunchActorFromHose(Actor, EVacuumMountLocation::Back, Index);
			}

			else if(DistancesInHose[Index] < 0 && FrontVacuumMode == EVacuumMode::Blow && Actor.HasControl())
			{	
				NetLaunchActorFromHose(Actor, EVacuumMountLocation::Front, Index);
			}

			else
			{
				DistancesInHose[Index] = DistancesInHose[Index] + CurrentSpeedThroughHose * DeltaTime;
				Actor.SetActorLocation(FMath::VInterpTo(Actor.GetActorLocation(), MainSplineComponent.GetLocationAtDistanceAlongSpline(DistancesInHose[Index], ESplineCoordinateSpace::World), DeltaTime, 15.f));

				FVector Dir = MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistancesInHose[Index], ESplineCoordinateSpace::World);
				Dir = Dir.GetSafeNormal();
				FRotator Rot = Math::MakeRotFromZ(Dir);
				Actor.SetActorRotation(FMath::RInterpTo(Actor.GetActorRotation(), Rot, DeltaTime, 15.f));

				UVacuumableComponent VacuumableComp = UVacuumableComponent::Get(Actor);
				if (VacuumableComp != nullptr)
				{
					float AlphaAlongHose = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MainSplineComponent.SplineLength), FVector2D(0.f, 1.f), DistancesInHose[Index]);
					bool bGoingForwards = CurrentSpeedThroughHose > 0.f;

					if (!bGoingForwards)
						AlphaAlongHose = 1.f - AlphaAlongHose;

					VacuumableComp.TickInsideVacuum(AlphaAlongHose);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetLaunchActorFromHose(AHazeActor Actor, EVacuumMountLocation ExhaustLocation, int ActorIndex)
	{
		ActorsInHose.RemoveAtSwap(ActorIndex);
		DistancesInHose.RemoveAtSwap(ActorIndex);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(Actor.GetComponentByClass(UVacuumableComponent::StaticClass()));

		if (Player != nullptr && Player.HasControl())
		{
			Player.SetCapabilityAttributeObject(n"Hose", this);
			Player.SetCapabilityAttributeNumber(n"MountLocation", ExhaustLocation);
			Player.SetCapabilityActionState(n"LaunchedFromVacuum", EHazeActionState::Active);

			ExhaustLocation == EVacuumMountLocation::Front ? ActorsAtFrontExhaust.Add(Actor) : ActorsAtBackExhaust.Add(Actor);

			Player.StopAllCameraShakes(false);
			OnLaunchedFromHose.Broadcast(Player, this, ExhaustLocation);
		}

		else if (VacuumableComponent != nullptr)
		{			
			RemoveBulgingActor(Actor);
			VacuumableComponent.ExitVacuum();
			OnObjectLaunchedFromHose.Broadcast(Actor);

			if (bUseAudioComponents && BlowOutObjectEvent != nullptr)
			{
				if (ExhaustLocation == EVacuumMountLocation::Front)
					FrontHazeAkComp.HazePostEvent(BlowOutObjectEvent);
				else
					BackHazeAkComp.HazePostEvent(BlowOutObjectEvent);
			}

			PlayBlowOutAnimation(ExhaustLocation);
		}
	}
	
	void PlayBlowOutAnimation(EVacuumMountLocation ExhaustLocation)
	{
		if (bStunnedMhLocked)
			return;

		FHazePlaySlotAnimationParams BlowOutParams;
		BlowOutParams.Animation = HoseAnimations.BlowOutAnimation;
		BlowOutParams.BlendTime = 0.1f;
			
		FHazeAnimationDelegate BlowOutDelegate;

		if(ExhaustLocation == EVacuumMountLocation::Front)
		{
			BlowOutDelegate.BindUFunction(this, n"ResumeFrontMH");
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), BlowOutDelegate, BlowOutParams);
		}
		else
		{
			BlowOutDelegate.BindUFunction(this, n"ResumeBackMH");
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), BlowOutDelegate, BlowOutParams);
		}
	}

	UFUNCTION()
	void ResumeFrontMH()
	{
		if (bStunnedMhLocked)
			return;

		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.1f;
		Params.bLoop = true;

		if (FrontVacuumMode == EVacuumMode::Blow)
		{
			Params.Animation = FrontPlayer == nullptr ? HoseAnimations.BlowMH : HoseAnimations.RidingBlowMH;
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		}
		else
		{
			Params.Animation = FrontPlayer == nullptr ? HoseAnimations.SuckMH : HoseAnimations.RidingSuckMH;
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		}
	}

	UFUNCTION()
	void ResumeBackMH()
	{
		if (bStunnedMhLocked)
			return;

		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.1f;
		Params.bLoop = true;

		if (FrontVacuumMode == EVacuumMode::Blow)
		{
			Params.Animation = BackPlayer == nullptr ? HoseAnimations.SuckMH : HoseAnimations.RidingSuckMH;
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		}
		else
		{
			Params.Animation = BackPlayer == nullptr ? HoseAnimations.BlowMH : HoseAnimations.RidingBlowMH;
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		}
	}

	UFUNCTION()
	void ThrowPlayersOffOfHose()
	{
		if (FrontPlayer != nullptr)
		{
			ThrowPlayerOffOfHose(FrontPlayer);
		}

		if (BackPlayer != nullptr)
		{
			ThrowPlayerOffOfHose(BackPlayer);
		}
	}

	UFUNCTION()
	void ThrowPlayerOffOfHose(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityActionState(n"ThrownOffHose", EHazeActionState::Active);
	}

	UFUNCTION()
	void ChangeDirection()
	{
		if(FrontVacuumMode == EVacuumMode::Suck)
		{
			FrontVacuumMode = EVacuumMode::Blow;
			FrontBlowEffect.Activate(true);
			FrontSuckEffect.Deactivate();
			BackBlowEffect.Deactivate();
			BackSuckEffect.Activate(true);
		}
		else
		{
			FrontVacuumMode = EVacuumMode::Suck;
			FrontBlowEffect.Deactivate();
			FrontSuckEffect.Activate(true);
			BackBlowEffect.Activate(true);
			BackSuckEffect.Deactivate();
		}

		//FrontHazeAkComp.HazePostEvent(ChangeBlowOrSuckDirectionEvent);
		//BackHazeAkComp.HazePostEvent(ChangeBlowOrSuckDirectionEvent);

		UpdateArrowDirections();
		UpdateForceDirections();
		DirectionChanged();
		ResumeFrontMH();
		ResumeBackMH();

		if (TargetHub != nullptr)
			TargetHub.ConnectedHoseDirectionChanged();
	}

	UFUNCTION(BlueprintEvent)
	void DirectionChanged()
	{}

	void UpdateForceDirections()
	{
		switch (FrontVacuumMode)
		{
		case EVacuumMode::Suck:
			CurrentForce = DefaultExhaustForce * 1.5f;
			CurrentSpeedThroughHose = DefaultSpeedThroughHose;
		break;
		case EVacuumMode::Blow:
			CurrentForce = DefaultExhaustForce * -1.5f;
			CurrentSpeedThroughHose = DefaultSpeedThroughHose * -1;
		break;
		}
	}

	UFUNCTION()
	void UpdateFaceMH()
	{
		if (bStunnedMhLocked)
			return;

		FHazePlaySlotAnimationParams BlowParams;
		BlowParams.Animation = HoseAnimations.BlowMH;
		BlowParams.BlendTime = 0.1f;
		BlowParams.bLoop = true;

		FHazePlaySlotAnimationParams SuckParams;
		SuckParams.Animation = HoseAnimations.SuckMH;
		SuckParams.BlendTime = 0.1f;
		SuckParams.bLoop = true;

		if (FrontVacuumMode == EVacuumMode::Blow)
		{
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), BlowParams);
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), SuckParams);
		}
		else
		{
			SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), SuckParams);
			SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), BlowParams);
		}
	}

	UFUNCTION()
	void SetStunnedMH(bool bLock = false)
	{
		bStunnedMhLocked = bLock;
		FHazePlaySlotAnimationParams Params;
		Params.Animation = HoseAnimations.StunnedMH;
		Params.bLoop = true;

		SkeletalFrontFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		SkeletalBackFace.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
	}

	UFUNCTION()
	void DisableOverlapEvents()
	{
		FrontCapsule.SetGenerateOverlapEvents(false);
		BackCapsule.SetGenerateOverlapEvents(false);
		FrontEntrance.SetGenerateOverlapEvents(false);
		BackEntrance.SetGenerateOverlapEvents(false);
	}

	UFUNCTION()
	void EnableOverlapEvents()
	{
		FrontCapsule.SetGenerateOverlapEvents(true);
		BackCapsule.SetGenerateOverlapEvents(true);
		FrontEntrance.SetGenerateOverlapEvents(true);
		BackEntrance.SetGenerateOverlapEvents(true);
	}
  
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AddCollisionSpheres();
		UpdateMainSpline();
		AddSplineMeshes();
		UpdateSplineMeshes();
		UpdateCapsulePositions();
		UpdateArrowDirections();
		AddIntermediateCollisionSpheres();
		UpdateAttachmentPointPositions();
		UpdateFaces();
		UpdateEffectVisibility();
		if(!IsHoseStatic())
			AddPhysicsConstraints();
	}

	void AddCollisionSpheres()
	{
		CollisionSpheres.Empty();

		for (int Index = 0, Count = GetNumberOfSpheres() + 1; Index < Count; ++ Index)
		{
			USphereComponent CollisionSphere = USphereComponent(this);
			CollisionSphere.SetSphereRadius(CollisionSphereRadius, false);
			CollisionSphere.SetWorldLocation(RefSplineComponent.GetLocationAtDistanceAlongSpline(((CollisionSphere.GetScaledSphereRadius()*Index)*2), ESplineCoordinateSpace::World));
			CollisionSphere.SetWorldRotation(RefSplineComponent.GetRotationAtDistanceAlongSpline(((CollisionSphere.GetScaledSphereRadius()*Index)*2), ESplineCoordinateSpace::World));
			CollisionSphere.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			CollisionSphere.SetCollisionProfileName(n"PhysicsActor");
			CollisionSphere.SetHiddenInGame(!bShowCollisionSpheres);
			CollisionSphere.SetUseCCD(true);
			CollisionSphere.SetAngularDamping(AngularDamping);
			CollisionSphere.SetLinearDamping(LinearDamping);
			CollisionSphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Ignore);
			CollisionSphere.SetGenerateOverlapEvents(bGenerateOverlapEvents);
			CollisionSphere.RemoveTag(ComponentTags::LedgeGrabbable);
			CollisionSphere.RemoveTag(ComponentTags::Walkable);
			CollisionSphere.SetSimulatePhysics(false);
			if(Index < StaticRange.Min || Index + 1> StaticRange.Max)
			{
				// CollisionSphere.SetSimulatePhysics(true);
			}
			else if(bVisualizeDisabledSpheres)
			{
				UVacuumVisualizerComponent Visualizer = UVacuumVisualizerComponent::Create(this);
				Visualizer.SetVisualizerProperties(CollisionSphere.GetWorldLocation(), CollisionSphereRadius + 25);
			}
			CollisionSphere.SetPhysMaterialOverride(PhysMat);
			CollisionSpheres.Add(CollisionSphere);
		}
	}

	void AddIntermediateCollisionSpheres()
	{
		IntermediateCollisionSpheres.Empty();

		for (int Index = 0, Count = GetNumberOfSpheres(); Index < Count; ++ Index)
		{
			USphereComponent CollisionSphere = USphereComponent(this);
			CollisionSphere.SetSphereRadius(CollisionSphereRadius, false);
			CollisionSphere.SetWorldLocation(RefSplineComponent.GetLocationAtDistanceAlongSpline(((CollisionSphere.GetScaledSphereRadius()*Index)*2) + (CollisionSphereRadius), ESplineCoordinateSpace::World));
			CollisionSphere.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			CollisionSphere.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
			CollisionSphere.SetGenerateOverlapEvents(bGenerateOverlapEvents);
			CollisionSphere.SetHiddenInGame(!bShowCollisionSpheres);
			CollisionSphere.SetVisibility(false);
			CollisionSphere.RemoveTag(ComponentTags::LedgeGrabbable);
			CollisionSphere.RemoveTag(ComponentTags::Walkable);
			IntermediateCollisionSpheres.Add(CollisionSphere);
		}
	}

	void UpdateIntermediateSpheres()
	{
		for (int Index = 0, Count = IntermediateCollisionSpheres.Num(); Index < Count; ++Index)
		{
			USphereComponent CollisionSphere = IntermediateCollisionSpheres[Index];
			CollisionSphere.SetWorldLocation(MainSplineComponent.GetLocationAtDistanceAlongSpline(((CollisionSphere.GetScaledSphereRadius()*Index)*2) + (CollisionSphereRadius), ESplineCoordinateSpace::World));
		}
	}

	void AddSplineMeshes()
	{
		SplineMeshes.Empty();

		for (int Index = 0, Count = GetNumberOfSpheres(); Index < Count; ++ Index)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this);
			SplineMesh.SetStaticMesh(HoseMesh);
			if (bUseShadows)
				SplineMesh.HazeSetShadowPriority(EShadowPriority::GameplayElement);			
			SplineMeshes.Add(SplineMesh);
		}
	}

	void AddPhysicsConstraints()
	{
		PhysicsConstraints.Empty();

		if(CollisionSpheres.Num() == 1)
			return;

		for (USphereComponent CurrentSphere : CollisionSpheres)
		{
			int Index = CollisionSpheres.FindIndex(CurrentSphere);
			if(Index != CollisionSpheres.Num() - 1)
			{
				UPhysicsConstraintComponent PhysicsConstraint = UPhysicsConstraintComponent::Create(this);
				PhysicsConstraint.SetWorldLocation(CurrentSphere.GetWorldLocation());
				PhysicsConstraint.SetConstrainedComponents(CurrentSphere, NAME_None, CollisionSpheres[Index + 1], NAME_None);
				PhysicsConstraint.SetAngularSwing1Limit(EAngularConstraintMotion::ACM_Limited, Swing1Limit);
				PhysicsConstraint.SetAngularSwing2Limit(EAngularConstraintMotion::ACM_Limited, Swing2Limit);
				PhysicsConstraint.SetAngularTwistLimit(EAngularConstraintMotion::ACM_Limited, TwistLimit);

				if(LinearMotionLimit > 0)
				{
				PhysicsConstraint.SetLinearXLimit(ELinearConstraintMotion::LCM_Limited, LinearMotionLimit);
				PhysicsConstraint.SetLinearYLimit(ELinearConstraintMotion::LCM_Limited, LinearMotionLimit);
				PhysicsConstraint.SetLinearZLimit(ELinearConstraintMotion::LCM_Limited, LinearMotionLimit);
				}

				PhysicsConstraints.Add(PhysicsConstraint);
			}
		}
	}

	UFUNCTION()
	void ModifyLinearLimit(float NewLimit)
	{
		for (UPhysicsConstraintComponent CurrentConstraint : PhysicsConstraints)
		{
			CurrentConstraint.SetLinearXLimit(ELinearConstraintMotion::LCM_Limited, NewLimit);
			CurrentConstraint.SetLinearYLimit(ELinearConstraintMotion::LCM_Limited, NewLimit);
			CurrentConstraint.SetLinearZLimit(ELinearConstraintMotion::LCM_Limited, NewLimit);
		}
	}

	void SetupInteractionComponents()
	{
		FrontInteractionComp.OnActivated.AddUFunction(this, n"OnFrontTriggerActivated");
		BackInteractionComp.OnActivated.AddUFunction(this, n"OnBackTriggerActivated");

		if(IsHoseStatic())
		{
			FrontInteractionComp.Disable(n"Invalid");
			BackInteractionComp.Disable(n"Invalid");
			return;
		}

		if(!bFrontMountable)
			FrontInteractionComp.Disable(n"Invalid");

		if(!bBackMountable)
			BackInteractionComp.Disable(n"Invalid");
	}

	UFUNCTION()
	void EnableInteraction(EVacuumMountLocation Location)
	{
		if (Location == EVacuumMountLocation::Front)
			FrontInteractionComp.Enable(n"Invalid");
		else
			BackInteractionComp.Enable(n"Invalid");
	}

	UFUNCTION()
	void DisableInteraction(EVacuumMountLocation Location)
	{
		if (Location == EVacuumMountLocation::Front)
			FrontInteractionComp.Disable(n"Invalid");
		else
			BackInteractionComp.Disable(n"Invalid");
	}

	void UpdateAttachmentPointPositions()
	{
		FTransform FrontTransform = MainSplineComponent.GetTransformAtSplinePoint(0, ESplineCoordinateSpace::World);
		if (!FrontTransform.Location.Equals(FrontAttachmentPoint.WorldLocation, 0.1f))
		{
			FrontAttachmentPoint.SetWorldLocationAndRotation(
				FrontTransform.Location,
				(FrontTransform.Rotation.ForwardVector * -1).ToOrientationRotator()
			);
		}

		FTransform BackTransform = MainSplineComponent.GetTransformAtSplinePoint(GetLastMainSplineIndex(), ESplineCoordinateSpace::World);
		if (!FrontTransform.Location.Equals(BackAttachmentPoint.WorldLocation, 0.1f))
		{
			BackAttachmentPoint.SetWorldLocationAndRotation(BackTransform.Location, BackTransform.Rotator());
		}
	}

	void UpdateFaces()
	{
		SetFaceProperties(FrontHeadType, SkeletalFrontFace, FrontFace, FrontEntrance, FrontCapsule);
		SetFaceProperties(BackHeadType, SkeletalBackFace, BackFace, BackEntrance, BackCapsule);
	}

	void SetFaceProperties(EVacuumHeadType HeadType, UHazeSkeletalMeshComponentBase SkeletalFace, UStaticMeshComponent StaticFace, USphereComponent Entrance, UCapsuleComponent Capsule)
	{
		FVector EntranceOffset;

		switch(HeadType)
		{
		case EVacuumHeadType::Face:
			StaticFace.SetHiddenInGame(true);
			StaticFace.SetVisibility(false);
			SkeletalFace.SetHiddenInGame(false);
			SkeletalFace.SetVisibility(true);
			EntranceOffset = FVector(150.f, 0.f, 0.f);
			Entrance.SetSphereRadius(70.f, false);
			Capsule.SetCapsuleRadius(70.f, false);
			StaticFace.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			SkeletalFace.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		break;

		case EVacuumHeadType::None:
			StaticFace.SetStaticMesh(NoFaceMesh);
			EntranceOffset = FVector(35.f, 0.f, 0.f);
			Entrance.SetSphereRadius(100.f, false);
			Capsule.SetCapsuleRadius(101.f, false);
		break;

		case EVacuumHeadType::Funnel:
			StaticFace.SetStaticMesh(FunnelMesh);
			EntranceOffset = FVector(320.f, 0.f, 0.f);
			if (bSetEntranceSizeAndOffsetAutomatically)
				Entrance.SetSphereRadius(300.f, false);
			Capsule.SetCapsuleRadius(70.f, false);
		break;
		}

		if(HeadType == EVacuumHeadType::None || HeadType == EVacuumHeadType::Funnel)
		{
			StaticFace.SetHiddenInGame(false);
			StaticFace.SetVisibility(true);
			SkeletalFace.SetHiddenInGame(true);
			SkeletalFace.SetVisibility(false);
			StaticFace.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			SkeletalFace.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		
		if (bSetEntranceSizeAndOffsetAutomatically)
			Entrance.SetRelativeLocation(EntranceOffset);
	}

	void UpdateCapsulePositions()
	{
		FrontCapsule.SetCapsuleHalfHeight(FrontCapsuleLength);
		float FrontOffset = ((FrontCapsuleLength - CollisionSphereRadius));
		FrontCapsule.SetRelativeLocation(FVector(FrontOffset, 1.f, 1.f));

		BackCapsule.SetCapsuleHalfHeight(BackCapsuleLength);
		float BackOffset = ((BackCapsuleLength - CollisionSphereRadius));
		BackCapsule.SetRelativeLocation(FVector(BackOffset, 0.f, 0.f));

		FrontCapsule.SetHiddenInGame(!bShowCapsules);
		BackCapsule.SetHiddenInGame(!bShowCapsules);
	}

	void UpdateArrowDirections()
	{
		switch (FrontVacuumMode)
		{
		case EVacuumMode::Suck:
			FrontArrow.SetRelativeRotation(FRotator(-90,0,0));
			BackArrow.SetRelativeRotation(FRotator(90,0,0));
		break;
		case EVacuumMode::Blow:
			FrontArrow.SetRelativeRotation(FRotator(90,0,0));
			BackArrow.SetRelativeRotation(FRotator(-90,0,0));
		break;
		}

		FrontArrow.SetHiddenInGame(!bShowArrows);
		BackArrow.SetHiddenInGame(!bShowArrows);
	}

	void UpdateEffectVisibility()
	{
		if(FrontVacuumMode == EVacuumMode::Blow)
		{
			FrontBlowEffect.SetAutoActivate(true);
			FrontSuckEffect.SetAutoActivate(false);
			BackBlowEffect.SetAutoActivate(false);
			BackSuckEffect.SetAutoActivate(true);
		}
		else
		{
			FrontBlowEffect.SetAutoActivate(false);
			FrontSuckEffect.SetAutoActivate(true);
			BackBlowEffect.SetAutoActivate(true);
			BackSuckEffect.SetAutoActivate(false);
		}

		FVector FrontEffectOffset = FVector::ZeroVector;
		FVector BackEffectOffset = FVector::ZeroVector;

		if(FrontHeadType == EVacuumHeadType::Face)
			FrontEffectOffset = FVector(175.f, 0.f, 0.f);
		if(BackHeadType == EVacuumHeadType::Face)
			BackEffectOffset = FVector(175.f, 0.f, 0.f);

		FrontBlowEffect.SetRelativeLocation(FrontEffectOffset);
		FrontSuckEffect.SetRelativeLocation(FrontEffectOffset);
		BackBlowEffect.SetRelativeLocation(BackEffectOffset);
		BackSuckEffect.SetRelativeLocation(BackEffectOffset);
	}

	UFUNCTION(BlueprintPure)
	float GetRefSplineLength() property
	{
		return RefSplineComponent.GetSplineLength();
	}

	UFUNCTION(BlueprintPure)
	float GetMainSplineLength() property
	{
		return MainSplineComponent.GetSplineLength();
	}

	UFUNCTION(BlueprintPure)
	int GetLastSplineIndex() property
	{
		return RefSplineComponent.GetNumberOfSplinePoints() - 1;
	}

	UFUNCTION(BlueprintPure)
	int GetLastMainSplineIndex() property
	{
		return MainSplineComponent.GetNumberOfSplinePoints() - 1;
	}

	UFUNCTION(BlueprintPure)
	int GetNumberOfSpheres() property
	{
		return (GetRefSplineLength()/CollisionSphereRadius)/2;
	}

	UFUNCTION(BlueprintPure)
	USphereComponent GetFirstCollisionSphere() property
	{
		return CollisionSpheres[0];
	}

	UFUNCTION(BlueprintPure)
	USphereComponent GetLastCollisionSphere() property
	{
		return CollisionSpheres[CollisionSpheres.Num() - 1];
	}

	UFUNCTION(BlueprintPure)
	bool IsHoseStatic()
	{
		if(StaticRange.Min == 0 && StaticRange.Max >= CollisionSpheres.Num())
			return true;
		else
			return false;
	}

	bool IsActorValidVacuumTarget(AActor Actor)
	{
		if (Cast<AHazePlayerCharacter>(Actor) != nullptr)
			return true;

		UVacuumableComponent VacuumableComponent = Cast<UVacuumableComponent>(Actor.GetComponentByClass(UVacuumableComponent::StaticClass()));

		if (VacuumableComponent != nullptr && VacuumableComponent.bAffectedByVacuum)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	FVector GetDirectionAtStartPoint() property
	{
		return MainSplineComponent.GetDirectionAtSplinePoint(0, ESplineCoordinateSpace::World) * -1;
	}

	UFUNCTION(BlueprintPure)
	FVector GetDirectionAtEndPoint() property
	{
		return MainSplineComponent.GetDirectionAtSplinePoint(GetLastMainSplineIndex(), ESplineCoordinateSpace::World);
	}
}

enum EVacuumMountLocation
{
	Front,
	Back
}

struct FStaticRange
{
	UPROPERTY()
	int Min;

	UPROPERTY()
	int Max;
}

struct FVacuumControlMaximumForces
{
	UPROPERTY()
	float HorizontalMax;
	
	UPROPERTY()
	float VerticalMax;
}

enum EVacuumHeadType
{
	Face,
	None,
	Funnel
}


class UVacuumVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UVacuumVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UVacuumVisualizerComponent Comp = Cast<UVacuumVisualizerComponent>(Component);
        if (Comp == nullptr)
            return;

		DrawWireCapsule(Comp.VisualizerLocation, FRotator::ZeroRotator, FLinearColor::Black, Comp.SphereRadius, Comp.SphereRadius, 16, 5.f);
    }
}

class UVacuumVisualizerComponent : UActorComponent
{
	float SphereRadius;
	FVector VisualizerLocation;

	UFUNCTION()
	void SetVisualizerProperties(FVector Location, float CollisionSphereRadius)
	{
		SphereRadius = CollisionSphereRadius;
		VisualizerLocation = Location;
	}
}