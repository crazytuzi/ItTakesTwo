import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspBombSlotComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspBomberTeam;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.Weapons.Sap.SapCustomAttachComponent;

UCLASS(Abstract)
class AAIBomberWasp : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hips")
	USapCustomAttachComponent SapAttach;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent) 
	UWaspMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIWaspDefaultMovementSettings;
   	default CapsuleComponent.SetCollisionProfileName(n"WaspNPC");

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchResponseComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
    UWaspBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_DefaultSettings_BomberWasp.DA_DefaultSettings_BomberWasp");

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspHealthComponent HealthComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspAnimationComponent AnimComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspEffectsComponent EffectsComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

    UPROPERTY(DefaultComponent, Attach = Mesh)
    UWaspBombSlotComponent BombSlotComp;
    default BombSlotComp.RelativeLocation = FVector(40.f,0.f,20.f);

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

    // Triggers when we die
	UPROPERTY(Category = "Wasp Events")
	FWaspOnDie OnDie;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

        JoinTeam(n"WaspBomberTeam", UWaspBomberTeam::StaticClass());

		AddCommonWaspCapabilities(this);

        AddCapability(n"WaspBehaviourFollowSplineCapability");
        AddCapability(n"WaspBehaviourFindTargetCapability");
        AddCapability(n"WaspBehaviourEngageCapability");
        AddCapability(n"WaspBehaviourGentlemanCircleCapability");
        AddCapability(n"WaspBehaviourPrepareAttackCapability");
        AddCapability(n"WaspBehaviourTauntCapability");
        AddCapability(n"WaspBehaviourAttackBombRunCapability");
        AddCapability(n"WaspBehaviourRecoverCapability");
        AddCapability(n"WaspBehaviourPostAttackPauseCapability");
        AddCapability(n"WaspBehaviourStunnedCapability");
        AddCapability(n"WaspBehaviourFlyAwayCapability");
		AddCapability(n"WaspBehaviourFleeAlongSplineCapability");

		SetupCommonWaspDelegates(this);

		HazeAkComp.HazePostEvent(StartFlyingEvent);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        LeaveTeam(n"WaspBomberTeam");       
    }

	UFUNCTION(NotBlueprintCallable)
	private void OnDied(AHazeActor Wasp)
	{
		OnDie.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		HazeAkComp.HazePostEvent(StartFlyingEvent);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		HazeAkComp.HazePostEvent(StopFlyingEvent);
		return false;
	}
};
