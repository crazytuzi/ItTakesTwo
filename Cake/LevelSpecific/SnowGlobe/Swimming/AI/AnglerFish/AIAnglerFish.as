import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Movement.FishMovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.FishCommon;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Animation.FishAnimationComponent;
import Cake.LevelSpecific.Snowglobe.Swimming.AI.AnglerFish.Audio.FishAudioComponent;
import Vino.Animations.PoseTrailComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;

event void FFishEvent();

UCLASS(Abstract)
class AAIAnglerFish : AHazeCharacter
{
	// Don't hide on camera overlap, we'll hide the fish when it's eating us!
	default CapsuleComponent.ComponentTags.Remove(ComponentTags::HideOnCameraOverlap);

	// This will make this not disabled during the disabled phase on the actor
	default Mesh.bUseDisabledTickOptimizations = true;
	default Mesh.DisabledVisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	default CapsuleComponent.SetCollisionProfileName(n"WaspNPC");
	default CapsuleComponent.bGenerateOverlapEvents = false;

	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = "RootComponent")
	USphereComponent MovementCollision;
	default MovementCollision.bGenerateOverlapEvents = false;
	default MovementCollision.SphereRadius = 2000.f;
	default MovementCollision.RelativeLocation = FVector(1200.f, 0.f, 0.f);
	default MovementCollision.SetCollisionProfileName(n"WaspNPC");

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent) 
	UFishMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIFishDefaultMovementSettings;	
	default MovementComponent.ControlSideDefaultCollisionSolver = n"AIFishCharacterSolver";
	default MovementComponent.RemoteSideDefaultCollisionSolver = n"AIFishCharacterRemoteSolver";
	default MovementComponent.bDepenetrateOutOfOtherMovementComponents = false;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
    UFishBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = nullptr;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UFishAnimationComponent AnimationComponent;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UFishEffectsComponent EffectsComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent VisualBoarder;
	default VisualBoarder.bGenerateOverlapEvents = false;

	// Fish cave is about 46000 units in diameter, though the fish keeps a few thousand units distance to the walls.
	// We never want the fish to be disabled while the players are at a wrench station, which is about 35000 units at most to the walls.
	UPROPERTY(DefaultComponent, Attach = Root)
	USnowGlobeLakeDisableComponentExtension DisableComponentExtension;
	default DisableComponentExtension.ActiveType = ESnowGlobeLakeDisableType::ActiveUnderSurfaceInWater;
	default DisableComponentExtension.DisableRange = FHazeMinMax(35000.f, 50000.f); 
	default DisableComponentExtension.ViewRadius = 1500.f;
	default DisableComponentExtension.DontDisableWhileVisibleTime = 1.f;
	default DisableComponentExtension.TickDelay = 0.f;
	default DisableComponentExtension.BoxVisualizer = VisualBoarder;

	UPROPERTY(DefaultComponent)
	UFishAudioComponent AudioComp;

	UPROPERTY(DefaultComponent)
	UPoseTrailComponent PoseTrail;
	default PoseTrail.Interval = 500.f;
	default PoseTrail.BoneInterpolationSpeed = 1.f;

	UPROPERTY(Category = "AnglerFish")
	FFishEvent FishSafe;

	UPROPERTY(Category = "AnglerFish")
	FFishEvent FishDetect;

	UPROPERTY(Category = "AnglerFish")
	FFishEvent FishAttack;

	bool bFleeing = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(MovementCollision);

		AddCapability(n"FishUpdateBehaviourStateCapability");
		AddCapability(n"FishSwimmingMovementCapability");
		AddCapability(n"FishSwimAlongSplineMovementCapability");
 		AddCapability(n"FishSelectTargetCapability");
		AddCapability(n"FishTrackTargetCapability");
		AddCapability(n"FishPushAwaySwimmersCapability");
		AddCapability(n"FishTryToEatPlayerCapability");
		AddCapability(n"FishPoseTrailCapability");
		AddCapability(n"FishVOPlayerBarksCapability");

        AddCapability(n"FishBehaviourRoamCapability");
        AddCapability(n"FishBehaviourInvestigateCapability");        
        AddCapability(n"FishBehaviourRecoverCapability");
        AddCapability(n"FishBehaviourPrepareBlindChargeCapability");
		AddCapability(n"FishBehaviourAttackBlindChargeCapability");
		AddCapability(n"FishBehaviourFleeAlongSplineCapability");
		AddCapability(n"FishEffectUpdateCapability");
		
		if(Network::IsNetworked() && Game::IsEditorBuild())
			AddDebugCapability(n"AISkeletalMeshNetworkVisualizationCapability");

		EffectsComp.OnSwitchMode.AddUFunction(this, n"OnSwitchEffectsMode");	
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		CrumbComponent.SetCrumbDebugActive(this, false);
    }

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const 
	{
		return ActorLocation;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSwitchEffectsMode(EFishEffectsMode Mode)
	{
		switch (Mode)
		{
			case EFishEffectsMode::Attack:
				FishAttack.Broadcast();
				FishDetect.Broadcast();
				return;
			case EFishEffectsMode::Searching:
				FishDetect.Broadcast();
				return;
			case EFishEffectsMode::Idle:
			case EFishEffectsMode::None:
				FishSafe.Broadcast();
				return;
		}
	}

	UFUNCTION()
	void FleeAlongSpline(ASplineActor Spline)
	{
		// Flee once we're in full screen, pause until then
		BehaviourComponent.SetState(EFishState::None);
		BehaviourComponent.FleeingSplines.Insert(Spline, 0);
		System::SetTimer(this, n"FleeIfFullScreen", 1.f, false);
		bFleeing = true;

		// We'll disable ourselves when at end of spline, don't disable before that!
		BehaviourComponent.bAllowDisable = false;
		DisableComponentExtension.SetComponentTickEnabled(false);
		DisableComp.SetUseAutoDisable(false);	
	}

	UFUNCTION(NotBlueprintCallable)
	void FleeIfFullScreen()
	{
		if (SceneView::IsFullScreen())
			BehaviourComponent.Flee();
		else
			System::SetTimer(this, n"FleeIfFullScreen", 0.5f, false);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Disallow disabling when starting to flee above, then re-allow it from FleeAlongSpline behaviour when at end of spline
		if (!BehaviourComponent.bAllowDisable)
			return true;

		if (bFleeing)
		{
			// Fish mesh won't be disabled fully due to bUseDisabledTickOptimizations
			Mesh.SetHiddenInGame(true);
			Mesh.SetComponentTickEnabled(false);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		return false;
	}

#if EDITOR
	bool bTestingEffects = false;
	void TestEffects()
	{
		if (!bTestingEffects)
			BlockCapabilities(n"FishBehaviour", this);		
		bTestingEffects = true;
	}

	UFUNCTION(DevFunction)
	void TestFishEffects_Idle()
	{
		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		TestEffects();
	}

	UFUNCTION(DevFunction)
	void TestFishEffects_Searching()
	{
		EffectsComp.SetEffectsMode(EFishEffectsMode::Searching);
		TestEffects();
	}

	UFUNCTION(DevFunction)
	void TestFishEffects_Attack()
	{
		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);
		TestEffects();
	}

	UFUNCTION(DevFunction)
	void TestFishEffects_Resume()
	{
		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		if (bTestingEffects)
			UnblockCapabilities(n"FishBehaviour", this);	
		bTestingEffects = false;
	}
#endif
};
