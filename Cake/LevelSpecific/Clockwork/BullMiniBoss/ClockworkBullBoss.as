import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Peanuts.Fades.FadeStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossCenterPillar;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossMovementCircle;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossDataAsset;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossData;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Peanuts.Triggers.BothPlayerTrigger;

// FUNCTIONS
import void SetupBullBossForPlayer(AClockworkBullBoss) from "Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent";
import void TriggerImpactOnPlayer(FBullValidImpactData, AHazePlayerCharacter) from "Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent";

delegate void FOnAnimationValidationComplete();
event void FOnAnimationValidationCompleteSignature();

UCLASS(hidecategories="Clothing Variable Activation Navigation Shape Tick Replication Lightning Rendering Activation Cooking Replication Input HLOD Mobile AssetUserData")
class AClockworkBullBossArenaManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ABothPlayerTrigger ActivationTrigger;

	TPerPlayer<FVector> LastValidLocation;

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			LastValidLocation[Player] = Player.GetActorLocation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Position;
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			if(ActivationTrigger.BrushComponent.GetClosestPointOnCollision(Player.GetActorLocation(), Position) > 100.f)
			{
				Player.CleanupCurrentMovementTrail();
				Player.SetActorLocation(LastValidLocation[Player]);	
			}
			else
			{
				LastValidLocation[Player] = Player.GetActorLocation();
			}
			
		}
	}
}

class UHazeBullBossMovementComponent : UHazeMovementComponent
{
	default bDepenetrateOutOfOtherMovementComponents = false;

	private FHazeLocomotionTransform LastConsumedRootMotion;

	AClockworkBullBoss BullOwner;

	bool ConsumeRootMotion(UHazeCharacterSkeletalMeshComponent Mesh, FHazeLocomotionTransform& OutLocomotion)
	{
		const bool bHasRootMotion = Mesh.ConsumeLastExtractedRootMotion(LastConsumedRootMotion);
		if(bHasRootMotion)
		{
			OutLocomotion = LastConsumedRootMotion;
		}
		return bHasRootMotion;
	}	

	UFUNCTION(BlueprintOverride)
    void BeginPlay() override
	{
		Super::BeginPlay();
		BullOwner = Cast<AClockworkBullBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PostMove()
	{
		// Safety if the bullboss is forced underground
		if(BullOwner.bIsInCombat && HasControl())
		{
			FVector ActorCurrentLocation = BullOwner.GetActorLocation();
			const float FloorDiff = FMath::Abs(ActorCurrentLocation.Z - BullOwner.LockedHeight);
			if(FloorDiff > 100.f)
				BullOwner.SetActorLocation(FVector(ActorCurrentLocation.X, ActorCurrentLocation.Y, BullOwner.LockedHeight));
		}
	}
}

// BULL
UCLASS(hidecategories="Clothing Variable Activation Navigation Shape Tick Replication Lightning Rendering Activation Cooking Replication Input HLOD Mobile AssetUserData")
class AClockworkBullBoss : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeBullBossMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComponent.UpdateSettings.OptimalCount = 2;
	default ReplicateAsMovingActor();

	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent NetworkSideComponent;
	default NetworkSideComponent.ControlSide = EHazePlayer::May;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComponent;

	UPROPERTY(Category = "Combat", EditDefaultsOnly)
	UClockworkBullBossAiSettings Settings;

	UPROPERTY(Category = "Combat", EditInstanceOnly)
	AClockworkBullBossPillar CenterPillar = nullptr;
	
	UPROPERTY(Category = "Combat", EditInstanceOnly)
	AClockworkBullBossMovementCircle MovementActor;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent ChargeCamera;

	TArray<FBullAttackCollisionData> CollisionData;

	default CapsuleComponent.SetCollisionProfileName(n"PlayerCharacter");
	default CapsuleComponent.RemoveTag(n"Walkable");
	default CapsuleComponent.CapsuleHalfHeight = 600.f;
	default CapsuleComponent.CapsuleRadius = 600.f;
	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;

	//default MeshOffsetOffsetComponent.RelativeLocation.X = -200.f;
	default Mesh.SetCollisionProfileName(n"Pawn");
	default Mesh.RemoveTag(n"Walkable");
	default Mesh.SetLastestEndTickGroup(ETickingGroup::TG_HazeGameplay);
	default Mesh.RelativeLocation = FVector(-200.f, 0.f, 0.f);
	default Mesh.bPreInitializeFeatures = true;
	default Mesh.bUpdateOverlapsOnAnimationFinalize = false;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent HeadCollisionComponent;
	default HeadCollisionComponent.Radius = 500.f;
	default HeadCollisionComponent.HalfHeight = 500.f;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent LeftBackCollisionComponent;
	default LeftBackCollisionComponent.Radius = 80.f;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent RightBackCollisionComponent;
	default RightBackCollisionComponent.Radius = 80.f;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent LeftFrontCollisionComponent;
	default LeftFrontCollisionComponent.Radius = 80.f;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent RightFrontCollisionComponent;
	default RightFrontCollisionComponent.Radius = 80.f;

	UPROPERTY(DefaultComponent)
	UBullImpactComponent TorsoCollisionComponent;
	default TorsoCollisionComponent.Radius = 400.f;
	default TorsoCollisionComponent.HalfHeight = 600.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Events")
	FBullBossImpactActorEventSignature OnChargeImpact;

	UPROPERTY(Category = "Events")
	FBullBossKillPlayerEventSignature OnPlayerDeath;

	UPROPERTY(Category = "Events")
	FBullBossActionEvent OnActionEvent;

	UPROPERTY(Category = "Events")
	FOnChargeStateChangeSignature OnChargeStateChange;

	UPROPERTY(Category = "Players")
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY(Category = "Players")
	UPlayerHealthSettings HealthSettings;

	UPROPERTY(Category = "Ai", EditDefaultsOnly)
	UHazeCapabilitySheet BullSheet;

	UPROPERTY(Category = "Players")
	FBullBossPlayerSetupInformation MaySetupInformation;

	UPROPERTY(Category = "Players")
	FBullBossPlayerSetupInformation CodySetupInformation;

