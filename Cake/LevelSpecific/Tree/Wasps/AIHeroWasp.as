import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Peanuts.Disable.TriggeredEnableComponent;
import Peanuts.Audio.AudioStatics;
import Cake.Weapons.Sap.SapCustomAttachComponent;

UCLASS(Abstract, hideCategories="StartingAnimation Animation Mesh Materials Physics Collision Activation Lighting Shape Navigation Character Clothing Replication Rendering Cooking Input Actor LOD AssetUserData")
class AAIHeroWasp : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hips")
	USapCustomAttachComponent SapAttach;
	default SapAttach.bSapHidden = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent) 
	UWaspMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIWaspDefaultMovementSettings;
	default MovementComponent.ControlSideDefaultCollisionSolver = n"WaspFlyingCollisionSolver";
	default MovementComponent.RemoteSideDefaultCollisionSolver = n"WaspFlyingCollisionSolver";
   	default CapsuleComponent.SetCollisionProfileName(n"WaspNPC");

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchResponseComp;

    UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UWaspBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_DefaultSettings_HeroWasp.DA_DefaultSettings_HeroWasp");

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspAnimationComponent AnimComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspHealthComponent HealthComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspEffectsComponent EffectsComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UDecalComponent AttackDecal;
	default AttackDecal.DecalMaterial = Asset("/Game/Environment/Decals/Gameplay/Decal_RedArrow2.Decal_RedArrow2");
	default AttackDecal.bVisible = false;
	default AttackDecal.bDestroyOwnerAfterFade = false; 

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTriggeredEnableComponent TriggeredEnableComponent;

	// With lots of wasps this can spam network and we don't use it for anything important currently
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactCallbacksComp;
	default ImpactCallbacksComp.bCanBeActivedLocallyOnTheRemote = true; 

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathExploEvent;

    // Triggers when we die
	UPROPERTY(Category = "Wasp Events")
	FWaspOnDie OnDie;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

		AddCommonWaspCapabilities(this);
		AddCapability(n"WaspAttackRunCapability");
		AddCapability(n"WaspEnemyIndicatorCapability");
		AddCapability(n"WaspVOEffortsCapability");
		AddCapability(n"WaspVOPlayerBarksCapability");

        AddCapability(n"WaspBehaviourFindTargetCapability");
        AddCapability(n"WaspBehaviourFollowSplineCapability");
		AddCapability(n"WaspBehaviourEntryScenepointCapability");
        AddCapability(n"WaspBehaviourEngageCapability");
        AddCapability(n"WaspBehaviourGentlemanCircleCapability");
        AddCapability(n"WaspBehaviourPrepareAttackCapability");
        AddCapability(n"WaspBehaviourTauntCapability");
        AddCapability(n"WaspBehaviourAttackSwoopCapability");
        AddCapability(n"WaspBehaviourRecoverCapability");
        AddCapability(n"WaspBehaviourQuickAttackRecoverCapability");
        AddCapability(n"WaspBehaviourStunnedCapability");
        AddCapability(n"WaspBehaviourFlyAwayCapability");
		AddCapability(n"WaspBehaviourFleeAlongSplineCapability");
		AddCapability(n"WaspBehaviourSpottedEnemyTauntCapability");

		SetupCommonWaspDelegates(this);

		HazeAkComp.HazePostEvent(StartFlyingEvent);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		CrumbComponent.SetCrumbDebugActive(this, false);
    }

	UFUNCTION(NotBlueprintCallable)
	private void OnDied(AHazeActor Wasp)
	{
		OnDie.Broadcast(this);
		UHazeAkComponent::HazePostEventFireForget(DeathExploEvent, GetActorTransform());
		HazeAkComp.HazePostEvent(StopFlyingEvent);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		HazeAkComp.HazePostEvent(StopFlyingEvent);
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		HazeAkComp.HazePostEvent(StartFlyingEvent);
	}
};

