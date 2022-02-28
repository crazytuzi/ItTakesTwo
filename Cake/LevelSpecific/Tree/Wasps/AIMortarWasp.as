import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspMortarTeam;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspMortarComponent;
import Peanuts.Disable.TriggeredEnableComponent;
import Peanuts.Audio.AudioStatics;
import Cake.Weapons.Sap.SapCustomAttachComponent;

UCLASS(Abstract)
class AAIMortarWasp : AHazeCharacter
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

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
    UWaspBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_DefaultSettings_MortarWasp.DA_DefaultSettings_MortarWasp");

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspHealthComponent HealthComp;
	default HealthComp.CustomSapMaterialIndex = 4;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspAnimationComponent AnimComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspEffectsComponent EffectsComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTriggeredEnableComponent TriggeredEnableComponent;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UWaspMortarComponent MortarComp;

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

	UPROPERTY()
	TArray<USkeletalMesh> ArmourVariants;

    // Triggers when we die
	UPROPERTY(Category = "Wasp Events")
	FWaspOnDie OnDie;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

        UWaspMortarTeam Team = Cast<UWaspMortarTeam>(JoinTeam(n"WaspMortarTeam", UWaspMortarTeam::StaticClass())); 

		AddCommonWaspCapabilities(this);
        AddCapability(n"WaspMortarCapability");
		AddCapability(n"WaspEnemyIndicatorCapability");
		AddCapability(n"WaspIntensifyAggressionCapability");

        AddCapability(n"WaspBehaviourFollowSplineCapability");
        AddCapability(n"WaspBehaviourFindTargetCapability");
		AddCapability(n"WaspBehaviourEntryScenepointCapability");
        AddCapability(n"WaspBehaviourCombatPositioningCapability");
        AddCapability(n"WaspBehaviourEngageCapability");
        AddCapability(n"WaspBehaviourGentlemanCircleCapability");
        AddCapability(n"WaspBehaviourPrepareAttackCapability");
        AddCapability(n"WaspBehaviourAttackStrafeShootCapability");
        AddCapability(n"WaspBehaviourRecoverCapability");
        AddCapability(n"WaspBehaviourPostAttackPauseCapability");
        AddCapability(n"WaspBehaviourStunnedCapability");
        AddCapability(n"WaspBehaviourFlyAwayCapability");
		AddCapability(n"WaspBehaviourFleeAlongSplineCapability");
		AddCapability(n"WaspBehaviourMortarIntroTauntCapability"); 

		SetupCommonWaspDelegates(this);

		HazeAkComp.HazePostEvent(StartFlyingEvent);

        // Start perception
		// PerceptionComponent.SetComponentEnabled(true);
		// PerceptionComponent.SetSensingInterval(0.2f);

		if (HasControl())
		{
			USkeletalMesh Armour = Team.SelectArmourVariant(ArmourVariants);
			if (Armour != nullptr)
				NetSetArmourVariant(Armour);
		}
		HealthComp.ArmourComp = Cast<USkinnedMeshComponent>(AnimComp.ArmourComp);
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetArmourVariant(USkeletalMesh Armour)
	{
		USkinnedMeshComponent ArmourComp = Cast<USkinnedMeshComponent>(AnimComp.ArmourComp);
		if (ArmourComp != nullptr)
			ArmourComp.SetSkeletalMesh(Armour);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        LeaveTeam(n"WaspMortarTeam");       
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