	// How long can the player stand and time control before he gets interupted
	UPROPERTY(Category = "Players")
	float MaxTimeIgnoreAsTargetTime = 20.f;

	// This camera setting will be activated when may is between the pillar and the boss, and he wants to charge may.
	UPROPERTY(Category = "Cameras|Charge")
	UHazeCameraSpringArmSettingsDataAsset BuildingUpToChargePlayerCameraSetting;

	UPROPERTY(Category = "Cameras|Charge")
	EHazeCameraPriority BuildingUpToChargePlayerCameraSettingPrio = EHazeCameraPriority::Script;

	UPROPERTY(Category = "Cameras|Charge")
	FHazeCameraBlendSettings BuildingUpToChargePlayerCameraSettingBlend;

	UPROPERTY(Category = "Movement")
	float GravityMultiplier = 9.f;

	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	EBullBossChargeStateType ChargeState = EBullBossChargeStateType::Inactive;

	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	float ChargeMinLerpTime = 0.1f;

	// At what distance will it take the 'ChargeMinLerpTime' to reach the target
	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	float ChargeMinDistance = 100.f;

	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	float ChargeMaxLerpTime = 1.f;

	// At what distance will it take the 'ChargeMaxLerpTime' to reach the target
	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	float ChargeMaxDistance = 1000.f;

	UPROPERTY(Category = "Charge", BlueprintReadOnly)
	bool bPlayerDodgeCharge = false;

	UPROPERTY(EditInstanceOnly)
	AClockworkBullBossArenaManager ArenaManager;

	UPROPERTY()
	FBullBossAttackReplicationParams AttackReplicationParams;

	TArray<AHazePlayerCharacter> AvailableTargets;
	private USceneComponent CurrentTargetComponent = nullptr;
	private AHazePlayerCharacter LastPlayerTarget = nullptr;
	//AHazePlayerCharacter PendingControlSidePlayer = nullptr;
	float BlockChangeTargetTimeLeft = 0;
	float CurrentTargetAquireGameTime = 0;

	private FHazeFrameMovement PendingMoveData;
	private FHazeRequestLocomotionData PendingAnimationRequest;
	private bool bHasPendingMovementData = false;
	private bool bPendingConsumeIsControlSide = true;
	
	private bool bRootMotionRotationActive = false;
	private bool bUseRootMotionRotationSpeedCurve = false;
	private FRuntimeFloatCurve RotationSpeedCurve;
	private float RotationTimeChange = 0;
	private float RotationTimeChangeLeft = 0;
	private float RotationBlockTime = 0;
	
	bool bValidEscapeWindowIsActive = false;
	bool bHasLockedTeleportPosition = false;
	FVector ValidEscapePosition = FVector::ZeroVector;

	FBullAttackRangeChange AttackRangeChange;

	const float DefaultRotationSpeed = 10.f;
	private bool bWindingUpCharge = false;;
	private TArray<FBullDebugText> DebugTextArray;
	bool bPlayerWantsBullToCharge = false;

	bool bIsInCombat = false;
	int ActiveDamageCount = 0;
	float LockedHeight = 0;
	float MoveToChargeSpeed = -1;
	float ActiveTimeControlTime = 0;

	private bool bIsWaitingForNetworkAnimationValidation = false;
	private FOnAnimationValidationCompleteSignature OnPendingAnimationValidationComplete;


	private int HasCustomTargetLocationFrameLeft;
	private FVector CustomTargetLocation;

