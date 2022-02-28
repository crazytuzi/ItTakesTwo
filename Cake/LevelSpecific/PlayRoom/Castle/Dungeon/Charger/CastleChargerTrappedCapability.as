import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.CastleChargerTrap;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;

class UCastleChargerTrappedCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(n"CastleEnemyAI");
	default CapabilityTags.Add(n"ChargerTrap");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 11;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	ACastleEnemy Charger;
	UCastleEnemyChargerComponent ChargerComp;

	bool bKilled;
	float RespawnTimer = 3.f;
	float RespawnTracker;

	bool bWaitingForSyncRespawnHands = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Charger = Cast<ACastleEnemy>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ChargerComp.bChargerTrapped)
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if (ChargerComp.bDead)
		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Charger.BlockCapabilities(n"Movement", this);
		Charger.BlockCapabilities(n"CastleEnemyAI", this);
		Charger.BlockCapabilities(n"CastleEnemyKnockback", this);
		Charger.BlockCapabilities(n"CastleEnemyCharge", this);

		SpawnMissingHands();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Charger.UnblockCapabilities(n"Movement", this);
		Charger.UnblockCapabilities(n"CastleEnemyAI", this);
		Charger.UnblockCapabilities(n"CastleEnemyKnockback", this);
		Charger.UnblockCapabilities(n"CastleEnemyCharge", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CastleEnemyChargerTrapped");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"CastleEnemyChargerTrapped");
		}
		
		CrumbComp.LeaveMovementCrumb();
	}
	
	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector Velocity;
			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	void SpawnMissingHands()
	{
		if (!ChargerComp.ChargerHandType.IsValid())
			return;

		if (ChargerComp.ChargerHand1 == nullptr)
		{
			ChargerComp.ChargerHand1 = Cast<ACastleEnemy>(SpawnActor(ChargerComp.ChargerHandType, Charger.ActorLocation + (Charger.ActorRightVector * 450), bDeferredSpawn = true, Level = Owner.GetLevel()));
			ChargerComp.ChargerHand1.OnKilled.AddUFunction(this, n"OnHandKilled");
			ChargerComp.ChargerHand1.MakeNetworked(this, n"ChargerHand1_", ChargerComp.SpawnHandCounter1++);
			ChargerComp.ChargerHand1.BlockCapabilities(n"CastleEnemyMovement", this);
			
			// Never change control side!
			ChargerComp.ChargerHand1.bCanAggro = false; 
			ChargerComp.ChargerHand1.bChangeNetworkSideOnAggro = false;
			if (ChargerComp.bDead)
			{
				ChargerComp.ChargerHand1.bShowHealthBar = false;
				ChargerComp.ChargerHand1.bUnhittable = true;
			}

			FinishSpawningActor(ChargerComp.ChargerHand1);
			if (ChargerComp.bDead)
			{
				ChargerComp.ChargerHand1.bShowHealthBar = false;
				ChargerComp.ChargerHand1.bUnhittable = true;
			}
		}

		if (ChargerComp.ChargerHand2 == nullptr)
		{
			ChargerComp.ChargerHand2 = Cast<ACastleEnemy>(SpawnActor(ChargerComp.ChargerHandType, Charger.ActorLocation - (Charger.ActorRightVector * 450), bDeferredSpawn = true, Level = Owner.GetLevel()));
			ChargerComp.ChargerHand2.OnKilled.AddUFunction(this, n"OnHandKilled");
			ChargerComp.ChargerHand2.MakeNetworked(this, n"ChargerHand2_", ChargerComp.SpawnHandCounter2++);
			ChargerComp.ChargerHand2.BlockCapabilities(n"CastleEnemyMovement", this);

			// Never change control side!
			ChargerComp.ChargerHand2.bCanAggro = false; 
			ChargerComp.ChargerHand2.bChangeNetworkSideOnAggro = false;
			if (ChargerComp.bDead)
			{
				ChargerComp.ChargerHand2.bShowHealthBar = false;
				ChargerComp.ChargerHand2.bUnhittable = true;
			}

			FinishSpawningActor(ChargerComp.ChargerHand2);
			if (ChargerComp.bDead)
			{
				ChargerComp.ChargerHand2.bShowHealthBar = false;
				ChargerComp.ChargerHand2.bUnhittable = true;
			}
		}
	}

	UFUNCTION()
	void OnHandKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		// This is triggered by crumb delegate from hand control side
		if (ChargerComp.bHandHurt)
		{	
			if (HasControl())	
				NetKillCharger();
		}
		else
		{
			ChargerComp.bHandHurt = true;

			if (Enemy == ChargerComp.ChargerHand1)
			{
				ChargerComp.ChargerHand1 = nullptr;
				ChargerComp.bRightHandHurt = true;
			}

			if (Enemy == ChargerComp.ChargerHand2)
			{
				ChargerComp.ChargerHand2 = nullptr;
				ChargerComp.bRightHandHurt = false;
			}
			
			System::SetTimer(this, n"RespawnHand", RespawnTimer, false);
		}
	}

	UFUNCTION()
	void RespawnHand()
	{
		// Note that we now allow respawn of hands even when charge has died
		// since OnHandKilled is sent on hands actor channel 
		// If charger is dead we hide health bars for hands instead.
		if (!bWaitingForSyncRespawnHands)
		{
			bWaitingForSyncRespawnHands = true;
			Sync::FullSyncPoint(this, n"SyncedRespawnHand");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SyncedRespawnHand()
	{
		ChargerComp.bHandHurt = false;
		SpawnMissingHands();
		bWaitingForSyncRespawnHands = false;
	}

	void KillCharger()
	{
		ChargerComp.bDead = true;
		ChargerComp.Trap.OnChargerKilled.Broadcast();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetKillCharger()
	{
		Charger.SetActorEnableCollision(false);
		KillCharger();
	}
}