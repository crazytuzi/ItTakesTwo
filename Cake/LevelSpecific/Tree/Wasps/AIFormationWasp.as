import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;
import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Cake.Weapons.Sap.SapCustomAttachComponent;
UCLASS(Abstract)
class AAIFormationWasp : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hips")
	USapCustomAttachComponent SapAttach;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent) 
	UWaspMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIWaspDefaultMovementSettings;
	default MovementComponent.ControlSideDefaultCollisionSolver = n"WaspFlyingCollisionSolver";
	default MovementComponent.RemoteSideDefaultCollisionSolver = n"WaspFlyingCollisionSolver";
   	default CapsuleComponent.SetCollisionProfileName(n"NoCollision");

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchResponseComp;

	// Behaviour component which allows for local simulation, see BeginPlay below
    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
    UWaspLocalBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_DefaultSettings_FormationWasp.DA_DefaultSettings_FormationWasp");

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspHealthComponent HealthComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspAnimationComponent AnimComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspEffectsComponent EffectsComp;

	// With lots of wasps this can spam network and we don't use it for anything important currently
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactCallbacksComp;
	default ImpactCallbacksComp.bCanBeActivedLocallyOnTheRemote = true; 

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathExploEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	default HazeAkComp.bUseAutoDisable = false;

	private FHazeAudioEventInstance FlyingEventInstance;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UDecalComponent AttackDecal;
	default AttackDecal.DecalMaterial = Asset("/Game/Environment/Decals/Gameplay/Decal_RedArrow2.Decal_RedArrow2");
	default AttackDecal.bVisible = false;
	default AttackDecal.bDestroyOwnerAfterFade = false; 

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UPlaneLockUserComponent PlaneLockComp;

    // Triggers when we die
	UPROPERTY(Category = "Wasp Events")
	FWaspOnDie OnDie;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

		// Locally simulated behaviour only; formation wasps move in predetermined patterns
		// and when we have a lot of them we don't want to spam the network with lost of 
		// behaviour crumb activations/deactivations (as they tend to switch states frequently). 
		// We only net sync spawning (through wasp spawner) and disabling (in flee capability).
		// Also any hits, but that is handled on the hit player crumb component.

		AddCapability(n"WaspUpdateBehaviourStateCapability"); // Local simulation
		AddCapability(n"WaspLocalFlyingMovementCapability"); // Both movement and rotation locally simulated
		AddCapability(n"WaspDeathCapability"); // Replicates using crumbs, which is ok since we won't be leaving movement crumbs
		AddCapability(n"WaspThreeShotAnimationCapability");
		AddCapability(n"WaspSingleAnimationCapability");
		AddCapability(n"WaspPlaneLockCapability");
		AddCapability(n"WaspWeaponSpinnerCapability");
		AddCapability(n"WaspLocalAttackRunCapability");
		AddCapability(n"WaspVOEffortsCapability");

        AddCapability(n"WaspBehaviourFormationStartCapability");
        AddCapability(n"WaspBehaviourFormationCombatPositioningCapability");
        AddCapability(n"WaspBehaviourFormationPrepareAttackCapability");
        AddCapability(n"WaspBehaviourFormationAttackCapability");
        AddCapability(n"WaspBehaviourFormationRecoverCapability");
        AddCapability(n"WaspBehaviourFormationFleeCapability");

		SetupCommonWaspDelegates(this);
		FlyingEventInstance = HazeAkComp.HazePostEvent(StartFlyingEvent);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		CrumbComponent.SetCrumbDebugActive(this, false);

		if(HazeAkComp.EventInstanceIsPlaying(FlyingEventInstance))
		{
			HazeAkComp.HazeStopEvent(FlyingEventInstance.PlayingID);
		}
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