	private bool bHasCustomRotation;
	private FRotator CustomRotation;
	private float CustomRotationSpeed;

// #if TEST
// 	FHazeRequestLocomotionData LastAnimationRequest;
// #endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CapsuleComponent.RelativeLocation = FVector(200.f, 0.f, CapsuleComponent.CapsuleRadius);
    }
	
	void InitCollisionData()
	{
		if(CollisionData.Num() == 0)
		{
			CollisionData.Add(FBullAttackCollisionData(nullptr, EBullBossDamageInstigatorType::None));
			CollisionData.Add(FBullAttackCollisionData(HeadCollisionComponent, EBullBossDamageInstigatorType::Head));
			CollisionData.Add(FBullAttackCollisionData(LeftBackCollisionComponent, EBullBossDamageInstigatorType::LeftBackFoot));
			CollisionData.Add(FBullAttackCollisionData(RightBackCollisionComponent, EBullBossDamageInstigatorType::RightBackFoot));
			CollisionData.Add(FBullAttackCollisionData(LeftFrontCollisionComponent, EBullBossDamageInstigatorType::LeftFrontFoot));
			CollisionData.Add(FBullAttackCollisionData(RightFrontCollisionComponent, EBullBossDamageInstigatorType::RightFrontFoot));
			CollisionData.Add(FBullAttackCollisionData(TorsoCollisionComponent, EBullBossDamageInstigatorType::Torso));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MovementComponent.Setup(CapsuleComponent);
		MovementComponent.UseCollisionSolver(n"AICharacterSolver", n"AICharacterRemoteCollisionSolver");
		MovementComponent.StartIgnoringComponent(CenterPillar.StatueMesh);
		
		UMovementSettings::SetMoveSpeed(this, 1800, this, EHazeSettingsPriority::Defaults);
		UMovementSettings::SetGravityMultiplier(this, GravityMultiplier, this, EHazeSettingsPriority::Defaults);

		HeadCollisionComponent.AttachToComponent(Mesh, HeadCollisionComponent.AttachBoneName);
		LeftBackCollisionComponent.AttachToComponent(Mesh, LeftBackCollisionComponent.AttachBoneName);
		RightBackCollisionComponent.AttachToComponent(Mesh, RightBackCollisionComponent.AttachBoneName);
		LeftFrontCollisionComponent.AttachToComponent(Mesh, LeftFrontCollisionComponent.AttachBoneName);
		RightFrontCollisionComponent.AttachToComponent(Mesh, RightFrontCollisionComponent.AttachBoneName);
		TorsoCollisionComponent.AttachToComponent(Mesh, TorsoCollisionComponent.AttachBoneName);
		InitCollisionData();
		ArenaManager.DisableActor(this);
	
	#if TEST
		// Log animation transitions
		AddDebugCapability(n"DebugAnimationCapability");
	#endif

		BlockCapabilities(n"Movement", this);
		DisableMovementComponent(this);

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		StopFight();
	}

	UFUNCTION()
	void StartFight()
	{
		bIsInCombat = true;
		LockedHeight = GetActorLocation().Z;
		AddCapabilitySheet(BullSheet);

		for (auto Player : Game::Players)
			Player.ApplySettings(HealthSettings, this);

		AHazePlayerCharacter May = Game::GetMay();
		Capability::AddPlayerCapabilitySheetRequest(MaySetupInformation.Sheet, MaySetupInformation.SheetPriority, EHazeSelectPlayer::May);
		
		FSequenceDelegate OnStartedTeleportDelegate;
		OnStartedTeleportDelegate.BindUFunction(this, n"OnPlayerStartedTeleport");
		BindOnSequenceDelegate(ESequenceEventType::OnStartedTeleport, May, OnStartedTeleportDelegate);

		FSequenceDelegate OnPostStartedTeleportDelegate;
		OnPostStartedTeleportDelegate.BindUFunction(this, n"OnPlayerTeleported");
		BindOnSequenceDelegate(ESequenceEventType::OnPostStartedTeleport, May, OnPostStartedTeleportDelegate);

		FSequenceDelegate OnTeleportFinishedDelegate;
		OnTeleportFinishedDelegate.BindUFunction(this, n"OnPlayerTeleportFinished");
		BindOnSequenceDelegate(ESequenceEventType::OnTeleportFinished, May, OnTeleportFinishedDelegate);

		AHazePlayerCharacter Cody = Game::GetCody();
		Capability::AddPlayerCapabilitySheetRequest(CodySetupInformation.Sheet, CodySetupInformation.SheetPriority, EHazeSelectPlayer::Cody);

		SetupBullBossForPlayer(this);

		FOnPlayersGameOver OnGameOver;
		OnGameOver.BindUFunction(this, n"TriggerGameOver");
		BindPlayersGameOverEvent(OnGameOver);

		UnblockCapabilities(n"Movement", this);
		EnableMovementComponent(this);

		EnableActor(nullptr);
		ArenaManager.EnableActor(this);
		ArenaManager.SetActorTickEnabled(true);
	}

	UFUNCTION()
	void StopFight()
	{
		if(!bIsInCombat)
			return;

		bIsInCombat = false;
		RemoveCapabilitySheet(BullSheet);
		ClearPlayersGameOverEvent();

		for (auto Player : Game::Players)
		{
			MovementComponent.StopIgnoringActor(Player);
			Player.ClearSettingsByInstigator(this);
		}
		
		AHazePlayerCharacter May = Game::GetMay();
		ClearSequenceDelegates(May);
		Capability::RemovePlayerCapabilitySheetRequest(MaySetupInformation.Sheet, MaySetupInformation.SheetPriority, EHazeSelectPlayer::May);
		May.ClearLocomotionAssetByInstigator(this);

		AHazePlayerCharacter Cody = Game::GetCody();
		Capability::RemovePlayerCapabilitySheetRequest(CodySetupInformation.Sheet, CodySetupInformation.SheetPriority, EHazeSelectPlayer::Cody);
		Cody.ClearLocomotionAssetByInstigator(this);

		ClearPlayersGameOverEvent();
		BlockCapabilities(n"Movement", this);
		DisableMovementComponent(this);
		ArenaManager.DisableActor(this);
	}

	UFUNCTION()
	void SetMoveToChargeMovementSpeed(float Speed) property
	{
		MoveToChargeSpeed = Speed;
	}

	USceneComponent GetCurrentTarget()const property
	{
		return CurrentTargetComponent;
	}

	bool PlayerIsUsingTimeControl(AHazePlayerCharacter Player) const
	{
		auto TimeComp = UTimeControlComponent::Get(Player);
		if(TimeComp == nullptr)
			return false;

		if(!TimeComp.IsTimeControlActive())
			return false;
		
		return true;
	}

	AHazePlayerCharacter GetRandomPlayerTarget()const property
	{
		TArray<AHazePlayerCharacter> SelectablePlayers;
		if(AvailableTargets.Num() > 0 && LastPlayerTarget != nullptr && FMath::RandRange(0, 100) > 30)
		{
			if(AvailableTargets.Contains(LastPlayerTarget.GetOtherPlayer()))
			{	
				if(CanTargetPlayer(LastPlayerTarget.GetOtherPlayer(), true))
					SelectablePlayers.Add(LastPlayerTarget.GetOtherPlayer());
			}
		}

		if(SelectablePlayers.Num() == 0)
		{
			for(int i = 0; i < AvailableTargets.Num(); ++i)
			{
				if(CanTargetPlayer(AvailableTargets[i], true))
					SelectablePlayers.Add(AvailableTargets[i]);
			}
		}
		
		if(SelectablePlayers.Num() > 0)
		{
			int RandomIndex = FMath::RandRange(0, SelectablePlayers.Num() - 1);
			return (SelectablePlayers[RandomIndex]);
		}
		else
		{
			return nullptr;
		}
	}

	AHazePlayerCharacter GetBestPlayerTarget()const property
	{
		TArray<AHazePlayerCharacter> SelectablePlayers;
		for(int i = 0; i < AvailableTargets.Num(); ++i)
		{
			if(CanTargetPlayer(AvailableTargets[i], true))
				SelectablePlayers.Add(AvailableTargets[i]);
		}

		int BestScore = -1;
		AHazePlayerCharacter BestPlayer = nullptr;
		for(auto Player : SelectablePlayers)
		{
			const int Score = GetScoreToPlayer(Player);
			if(Score > BestScore || (Score == BestScore && FMath::RandBool()))
			{
				BestPlayer = Player;
				BestScore = Score;
			}
		}

		return BestPlayer;
	}	

	AHazePlayerCharacter GetBestVisiblePlayerTarget(FHazeIntersectionCone Cone, float TargetRadius = 200.f)const
	{
		int BestScore = -1;
		AHazePlayerCharacter BestPlayer = nullptr;
		for(auto Player : AvailableTargets)
		{	
			if(!CanTargetPlayer(Player, true))
				continue;

			if(!CanSeeTarget(Player.GetActorCenterLocation(), Cone, TargetRadius))
				continue;

			const int Score = GetScoreToPlayer(Player);
			if(Score > BestScore || (Score == BestScore && FMath::RandBool()))
			{
				BestPlayer = Player;
				BestScore = Score;
			}
		}

		return BestPlayer;
	}

	bool CanTargetPlayer(AHazePlayerCharacter PlayerToTest, bool bValidatePlayerSkills)const
	{
		if(PlayerToTest == nullptr)
			return false;

		if(PlayerToTest.IsPlayerDead())
			return false;

		// May can never be targeted as long as she is teleporting
		if(PlayerToTest.IsMay())
		{
			auto TimeComp = UTimeControlSequenceComponent::Get(PlayerToTest);
			if(TimeComp != nullptr && TimeComp.bIsCurrentlyTeleporting)	
				return false;
		}

		// Always target this player if the other player is dead
		if(PlayerToTest.GetOtherPlayer().IsPlayerDead())
			return true;

		if(bValidatePlayerSkills)
		{
			if(PlayerToTest.IsCody())
			{
				// If cody is the current target, we can alway target him
				auto CurrentPlayerTarget = GetCurrentTargetPlayer();
				if(CurrentPlayerTarget != nullptr && CurrentPlayerTarget.IsCody())
					return true;
			}

			// If we are timecontrolling, we need to have done it for a while until we can be target
			if(PlayerIsUsingTimeControl(PlayerToTest))
			{
				if(ActiveTimeControlTime < MaxTimeIgnoreAsTargetTime)
					return false;
			}
		}

		return true;
	}

	private float GetScoreToPlayer(AHazePlayerCharacter PlayerToTest) const
 	{
		if(PlayerToTest == nullptr)
			return -1;

		float FinalScore = 0;
		const FVector PlayerLocation = PlayerToTest.GetActorCenterLocation();

		float BiggestDistance = 0;
		float ThisDistance = 0;
		for(auto Player : AvailableTargets)
		{
			const float Dist = Player.ActorLocation.DistSquared2D(ActorLocation);
			if(Dist > BiggestDistance)
				BiggestDistance = Dist;

			if(Player == PlayerToTest)
				ThisDistance = Dist;
		}

		const float DistanceScoreAlpha = BiggestDistance > 0 ? 1 - (ThisDistance / BiggestDistance) : 1.f;

		FVector DirToTarget = PlayerToTest.GetActorLocation() - ActorLocation;
		DirToTarget.ConstrainToPlane(FVector::UpVector);
		if(DirToTarget.IsNearlyZero())
			DirToTarget = ActorForwardVector;

		const float DirectionAlpha = Math::GetLinearDotProduct(DirToTarget, ActorForwardVector);

		FinalScore += FMath::Lerp(0.f, 100.f, DistanceScoreAlpha);
		FinalScore += FMath::Lerp(0.f, 50.f, DirectionAlpha);

 		return FinalScore;
	}

	void SetPlayerTargetFromControl(AHazePlayerCharacter Target)
	{
		if(!HasControl())
			return;

		if(Target == nullptr)
			return;

		if(GetCurrentTargetPlayer() == Target)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Target", Target);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetPlayerTarget"), CrumbParams);
	}

	void ClearCurrentTargetFromControl()
	{
		if(CurrentTargetComponent != nullptr && HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ClearPlayerTarget"), CrumbParams);
		}
	}

	bool CanChangeTarget()const
	{
		if(BlockChangeTargetTimeLeft > KINDA_SMALL_NUMBER)
			return false;
		else if(BlockChangeTargetTimeLeft <= -1.f - KINDA_SMALL_NUMBER)
			return false;
		else
			return true;
	}

	UFUNCTION(NotBlueprintCallable)
    void Crumb_SetPlayerTarget(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Target = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Target"));
		SetPlayerTarget(Target);
	}

	UFUNCTION(NotBlueprintCallable)
    void Crumb_ClearPlayerTarget(const FHazeDelegateCrumbData& CrumbData)
	{
		ClearCurrentTarget();
	}

	private void SetPlayerTarget(AHazePlayerCharacter NewTarget)
	{
		ClearCurrentTarget();

		if(NewTarget != nullptr)
		{
			if(LastPlayerTarget == nullptr)
				LastPlayerTarget = NewTarget;

			CurrentTargetComponent = NewTarget.RootComponent;
			CurrentTargetAquireGameTime = Time::GetGameTimeSeconds();
			
			// SetControlSide(NewTarget);
			// if(NewTarget.HasControl() != HasControl())
			// {	
			// 	TriggerMovementTransition(this, n"ChangedControlSide");
			// }
		}

		//PendingControlSidePlayer = nullptr;
	}

	void ClearCurrentTarget()
	{
		if(CurrentTargetComponent != nullptr)
		{		
			AHazePlayerCharacter CurrentPlayerTarget = Cast<AHazePlayerCharacter>(CurrentTargetComponent.Owner);
			if(CurrentPlayerTarget != nullptr)
				LastPlayerTarget = CurrentPlayerTarget;

			CurrentTargetComponent = nullptr;
			CurrentTargetAquireGameTime = 0.f;
		}
	}

	UFUNCTION()
    void TriggerGameOver()
    {
		OnPlayerDeath.Broadcast();
		StopFight();
    }

	void WantToActivateChargeCamera(bool bStatus)
	{
		AHazePlayerCharacter May = Game::GetMay();
		if(bStatus == false)
		{
			SetWindingUpCameraState(false, May);
			return;
		}

		if(BuildingUpToChargePlayerCameraSetting == nullptr)
			return;

		if(CenterPillar == nullptr)
			return;

		FBullSetupMovementParams BullState(this, CenterPillar.GetActorLocation());
		const FVector PlayerLocation = BullState.FixupLocation(May.GetActorLocation());

		FVector DirToPlayer = (PlayerLocation - BullState.BullLocation).GetSafeNormal();
		if(DirToPlayer.IsNearlyZero())
			DirToPlayer = BullState.FacingDirection;
		
		// We are not facing the player
		if(BullState.GetHorizontalDirToTarget().DotProduct(DirToPlayer) < 0.8f)
		{
			SetWindingUpCameraState(false, May);
			return;
		}
		
		const float DistToPlayerSq = BullState.BullLocation.DistSquared(PlayerLocation);
		const float DistToPillarSq = BullState.BullLocation.DistSquared(BullState.TargetLocation);
		
		// The pillar is closer than the player, so the player can't be in the middle of the pillar and the bull
		if(DistToPlayerSq > DistToPillarSq)
		{
			SetWindingUpCameraState(false, May);
			return;
		}

		SetWindingUpCameraState(true, May);
	}

	private void SetWindingUpCameraState(bool bStatus, AHazePlayerCharacter May)
	{
		if(bWindingUpCharge != bStatus)
		{
			bWindingUpCharge = bStatus;
			if(bStatus)
			{
				May.ApplyCameraSettings(BuildingUpToChargePlayerCameraSetting, BuildingUpToChargePlayerCameraSettingBlend, this, BuildingUpToChargePlayerCameraSettingPrio);
			}
			else
			{
				May.ClearCameraSettingsByInstigator(this);
			}
		}
	}

	void IgnoreMovementCollision(AHazePlayerCharacter Player, bool bStatus)
	{
		if(bStatus)
		{
			MovementComponent.StartIgnoringActor(Player);
			UHazeMovementComponent::Get(Player).StartIgnoringActor(this);
		}
		else
		{
			MovementComponent.StopIgnoringActor(Player);
			UHazeMovementComponent::Get(Player).StopIgnoringActor(this);
		}
	}

	bool IsRootMotionRotationActive()const
	{
		return bRootMotionRotationActive;
	}

	float GetRootMotionBlendAlpha()const
	{
		if(RotationTimeChange > 0)
			return RotationTimeChangeLeft / RotationTimeChange;
		else
			return 0.f;
	}
	
	UFUNCTION()
	void ActivateAutomaticRotation(float BlendTime, float InitialDelay = 0.f)
	{
		if(!bRootMotionRotationActive)
			return;

		bRootMotionRotationActive = false;
		RotationTimeChange = FMath::Max(BlendTime, 0.f);
		RotationTimeChangeLeft = RotationTimeChange;
		bUseRootMotionRotationSpeedCurve = false;
		RotationBlockTime = Time::GetGameTimeSeconds() + InitialDelay;
	}

	UFUNCTION()
	void DectivateAutomaticRotation(float BlendTime)
	{
		if(bRootMotionRotationActive)
			return;
			
		bRootMotionRotationActive = true;
		RotationTimeChange = FMath::Max(BlendTime, 0.f);
		RotationTimeChangeLeft = RotationTimeChange;
		bUseRootMotionRotationSpeedCurve = false;
	}

	UFUNCTION()
	void SetAutomaticRotionCurve(const FRuntimeFloatCurve& Curve, float Duration)
	{
		bRootMotionRotationActive = false;
		bUseRootMotionRotationSpeedCurve = true;
		RotationSpeedCurve = Curve;
		RotationTimeChange = Duration;
		RotationTimeChangeLeft = RotationTimeChange;
	}

	void SetManualFacingRotation()
	{

	}

	UFUNCTION()
	void SetDamageEnabled(EBullBossDamageInstigatorType InInstigator, EBullBossDamageType DamageType, EBullBossDamageAmountType DamageAmountType, float ForceTime, FVector DamageForceLocalSpace, float LockedIntoTakeDamageTime = -1, FVector2D BonusRadius = FVector2D::ZeroVector)
	{
		InitCollisionData();
		FBullAttackCollisionData& collision = CollisionData[int(InInstigator)];
		const FVector2D OldBonusRadius = collision.BonusRadius;

		if(!collision.bEnabled)
		{
			collision.bEnabled = true;
			ActiveDamageCount++;
		}
	
		collision.BonusRadius = BonusRadius;
		collision.DamageType = DamageType;
		collision.DamageForce = DamageForceLocalSpace;
		collision.DamageAmount = GetBullBossDamageAmount(DamageAmountType);
		collision.LockedIntoTakeDamageTime = LockedIntoTakeDamageTime;
		collision.ApplyForceTime = ForceTime;
	}

	UFUNCTION()
	void SetDamageDisabled(EBullBossDamageInstigatorType InInstigator)
	{
		InitCollisionData();
		FBullAttackCollisionData& collision = CollisionData[int(InInstigator)];
		if(collision.bEnabled)
		{
			collision.bEnabled = false;
			collision.BonusRadius = FVector2D::ZeroVector;
			collision.DamageForce = FVector::ZeroVector;
			collision.DamageAmount = 0;
			ActiveDamageCount--;
		}
	}

	void TriggerDamageStartCollisionWithPlayer(const FBullAttackCollisionData& Collision, AHazePlayerCharacter Player, bool bFromChargeing)
	{
        if(Player == nullptr)
            return;

        if(!Player.HasControl())
            return;
	
		auto CurrentGodMode = GetGodMode(Player);
		if(CurrentGodMode == EGodMode::God)
			return;

		FBullValidImpactData Impact;
		Impact.DamageForce = Collision.DamageForce;
		Impact.DamageInstigator = Collision.InstigatorType;
		Impact.DamageType = Collision.DamageType;
		Impact.LockedIntoTakeDamageTime = Collision.LockedIntoTakeDamageTime;
		Impact.ApplyForceTime = Collision.ApplyForceTime;
		Impact.DamageAmount = Collision.DamageAmount;
		Impact.bFromCharge = bFromChargeing;

		TriggerImpactOnPlayer(Impact, Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Time::GetGameTimeSeconds() >= RotationBlockTime)
			RotationTimeChangeLeft = FMath::Max(RotationTimeChangeLeft - DeltaTime, 0.f);

		if(BlockChangeTargetTimeLeft > 0)
		{
			BlockChangeTargetTimeLeft = FMath::Max(BlockChangeTargetTimeLeft - DeltaTime, 0.f);  
		}

		if(bIsInCombat)
		{
			if(PlayerIsUsingTimeControl(Game::GetCody()))
				ActiveTimeControlTime = FMath::Min(ActiveTimeControlTime + DeltaTime, MaxTimeIgnoreAsTargetTime);
			else
				ActiveTimeControlTime = FMath::Max(ActiveTimeControlTime - (DeltaTime * 4.f), 0.f);
		}
		
		FVector Scale = GetActorScale3D();
		ensure(Scale.Equals(FVector(1.f)));

		if(bIsWaitingForNetworkAnimationValidation && !Mesh.CurrentFeatureHasPendingNetworkTransitions())
		{
			bIsWaitingForNetworkAnimationValidation = false;
			OnPendingAnimationValidationComplete.Broadcast();
			OnPendingAnimationValidationComplete.Clear();
		}
		
#if TEST
		if(GetDebugFlag(n"BullBossDebug"))
		{
			for(const FBullAttackCollisionData& collision : CollisionData)
			{
				if(collision.CollisionComponent == nullptr)
					continue;

				if(collision.IsCollisionEnabled())
				{
					AddDebugText("Damage <Green>Enabled</> on component: " + collision.CollisionComponent.GetName() + 
					"\nDamageType: " + collision.DamageType + "\n");
				}
			}

			System::DrawDebugSphere(GetTargetPosition(), 300, LineColor = FLinearColor::Blue);
		}
#endif

		// DEBUG
		//SetDamageEnabled(EBullBossDamageInstigatorType::Head, EBullBossDamageType::Stomp, FVector::ZeroVector, 600.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStartedTeleport(AHazePlayerCharacter Player)
	{
		bHasLockedTeleportPosition = true;
		ValidEscapePosition = Game::GetMay().GetActorLocation();
		SetCustomTargetLocationForFrame(ValidEscapePosition);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerTeleported(AHazePlayerCharacter Player)
	{
		bHasLockedTeleportPosition = false;

		if(!bValidEscapeWindowIsActive)
			return;

		if(bPlayerWantsBullToCharge)
			return;

		if(ChargeState == EBullBossChargeStateType::TargetingMay)
		{
			ChangeChargeState(EBullBossChargeStateType::TargetingForward);
		}
		else if(ChargeState == EBullBossChargeStateType::RushingMay)
		{
			ChangeChargeState(EBullBossChargeStateType::RushingForward);
		}
	}

	UFUNCTION()
	void OnPlayerTeleportFinished(AHazePlayerCharacter Player)
	{
		FHazePointOfInterest Poi;
		Poi.FocusTarget.Actor = this;
		Poi.FocusTarget.WorldOffset = FVector(0.f, 0.f, -500.f);
		Poi.Duration = 2.f;
		Poi.Blend.BlendTime = 0.55f;
		Player.ApplyPointOfInterest(Poi, this);
	}

	void InitializeMovement(UHazeMovementComponent MoveComp, FHazeFrameMovement& MoveData, FVector TargetWorldLocation, FName AnimationRequestTag, FName SubAnimationRequestTag, bool bIsControlSide)
	{    
		PendingMoveData = MoveData;
		bHasPendingMovementData = true;
		
		PendingAnimationRequest = FHazeRequestLocomotionData();
		PendingAnimationRequest.AnimationTag = AnimationRequestTag;
		PendingAnimationRequest.SubAnimationTag = SubAnimationRequestTag;
		if(PendingAnimationRequest.AnimationTag == NAME_None)
			PendingAnimationRequest.AnimationTag = n"Movement";

		PendingAnimationRequest.SetWantedWorldLocation(TargetWorldLocation);

		// We change the current rotation to what the frame movement wants us to face
		// MoveComp.SetTargetFacingRotation(PendingMoveData.Rotation);
		bPendingConsumeIsControlSide = bIsControlSide;

		// DEBUG
// #if TEST
// 		if(GetDebugFlag(n"BullBossDebug"))
// 		{
// 			if(LastAnimationRequest.AnimationTag != AnimationRequest.AnimationTag)
// 			{
// 				AddDebugText("AnimRequest: " + AnimationRequest.AnimationTag, 1.f, true);
// 			}
// 		}
// 		LastAnimationRequest = AnimationRequest;
// #endif

	}

	void ChangeChargeState(EBullBossChargeStateType NewChargeState)
	{
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddNumber(n"StateIndex", NewChargeState);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ChangeState"), CrumbParams);
	}

	void UpdateCollisionBonusDistances(float DeltaTime)
	{
		AttackRangeChange.IncreasedAttackRangeDuration -= DeltaTime;
		if(AttackRangeChange.IncreasedAttackRangeDuration <= 0)
		{
			AttackRangeChange = FBullAttackRangeChange();
		}
	}

	void ClearBonusAttackDistance()
	{
		AttackRangeChange.IncreasedAttackRangeDuration = 0;
		AttackRangeChange = FBullAttackRangeChange();
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ChangeState(const FHazeDelegateCrumbData& CrumbData)
	{
		const EBullBossChargeStateType Index = EBullBossChargeStateType(CrumbData.GetNumber(n"StateIndex"));
		ChargeState = Index;

		if(ChargeState == EBullBossChargeStateType::TargetingForward)
			bPlayerDodgeCharge = true;
		else if(ChargeState == EBullBossChargeStateType::RushingForward)
			bPlayerDodgeCharge = true;

		OnChargeStateChange.Broadcast(ChargeState);
	}

	bool CanInitializeMovement(UHazeMovementComponent MoveComp)const
	{
		if(bHasPendingMovementData)
			return false;

		if(!MoveComp.CanCalculateMovement())
			return false;

		if(!Mesh.CanRequestLocomotion())
			return false;

		return true;
	}

	void ResetPendingMoveData()
	{
		bHasPendingMovementData = false;
		bHasCustomRotation = false;
		HasCustomTargetLocationFrameLeft = 0;
	}

	bool ConsumePendingMovement(float DeltaTime, FHazeFrameMovement& MoveData)
	{
		if(bHasCustomRotation)
		{
			CustomRotationSpeed = CustomRotationSpeed < 0 ? MovementComponent.RotationSpeed : CustomRotationSpeed;
			MovementComponent.SetTargetFacingRotation(CustomRotation, CustomRotationSpeed);
		}
		PendingMoveData.ApplyTargetRotationDelta();

		if(bHasPendingMovementData && HasControl() == bPendingConsumeIsControlSide)
		{
			MoveData = FHazeFrameMovement(PendingMoveData);
		}
		else
		{
			MoveData = MovementComponent.MakeFrameMovement(n"BullDefaultMovement");
			MoveData.SetRotation(PendingMoveData.Rotation);
		}
		
		MoveData.OverrideStepDownHeight(200.f);
		MoveData.OverrideStepUpHeight(100.f);

		FHazeLocomotionTransform RootMotion;
		const bool bHasRootMotion = MovementComponent.ConsumeRootMotion(Mesh, RootMotion);
		//bool bHasUsedRootMotionRotation = false;

		// The remote side will follow the controlside, 
		//that should look goog enough with the animation driven movement
		// since it will move the same amount as the controlside did.
		if(bPendingConsumeIsControlSide)
		{

			if(bHasRootMotion)
			{
				MoveData.ApplyRootMotion(RootMotion, bAsUnique = true);

				if(bUseRootMotionRotationSpeedCurve)
				{
					const float RootMotionSpeed = GetRotationSpeed(-1);
					if(RootMotionSpeed > 0)
					{
						FQuat TargetRotation = FMath::QInterpConstantTo(GetActorQuat(), MoveData.Rotation, DeltaTime, RootMotionSpeed);
						MoveData.SetRotation(TargetRotation);
					}
				}

				if(RotationTimeChangeLeft > 0)
				{
					const float Alpha = GetRootMotionBlendAlpha();
					FQuat MoveRotation;

					// Lerp in the automatic rotation
					if(!bRootMotionRotationActive)
						MoveRotation = FQuat::Slerp(GetActorQuat(), PendingMoveData.Rotation, Alpha);
					
					// Lerp out the automatic rotation
					else
						MoveRotation = FQuat::Slerp(GetActorQuat(), MoveData.Rotation, Alpha);

					MoveData.SetRotation(MoveRotation);
				}
				else if(!bRootMotionRotationActive)
				{
					// Override the rootmotion rotation with the movement requested rotation
					MoveData.SetRotation(PendingMoveData.Rotation);
				}
			}

			MovementComponent.SetTargetFacingRotation(MoveData.Rotation, 0.f);
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();
		}

		PendingAnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
		PendingAnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
		PendingAnimationRequest.WantedVelocity = MoveData.Velocity;
		PendingAnimationRequest.WantedWorldTargetDirection = MoveData.Velocity.GetSafeNormal();
		PendingAnimationRequest.WantedWorldFacingRotation = MovementComponent.GetTargetFacingRotation();
		PendingAnimationRequest.MoveSpeed = MovementComponent.MoveSpeed;

		// Only overrides if we have animation
		MovementComponent.GetAnimationRequest(PendingAnimationRequest.AnimationTag);
		MovementComponent.GetSubAnimationRequest(PendingAnimationRequest.SubAnimationTag);

		RequestLocomotion(PendingAnimationRequest);

		bool bTemp = bHasPendingMovementData;
		bHasPendingMovementData = false;
		bHasCustomRotation = false;
		if(HasCustomTargetLocationFrameLeft > 0)
			HasCustomTargetLocationFrameLeft -= 1;
		bPendingConsumeIsControlSide = true;
		return bTemp;
	}

	float GetRotationSpeed(float WantedSpeed)const property
	{
		float FinalSpeed = DefaultRotationSpeed;
		if(WantedSpeed >= 0)
			FinalSpeed = WantedSpeed;

		if(bUseRootMotionRotationSpeedCurve)
		{
			const float Duration = RotationTimeChange - RotationTimeChangeLeft;
			FinalSpeed = FMath::Max(RotationSpeedCurve.GetFloatValue(Duration, FinalSpeed), 0.f);		
		}
			
		return FinalSpeed;
	}

	bool HasTarget()const
	{
		return CurrentTarget != nullptr;
	}

	float GetAttackRange()const property
	{
		return CapsuleComponent.GetCapsuleHalfHeight() + Settings.CanSeeTargetRange + AttackRangeChange.IncreasedAttackRange;
	}

	bool TargetIsInRange(FVector WantedTargetLocation, float Distance)const
	{
		FVector BullLocation = GetActorLocation();
		BullLocation.Z = WantedTargetLocation.Z;
		return WantedTargetLocation.DistSquared(BullLocation) <= FMath::Square(Distance);
	}

	bool TargetIsInAngle(FVector WantedTargetLocation, float DegreeAngle)const
	{
		const FVector DirToTarget = GetFacingDirectionToTarget(WantedTargetLocation);
		const float Angle = Math::GetAngle(DirToTarget, GetActorForwardVector());
		return Angle <= DegreeAngle;
	}

	bool CanSeeTarget(FVector WantedTargetLocation, float Distance, float DegreeAngle, float TargetRadius = 200.f) const
	{
		// Setup collision cone
		FHazeIntersectionCone Cone;
		GetIntersectionCone(Distance, DegreeAngle, Cone);
		return CanSeeTarget(WantedTargetLocation, Cone, TargetRadius);
	}

	bool CanSeeTarget(FVector WantedTargetLocation, FHazeIntersectionCone Cone, float TargetRadius = 200.f) const
	{
		// Setup collision sphere
		FHazeIntersectionSphere QuerySphere;
		QuerySphere.Origin = WantedTargetLocation;
		QuerySphere.Radius = TargetRadius;

		// Search cone must overlap the perch radius
		FHazeIntersectionResult Result;
		Result.QuerySphereCone(QuerySphere, Cone);
		return Result.bIntersecting;
	}

	void GetIntersectionCone(float Distance, float DegreeAngle, FHazeIntersectionCone& Out)const
	{
		Out.Origin = GetActorCenterLocation();
		const float SearchDistance = FMath::Max(Distance - CapsuleComponent.GetCapsuleHalfHeight(), CapsuleComponent.GetCapsuleHalfHeight());
		FVector ForwardLocation = ActorLocation + (ActorForwardVector * SearchDistance);
		Out.Direction = (ForwardLocation - GetActorCenterLocation()).GetSafeNormal();
		Out.AngleDegrees = DegreeAngle;
		Out.MaxLength = Distance;
	}

	void GetAttackIntersectionCone(FHazeIntersectionCone& Out)
	{
		GetIntersectionCone(GetAttackRange(), Settings.CanSeeTargetAngle, Out);
	}

	FVector GetFacingDirectionToTarget(FVector WantedTargetLocation) const
	{
		const FVector BullLocation = GetActorLocation();
		FVector HorizontalDirToTarget = (WantedTargetLocation - BullLocation).ConstrainToPlane(MovementComponent.WorldUp).GetSafeNormal();
		if(!HorizontalDirToTarget.IsNearlyZero())
			return HorizontalDirToTarget;

		return GetActorForwardVector();
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetCurrentTargetPlayer()const property
	{
		if(CurrentTarget == nullptr)
			return nullptr;

		auto CurrentPlayerTarget = Cast<AHazePlayerCharacter>(CurrentTarget.Owner);
		if(CurrentPlayerTarget == nullptr)
			return nullptr;
		
		return CurrentPlayerTarget;
	}

	UFUNCTION()
	void SetValidEscapeWindowActive(bool bStatus) property
	{
		bValidEscapeWindowIsActive = bStatus;
	}

	UFUNCTION()
	void SetWantToChargeStatus(bool bStatus) property
	{
		bPlayerWantsBullToCharge = bStatus;
	}
	
	void GetBestChargeFromTarget(USceneComponent& OutComponent)
	{
		if(MovementActor == nullptr)
			return;

		OutComponent = MovementActor.ChargeFromPosition;
	}

	// Returns -1 if not target is valid
	UFUNCTION(BlueprintPure)
	float GetDistanceToTarget()const
	{
		if(HasCustomTargetLocationFrameLeft > 0)
			return CustomTargetLocation.Distance(GetActorLocation());

		auto Target = GetCurrentTarget();
		if(Target != nullptr)
			return Target.GetWorldLocation().Distance(GetActorLocation());
			
		return -1;
	}

	UFUNCTION(BlueprintPure)
	FVector GetTargetPosition() const
	{
		if(HasCustomTargetLocationFrameLeft > 0)
			return CustomTargetLocation;

		auto Target = GetCurrentTarget();
		if(Target != nullptr)
			return Target.GetWorldLocation();
			
		return GetActorLocation();
	}

	UFUNCTION(BlueprintPure)
	FRotator GetRotationToTarget() const
	{
		const FVector Dir = (GetTargetPosition() - GetActorLocation()).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		if(Dir.IsNearlyZero())
			return GetActorForwardVector().Rotation();
		else
			return Dir.Rotation();
	}

	void SetCustomTargetLocationForFrame(FVector Target)
	{
		// We need to store it 2 frames
		HasCustomTargetLocationFrameLeft = 2;
		CustomTargetLocation = Target;
	}

	// Cleared at the end of the frame so needs to be updated as long as you want it to be active
	UFUNCTION()
	void SetCustomFacingForFrame(FRotator Rotation, float RotationSpeed = -1)
	{
		bHasCustomRotation = true;
		CustomRotationSpeed = RotationSpeed;
	}

	bool GetPendingDebugMovementData(FHazeFrameMovement& OutFrameMove, FHazeRequestLocomotionData& OutAnimationRequest)const
	{
		if(bHasPendingMovementData)
		{
			OutFrameMove = FHazeFrameMovement(PendingMoveData);
			OutAnimationRequest = FHazeRequestLocomotionData(PendingAnimationRequest);
			return true;
		}

		return false;
	}

	void AddDebugText(FString Text, float Duration = 0, bool bLog = false)
	{
	#if TEST
		FBullDebugText NewText;
		NewText.TimeLeft = Duration;
		NewText.Text = Text;
		DebugTextArray.Add(NewText);

		if(bLog)
		{
			System::PrintString(Text, false, true);
		}
	#endif
	}

	void ConsumeDebugText(float DeltaTime, FString& OutText)
	{
	#if TEST
		const float GameTime = Time::GetGameTimeSeconds();
		for(int i = DebugTextArray.Num() - 1; i >= 0; --i)
		{
			OutText += DebugTextArray[i].Text;
			OutText += "\n";
			DebugTextArray[i].TimeLeft -= DeltaTime;
			if(DebugTextArray[i].TimeLeft <= 0)
			{
				DebugTextArray.RemoveAt(i);
			}
		}
	#endif
	}

	void TriggerActionEvent(EBullBossEventTags EventType)
	{
		if(EventType != EBullBossEventTags::MAX)
		{
			OnActionEvent.Broadcast(EventType);
		}
	}

	UFUNCTION()
	void WaitForValidNetworkTransition(FOnAnimationValidationComplete OnComplete)
	{
		if(Mesh.CurrentFeatureHasPendingNetworkTransitions())
		{
			bIsWaitingForNetworkAnimationValidation = true;
			OnPendingAnimationValidationComplete.AddUFunction(OnComplete.GetUObject(), OnComplete.GetFunctionName());
		}
		else
		{
			OnComplete.ExecuteIfBound();
		}
	}

};



struct FBullSetupMovementParams
{
	FBullSetupMovementParams(AClockworkBullBoss Bull, const FVector& Target)
	{
		CollisionRadius = Bull.CapsuleComponent.CapsuleRadius;
		BullLocation = Bull.GetActorLocation();	
		BullLocation.Z += CollisionRadius;
		SetTargetLocation(Target);
		FacingDirection = Bull.GetActorForwardVector();
	}

	FVector FixupLocation(const FVector Loc)const
	{
		return FVector(Loc.X, Loc.Y, BullLocation.Z);
	}

	FVector GetHorizontalDirToTarget()const property
	{
		return HorDirToTarget;
	}

	FVector GetTargetLocation()const property
	{
		return FinalTargetLocation;
	}

	void SetTargetLocation(FVector Value) property
	{
		FinalTargetLocation = FixupLocation(Value);
		HorDirToTarget = (FinalTargetLocation - BullLocation).GetSafeNormal();
		if(HorDirToTarget.IsNearlyZero())
			HorDirToTarget = FacingDirection;
	}
	
	bool InsideRangeOfTarget(float ValidDistance = 0.f)const
	{
		return BullLocation.DistSquared(FinalTargetLocation) <= FMath::Square(CollisionRadius + ValidDistance);
	}

	const float CollisionRadius = 0;
	const FVector BullLocation;
	const FVector InitialTargetLocation;
	const FVector FacingDirection;

	private FVector FinalTargetLocation = FVector::ZeroVector;
	private FVector HorDirToTarget = FVector::ZeroVector;
	
};