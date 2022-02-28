import Cake.LevelSpecific.Tree.Queen.QueenVictimComponent;
import Cake.LevelSpecific.Tree.Queen.QueenBehaviourComponent;
import Cake.LevelSpecific.Tree.Queen.QueenSettings;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Queen.ThrowPlayerIntoArenaActor;
import Cake.LevelSpecific.Tree.Queen.QueenArmorComponentHandler;
import Cake.LevelSpecific.Tree.Queen.QueenHealthBarComponent;
import Cake.LevelSpecific.Tree.Queen.ParkingSpot.QueenParkingSpotComponent;
import Cake.LevelSpecific.Tree.Queen.GrabSpline.QueenGrabSplinePosComponent;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspGrindSplineBlocker.WasGrindBlockerComponent;
import Vino.Movement.Grinding.GrindSpline;
import Cake.LevelSpecific.Tree.Queen.QueenAnimData;
import Cake.LevelSpecific.Tree.Queen.QueenFacingComponent;

event void FQueenOnDieEvent();
event void FQueenOnSpecialAttackDone(UActorComponent SpecialAttack);
event void FQueenOnDamageTakenEvent(FVector HitLocation, USceneComponent HitComponent, FName HitSocket,	float DamageTaken);
enum EQueenPhaseEnum
{
	Phase1,
	Phase2,
	Phase3
};

UCLASS(abstract, HideCategories = "Activation Replication Input Cooking LOD Actor")
class AQueenActor : AHazeActor
{
	UPROPERTY()
	bool bAllowSpecialAttacks = false;

	bool bAllowWaspSpawning = true;

	UPROPERTY()
	int QueenSpecialAttackIndex = 0;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UQueenGrabSplinePosComponent GrabSplinePosComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncQueenRotation;

	UPROPERTY(DefaultComponent)
	UQueenAnimData AnimData;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UQueenFacingComponent FacingComp;

	UPROPERTY()
	EQueenPhaseEnum QueenPhase;

	UPROPERTY()
	AHazeActor RespawnLocation;

	UPROPERTY()
	ASwarmActor RailBlockerSwarmLeft;

	UPROPERTY()
	ASwarmActor RailBlockerSwarmRight;

	UPROPERTY()
	AHazeActor OverrideLookatPosition;

	UPROPERTY()
	AVolume BehindQueenArea;

	UPROPERTY()
	AVolume InFrontOfQueenArea;

	UPROPERTY()
	AGrindspline GrindSpline;

	UPROPERTY(Category = "Settings")
	UQueenSettings Phase1Settings;

	UPROPERTY(Category = "Settings")
	UQueenSettings Phase2Settings;

	UPROPERTY(Category = "Settings")
	UQueenSettings Phase3Settings;

	UPROPERTY(Category = "Settings")
	UQueenSettings SpawnNoWaspsSettings;

	// Used in the beginning of P3; when we only want 1 swarm active, 
	// until the player realizes where the armorComp is.
	UPROPERTY(Category = "Settings")
	UQueenSettings Phase3IntroSettings;

	UPROPERTY()
	AThrowPlayerIntoArena ThrowCodyIntoArenaActor;

	UPROPERTY()
	AThrowPlayerIntoArena ThrowMayIntoArenaActor;

	UPROPERTY()
	AHazeActor LookatQueenAfterSpecialAttackActor;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FoghornBank;

