import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspMovementComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspCommon;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspShieldTeam;
import Peanuts.Disable.TriggeredEnableComponent;
import Peanuts.Audio.AudioStatics;
import Cake.Weapons.Sap.SapCustomAttachComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;

UCLASS(Abstract, hideCategories="StartingAnimation Animation Mesh Materials Physics Collision Activation Lighting Shape Navigation Character Clothing Replication Rendering Cooking Input Actor LOD AssetUserData")
class AAIShieldWasp : AHazeCharacter
{
	default bAdaptCapsuleHeightOffsetToSize = false;

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
	default SapResponseComp.bEnableSapAutoAim = false;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchResponseComp;

    UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UWaspBehaviourComponent BehaviourComponent;
	default BehaviourComponent.DefaultSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Wasps/DA_DefaultSettings_HeroWasp.DA_DefaultSettings_HeroWasp");

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

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hips")
	USapCustomAttachComponent SapAttach;
	default SapAttach.bSapHidden = true;

	UPROPERTY(DefaultComponent, Attach = SapAttach)
	UAutoAimTargetComponent MatchAutoAimComp;
	default MatchAutoAimComp.SetAutoAimEnabled(false);
	default MatchAutoAimComp.AffectsPlayers = EHazeSelectPlayer::May;
	default MatchAutoAimComp.AutoAimMaxAngle = 10.f;

	UPROPERTY(DefaultComponent, Attach = SapAttach)
	USapAutoAimTargetComponent SapAutoAimComp;
	default SapAutoAimComp.SetAutoAimEnabled(false);
	default SapAutoAimComp.AffectsPlayers = EHazeSelectPlayer::Cody;
	default SapAutoAimComp.AutoAimMaxAngle = 10.f;
	default SapAutoAimComp.TargetRadius = 0.f;
	default SapAutoAimComp.HighlightMode = ESapAutoAimHighlightMode::None;

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
	TArray<UStaticMesh> ShieldVariants;

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
		AddCapability(n"WaspWeaponSpinnerCapability");
		AddCapability(n"WaspIntensifyAggressionCapability");
		AddCapability(n"WaspVOPlayerShieldWaspBarksCapability");

		AddCapability(n"WaspBehaviourEntryScenepointCapability");
        AddCapability(n"WaspBehaviourFollowSplineCapability");
        AddCapability(n"WaspBehaviourFindTargetCapability");
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

		// When switching to homing projectiles, sheet should add
		// - WaspHomingProjectileLauncherCapability
		// - WaspBehaviourAttackStrafeShootCapability (or other suitable shooting attack manouver)
		// and block (tag "AttackRun")
		// - WaspAttackRunCapability
		// - WaspBehaviourAttackSwoopCapability

		SetupCommonWaspDelegates(this);

		HazeAkComp.HazePostEvent(StartFlyingEvent);

        UWaspShieldTeam Team = Cast<UWaspShieldTeam>(JoinTeam(n"WaspShieldTeam", UWaspShieldTeam::StaticClass())); 
		if (HasControl())
		{
			UStaticMesh Shield = Team.SelectShieldVariant(ShieldVariants);
			if (Shield != nullptr)
				NetSetShieldVariant(Shield);
		}
		HealthComp.ArmourComp = Cast<USkinnedMeshComponent>(AnimComp.ArmourComp);
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetShieldVariant(UStaticMesh Shield)
	{
		UStaticMeshComponent ShieldComp = Cast<UStaticMeshComponent>(AnimComp.ShieldComp);
		if (ShieldComp != nullptr)
			ShieldComp.SetStaticMesh(Shield);
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
	void Tick(float DeltaTime)
	{
		UpdateSappability(IsSappable());
		UpdateMatchability(IsMatchable());
	}

	void UpdateSappability(bool bSappable)
	{
		// We won't make us compoletely unsappable, or blobs in the air which should strike might fail and vice versa.
		SapAutoAimComp.SetAutoAimEnabled(bSappable);
	}

	void UpdateMatchability(bool bMatchable)
	{
		MatchAutoAimComp.SetAutoAimEnabled(bMatchable);
		if (AnimComp.ShieldComp != nullptr)
		{
			if (bMatchable)
				AnimComp.ShieldComp.RemoveTag(ComponentTags::BlockAutoAim);
			else
				AnimComp.ShieldComp.AddTag(ComponentTags::BlockAutoAim);
		}
		if (!bMatchable)
			UWaspComposableSettings::SetIgniteAttachedSapRadius(this, 0.f, this, EHazeSettingsPriority::Override);
		else	
			ClearSettingsByInstigator(this);
	}

	bool IsSappable()
	{
		if (BehaviourComponent.State == EWaspState::Recover)
			return true;

		FVector ToCodyDir = (Game::GetCody().ActorLocation - ActorLocation).GetSafeNormal();
		if (ActorForwardVector.DotProduct(ToCodyDir) > 0.76f) // ~30 degrees
			return false;

		return true;
	}

	bool IsMatchable()
	{
		if (HealthComp.SapMass == 0)
			return false;

		if (BehaviourComponent.State == EWaspState::Recover)
			return true;

		FVector ToMayDir = (Game::GetMay().ActorLocation - ActorLocation).GetSafeNormal();
		if (ActorForwardVector.DotProduct(ToMayDir) > 0.76f) // ~30 degrees
			return false;

		return true;
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