	UFUNCTION()
	void StopBossSpawning()
	{
		SetCapabilityActionState(n"SpawnNoWasps", EHazeActionState::Active);
		ApplySettings(SpawnNoWaspsSettings, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION()
	void ResumeBossSpawning()
	{
		if (bAllowWaspSpawning)
		{
			SetCapabilityActionState(n"SpawnNoWasps", EHazeActionState::Inactive);
			ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION()
	void PushP3IntroSettings()
	{
		ensure(Phase3IntroSettings != nullptr);
		ApplySettings(Phase3IntroSettings, this, EHazeSettingsPriority::Override);
	}
	void PopP3IntroSettings()
	{
		ClearSettingsByInstigator(this);
	}

	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.BodyInstance.COMNudge = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent HitResponseComp;

	UPROPERTY(DefaultComponent)
	UQueenBehaviourComponent BehaviourComp;

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

	UPROPERTY(DefaultComponent)
	UQueenVictimComponent VictimComp;

	UPROPERTY(DefaultComponent)
	UQueenArmorComponentHandler ArmorComponentHandler;

	UPROPERTY(DefaultComponent)
	UQueenParkingSpotComponent ParkingSpotComp;

	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FQueenOnDamageTakenEvent OnDamageTaken;

	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FQueenOnDamageTakenEvent OnArmourTakenDamage;

	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FQueenOnSpecialAttackDone OnSpecialAttackDone;

	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FQueenOnSpecialAttackDone OnSpecialAttackStarted;

	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FQueenOnDieEvent OnDie;

	UPROPERTY(Category = "Settings")
	UQueenSettings DefaultSettings = nullptr;

	UPROPERTY()
	TArray<ABlockingVolume> GateBlockingVolumes;

	UPROPERTY(Category = "Capabilities")
	TArray<TSubclassOf<UHazeCapability>> CoreCapabilities;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Have May be the controlside initially because Match, Sap, Swarm and Swarmbuilder all have May as controlside. 
		SetControlSide(Game::GetMay());

		if (DefaultSettings != nullptr)
			SwitchSettings(DefaultSettings);

		for (auto& CoreCap : CoreCapabilities)
			AddCapability(CoreCap);

		ArmorComponentHandler.Setup();

		SetBlockingVolumesEnabled(false);

		JoinTeam(n"Queen");

		if (!bAllowWaspSpawning)
		{
			StopBossSpawning();
		}
	}

	UFUNCTION(NetFunction)
	void DebugStopBossSpawning()
	{
		bAllowWaspSpawning = false;
		StopBossSpawning();
	}

	UFUNCTION()
	void SetBlockingVolumesEnabled(bool Enabled)
	{
		for (auto Volume : GateBlockingVolumes)
		{
			Volume.SetActorEnableCollision(Enabled);
		}
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
 		for (auto& CoreCap : CoreCapabilities)
		{
 			RemoveCapability(CoreCap);
		}

		OnQueenDestroyed();
	}

	UFUNCTION(BlueprintEvent)
	void OnQueenDestroyed()
	{

	}


	UFUNCTION()
	void EnableRailBlockerSwarms()
	{
		if (RailBlockerSwarmLeft != nullptr && RailBlockerSwarmLeft.IsActorDisabled())
		{
			UWaspGrindBlockerComponent::Get(RailBlockerSwarmLeft).SetBlocking();
			UWaspGrindBlockerComponent::Get(RailBlockerSwarmRight).SetBlocking();
			GrindSpline.bCanJump = false;
			GrindSpline.bCanLandOn = false;
			GrindSpline.bCanGrappleTo = false;
		}
	}

	UFUNCTION()
	void HideNeckParts()
	{
		Mesh.HideBoneByName(n"LeftHookCover", EPhysBodyOp::PBO_None);
		Mesh.HideBoneByName(n"RightHookCover", EPhysBodyOp::PBO_None);
	}

	UFUNCTION()
	void DisableRailBlockerSwarms()
	{
		if (RailBlockerSwarmLeft != nullptr && !RailBlockerSwarmLeft.IsActorDisabled())
		{
			UWaspGrindBlockerComponent::Get(RailBlockerSwarmLeft).FlyAway();
			UWaspGrindBlockerComponent::Get(RailBlockerSwarmRight).FlyAway();

			GrindSpline.bCanJump = true;
			GrindSpline.bCanLandOn = true;
			GrindSpline.bCanGrappleTo = true;
		}
	}

	UFUNCTION()
	void RecruitSwarm(ASwarmActor InSwarm)
	{
		BehaviourComp.RecruitSwarm(InSwarm);
	}

	UFUNCTION()
	void KillAllSwarms()
	{
		for (ASwarmActor Swarm : BehaviourComp.Swarms)
		{
			Swarm.KillSwarm();
		}
	}

	UFUNCTION()
	void SwitchQueenBehaviour(UHazeCapabilitySheet OptionalQueenCapabilitySheet, UQueenSettings OptionalQueenSettings = nullptr)
	{
		SwitchCapabilitySheet(OptionalQueenCapabilitySheet);
		SwitchSettings(OptionalQueenSettings);
	}

	void SwitchSettings(UQueenSettings InSettings)
	{
		if (InSettings == nullptr)
			return;

		if (InSettings == BehaviourComp.CurrentSettings)
			return;

		if (BehaviourComp.CurrentSettings != nullptr)
			ClearSettingsWithAsset(BehaviourComp.CurrentSettings, BehaviourComp);

		BehaviourComp.CurrentSettings = InSettings;
		ApplySettings(InSettings, BehaviourComp);
	}

	UFUNCTION()
	void SwitchCapabilitySheet(UHazeCapabilitySheet InSheet)
	{
		if (InSheet == nullptr)
		{
			return;
		}

		if(InSheet == BehaviourComp.CurrentBehaviourSheet)
		{
			return;
		}

		if (BehaviourComp.CurrentBehaviourSheet != nullptr)
		{
			RemoveCapabilitySheet(BehaviourComp.CurrentBehaviourSheet);
		}

		BehaviourComp.CurrentBehaviourSheet = InSheet;
		AddCapabilitySheet(InSheet);
	}

	UFUNCTION()
	void ThrowPlayersIntoArena()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (BehindQueenArea.IsOverlappingActor(Player) && Player.HasControl())
			{
				if (Player.IsCody())
				{
					ThrowCodyIntoArenaActor.NetThrowPlayerIntoArena(Player);
				}
				else if (Player.IsMay())
				{
					ThrowMayIntoArenaActor.NetThrowPlayerIntoArena(Player);
				}
			}
		}
	}

	UFUNCTION(BlueprintPure)
	int GetNumSwarms() const
	{
		return BehaviourComp.Swarms.Num();
	}

	UFUNCTION(BlueprintPure)
	bool IsShieldSwarmActive() const
	{
		for(ASwarmActor SwarmIter : BehaviourComp.Swarms)
		{
			if(SwarmIter ==  nullptr)
				continue;
			
			if(SwarmIter.IsShape(ESwarmShape::Shield))
			{
				return true;
			}
		}
		return false;
	}

}
