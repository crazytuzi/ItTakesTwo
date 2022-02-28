
import Vino.Movement.Components.MovementComponent;
import Vino.Checkpoints.Statics.LivesStatics;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantImpactComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Peanuts.Movement.GroundTraceFunctions;


event void FOnKilledWithSickle(ASickleEnemy Actor, bool bIsAlsoRemoved);
event void FPlayerCombatAreaEvent(ASickleEnemyMovementArea Area, AHazePlayerCharacter Player);
event void FSickleEnemySpawnManagerActivated();
event void FPlayerCombatAreaCompleteEvent(ASickleEnemyMovementArea Area);
event void FOnKilledInArea(ASickleEnemy EnemyKilled, AHazePlayerCharacter Killer);

import bool BindAreaOnCompleteEvent(ASickleEnemyMovementArea Area, AHazeActor ComponentOwner) from "Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent";
import FString GetSpawnManagerDebugInfo(ASickleEnemyMovementArea Area, AHazeActor ComponentOwner, bool bExtendedEnemyInfo) from "Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent";
import bool ShouldDelaySickleEnemyDestruction(ASickleEnemy Enemy) from "Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent";
import void InitalizeDelayDeath(ASickleEnemy Enemy) from "Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyDead";

bool OwnerIsSickleEnemeyAndDead(const UVineImpactComponent ImpactComponent)
{
	auto Enemy = Cast<ASickleEnemy>(ImpactComponent.Owner);
	if(Enemy != nullptr && !Enemy.IsAlive())
		return true;

	return false;
}

void GetAllCutableComponents(TArray<USickleCuttableComponent>& Components)
{
	TArray<ASickleEnemy> Enemies;
	GetAllActorsOfClass(Enemies);
	for(auto Enemy : Enemies)
	{
		Components.Add(USickleCuttableComponent::Get(Enemy));
	}
}

struct FBlockAttackInstigator 
{
	UObject Instigator;
	float DelayTime;
}

// The standard class for sickle enemy
UCLASS(Abstract, Meta = (AutoExpandCategories = "AiSettings"))
class ASickleEnemy : AHazeCharacter
{ 
	default ReplicateAsMovingActor();
	
	default CapsuleComponent.SetCollisionProfileName(n"GardenNPC");

	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.bComponentUseFixedSkelBounds = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USickleCuttableHealthComponent SickleCuttableComp;

	UPROPERTY(DefaultComponent)
	UTurretPlantImpactComponent TurretPlantImpactComp;

	/* Triggers 2 times. First, when the final strike happens,
	 * Second when the actor is removed after the death delay
	*/
	UPROPERTY()
	FOnKilledWithSickle OnKilled;

	// UPROPERTY(DefaultComponent, Attach = "Mesh")
	// UVineImpactComponent VineImpactComp;
	// default VineImpactComp.AttachmentMode = EVineAttachmentType::Component;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTargetComponent;
	default AutoAimTargetComponent.AffectsPlayers = EHazeSelectPlayer::Cody;
	default AutoAimTargetComponent.bUseVariableAutoAimMaxAngle = true;
	default AutoAimTargetComponent.AutoAimMaxAngleMinDistance = 20.f;
	default AutoAimTargetComponent.AutoAimMaxAngleAtMaxDistance = 2.f;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.CrumbDebugRadius = 200.f;

	UPROPERTY(Category = "Rendering")
	float MeshCullDistance = 10000.f;

	// Animation Params
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAttackingPlayer = false;

	float LastAttackTime = 0;

	// Animation Params, true when the player starts the attack against the enemy
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsBeeingHitBySickle = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float LastDamageAmount = 0;

	// Animation Params, true when the player starts the attack against the enemy
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FName ActiveSickleComboTag = NAME_None;

	// Animation Params, true when the vine has hit or is holding the enemy
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsBeeingHitByVine = false;

	// If the enemy dont belong to a spawnmanager, you need to setup its movearea
	UPROPERTY(EditInstanceOnly)
	ASickleEnemyMovementArea AreaToMoveIn;

	// If true, this actor is not allowed to leave this area
	UPROPERTY(EditDefaultsOnly)
	bool bLockToArea = true;

	// If you want the enemy to only be able to move inside another area then the combat area, use this
	UPROPERTY(EditInstanceOnly)
	ASickleEnemyRestrictedMovementArea RestrictedAreaToMoveIn;

	UPROPERTY(EditDefaultsOnly)
	FVector HealthBarPositionOffset = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<USickleEnemySpawningEffect> SpawnEffectClass;

	private USickleEnemyComponentBase AiSettings;
	private USickleEnemyComponentBase AiComponentBase;

	FHazeFrameMovement TotalCollectedMovement;
	bool bHasMovementData = false;

	bool bIsSpawning = false;
	FVector InitialLocation = FVector::ZeroVector;
	FName TeamName;

	private FRandomStream RandomStream;
	private float CurrentStunnedDuration = 0;
	private float BlockMovementDuration = 0;

	private TArray<UObject> MovementIsBlockedInstigators;
	private TArray<FBlockAttackInstigator> AttackIsBlockedInstigators;
	
	bool bIsTakingSickleDamage = false;
	bool bIsTakingWhipDamage = false;
	bool bHasDelayedDeath = false;

	EHazePlayer LastValidAttacker = EHazePlayer::MAX;
	bool bParticipatingInCombat = false;
	bool bInvalidSpawn = false;

		
	bool bHasPendingExitTurretPlantDamage = false;
	float PendingExitTurretPlantDamage = 0;


	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		auto VineImpactComp = UVineImpactComponent::Get(this);
		if(VineImpactComp != nullptr)
		{
			AutoAimTargetComponent.AttachToComponent(VineImpactComp);
		}
	}

	void InitializeMovementForNextFrame(bool bForced = false)
	{
		if(bForced || TotalCollectedMovement.Instigator == NAME_None)
		{
			TotalCollectedMovement = AiComponentBase.MakeFrameMovement(n"SickleEnemyMovement");
		}
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		AiSettings = USickleEnemyComponentBase::Get(this);
		if(AiSettings == nullptr)
			PrintError("" + GetName() + " is missing ai settings component");

		InitialLocation = GetActorLocation();

		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnSickleDamageReceived");
		TurretPlantImpactComp.OnTurretPlantImpact.AddUFunction(this, n"BeeingAttackedByTurretPlant");
		
		auto VineImpactComp = UVineImpactComponent::Get(this);
		if(VineImpactComp != nullptr)
		{
			AutoAimTargetComponent.AttachToComponent(VineImpactComp);
			VineImpactComp.OnVineConnected.AddUFunction(this, n"VineConnected");
			VineImpactComp.OnVineDisconnected.AddUFunction(this, n"VineDisconnected");
			VineImpactComp.OnVineWhipped.AddUFunction(this, n"VineWhipped");
		}
	
		Mesh.SetCullDistance(MeshCullDistance);

		AiComponentBase = USickleEnemyComponentBase::Get(this);

		if(AreaToMoveIn != nullptr)
			AreaToMoveIn.EnemyAdded(this);
		
		if(Network::IsNetworked())
			bHasDelayedDeath = ShouldDelaySickleEnemyDestruction(this);

		bParticipatingInCombat = true;
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// This will clear the invulerability
		float TempDamageValue;
		ConsumeExitTurretPlantDamage(TempDamageValue);

		RemoveFromCombat();
	}

	bool SetupPendingExitTurretPlantDamage(
		AHazePlayerCharacter Player, 
		float DamageAmount)
	{
		if(bHasPendingExitTurretPlantDamage)
			return true;

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
		if(!HealthComp.CanTakeDamage())
			return false;
		
		if(!HealthComp.WouldDieFromDamage(DamageAmount))
			return false;

		bHasPendingExitTurretPlantDamage = true;
		PendingExitTurretPlantDamage = DamageAmount;
		Player.AddPlayerInvulnerability(this);
		return true;
	}

	bool ConsumeExitTurretPlantDamage(float& OutDamage)
	{
		if(!bHasPendingExitTurretPlantDamage)
			return false;

		auto Player = Game::GetCody();
		if(Player == nullptr)
			return false;

		bHasPendingExitTurretPlantDamage = false;
		OutDamage = PendingExitTurretPlantDamage;
	
		Player.RemovePlayerInvulnerability(this);
		return OutDamage > 0;
	}

	bool IsEnemyValid() const
	{
		if(IsActorBeingDestroyed())
			return false;
		if(AiSettings == nullptr)
			return false;
		return true;
	}

	private void RemoveFromCombat()
	{
		if(!bParticipatingInCombat)
			return;

		bParticipatingInCombat = false;
		if(TeamName != NAME_None)
		{
			LeaveTeam(TeamName);
			TeamName = NAME_None;
		}

		if(AreaToMoveIn != nullptr)
			AreaToMoveIn.EnemyLost(this);
	}

	bool GetIsTakingDamage()const
	{
		return bIsTakingWhipDamage || bIsTakingSickleDamage;
	}

	void InitializeRandomSeed(int Index)
	{
		RandomStream.Initialize(Index * 1000);
	}

	float RandRange(float Min, float Max) const
	{
		return RandomStream.RandRange(Min, Max);
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentStunnedDuration = FMath::Max(CurrentStunnedDuration - DeltaTime, 0.f);

		// -1 is inifnite
		if(AiComponentBase.CanChangeTargetTimeLeft > 0)
		{
			AiComponentBase.CanChangeTargetTimeLeft = FMath::Max(AiComponentBase.CanChangeTargetTimeLeft - DeltaTime, 0.f);
		}	

		// -1 is inifnite
		if(BlockMovementDuration > 0)
		{
			BlockMovementDuration = FMath::Max(BlockMovementDuration - DeltaTime, 0.f);
		}

		// // -1 is inifnite
		// if(BlockAttackDuration > 0)
		// {
		// 	BlockAttackDuration = FMath::Max(BlockAttackDuration - DeltaTime, 0.f);
		// }

		for(int i = AttackIsBlockedInstigators.Num() - 1; i >= 0; --i)
		{
			if(AttackIsBlockedInstigators[i].Instigator == nullptr)
			{
				AttackIsBlockedInstigators.RemoveAtSwap(i);
			}

			if(AttackIsBlockedInstigators[i].DelayTime > 0)
			{
				AttackIsBlockedInstigators[i].DelayTime -= DeltaTime;
				if(AttackIsBlockedInstigators[i].DelayTime <= 0)
				{
					AttackIsBlockedInstigators.RemoveAtSwap(i);
				}
			}
		}
	
#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			FVector UpVector = GetMovementWorldUp();
			FVector From = GetActorLocation() + (UpVector * 100.f);
			FVector To = From - (UpVector * 800.f);
			System::DrawDebugCylinder(From, To, AiSettings.AttackDistance, LineColor = FLinearColor::Red, Thickness = 6);

			PrintToScreen("Can Attack: "  + CanAttack());
			PrintToScreen("Can Move: "  + CanMove());
		}	
#endif

	}

	AHazePlayerCharacter GetCurrentTarget()const property
	{
		if(AiComponentBase.CurrentPlayerTarget != nullptr)
		{
			float Multiplier = 1.f;
			if(!CanBeTargeted(AiComponentBase.CurrentPlayerTarget, Multiplier))
				return nullptr;
		}

		return AiComponentBase.CurrentPlayerTarget;
	}

	bool CanBeTargeted(AHazePlayerCharacter Player, float& OutDistanceMultiplier)const
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
		
		if(!HealthComp.AreDeathEffectsFinished())
			return false;
		
		if (HealthComp.bIsDead)
			return false;

		if(Player.IsCody())
		{
			if(Game::GetCody().Tags.Contains(n"ControllingJoy") == true)
				return false;
			
			auto PlantComp = UControllablePlantsComponent::Get(Player);
			if(PlantComp != nullptr && PlantComp.CurrentPlant != nullptr)
			{
				if(PlantComp.CurrentPlant == Cast<ATomato>(PlantComp.CurrentPlant))
					return true;

				if(PlantComp.CurrentPlant == Cast<ATurretPlant>(PlantComp.CurrentPlant))
				{
					float OtherPlayerMultiplier;
					if(!AiComponentBase.bIgnoreCodyIfTurretPlantAndBothPlayersAreAlive 
						|| !CanBeTargeted(Player.GetOtherPlayer(), OtherPlayerMultiplier))
					{
						OutDistanceMultiplier = 4.f;
						return true;
					}
				}

				return false;
			}
		}

		return true;
	}

	void SetPlayerAsTarget(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		if(Player == AiComponentBase.CurrentPlayerTarget)
			return;

		if(AiComponentBase.CanChangeTargetTimeLeft != 0.f && Player != nullptr)
			return;

		if(AiComponentBase.CurrentPlayerTarget == nullptr)
			AiComponentBase.CanChangeTargetTimeLeft = AiSettings.ChangeTargetDelayTime;
		else
			AiComponentBase.CanChangeTargetTimeLeft = AiSettings.ChangeTargetDelayTime * 0.5f;

		AiComponentBase.SetPlayerAsTargetInternal(Player);
	}

	void LockPlayerAsTarget(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		AiComponentBase.CanChangeTargetTimeLeft = -1;

		if(Player == AiComponentBase.CurrentPlayerTarget)
			return;

		AiComponentBase.SetPlayerAsTargetInternal(Player);
	}

	void BlockTargetPicking()
	{
		if(HasControl())
		{
			AiComponentBase.CanChangeTargetTimeLeft = -1;
			AiComponentBase.SetPlayerAsTargetInternal(nullptr);
		}

	}

	void UnblockTargetPicking()
	{
		if(HasControl() && AiComponentBase.CanChangeTargetTimeLeft < 0)
		{
			AiComponentBase.CanChangeTargetTimeLeft = 0;
		}
	}

	void SetFreeTargeting()
	{
		if(!HasControl())
			return;

		if(AiComponentBase.CanChangeTargetTimeLeft > 0)
			return;

		AiComponentBase.CanChangeTargetTimeLeft = AiSettings.ChangeTargetDelayTime;
	}

	UFUNCTION(NotBlueprintCallable)
	void VineConnected()
	{
		bIsBeeingHitByVine = true;
		this.SetCapabilityActionState(n"AudioVineConnected", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void VineDisconnected()
	{
		bIsBeeingHitByVine = false;
		this.SetCapabilityActionState(n"AudioVineDisconnected", EHazeActionState::ActiveForOneFrame);		
	}

	UFUNCTION(NotBlueprintCallable)
	void VineWhipped()
	{
		SetCapabilityActionState(GardenSickle::TriggerVineWhip, EHazeActionState::ActiveForOneFrame);
		Mesh.SetAnimBoolParam(n"VineWhip", true);
	}

	// this bind is not networked
	UFUNCTION(NotBlueprintCallable)
	void BeeingAttackedByTurretPlant(FTurretPlantHitInfo HitInfo)
	{
		OnTurretPlantDamageReceived(HitInfo.DamageAmount, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSickleDamageReceived(int DamageAmount)
	{
		bIsTakingSickleDamage = true;
		LastDamageAmount = DamageAmount;
		LastValidAttacker = EHazePlayer::May;
		SetAnimBoolParam(n"IsTakingDamage", true);
		SpawnBloodDecal();

		if(SickleCuttableComp.Health > 0 && DamageAmount > 0)
		{
			SetCapabilityActionState(n"AudioSickleDamage", EHazeActionState::ActiveForOneFrame);
		}

		if(SickleCuttableComp.Health <= 0 && !AiSettings.bHasBeenKilled)
		{
			AiSettings.Killed();
			SickleCuttableComp.bOwnerIsDead = true;
			BlockCapabilities(n"SickleEnemyAlive", this);
			CrumbComponent.LockTrail(this, false, true);
			BlockMovementSyncronization(this);
			OnKilled.Broadcast(this, false);
			if(AreaToMoveIn != nullptr)
			{
				AreaToMoveIn.OnEnemyKilled.Broadcast(this, Game::GetMay());
			}

			System::SetTimer(this, n"FinalizeDeath", AiSettings.SickleDeathDelay, false);

			SetCapabilityActionState(n"AudioSickleKill", EHazeActionState::ActiveForOneFrame);
		}
	}

	void OnWhipDamageReceived(int DamageAmount, bool bInvulerable)
	{
		SickleCuttableComp.ApplyDamage(DamageAmount, Game::GetCody(), bInvulerable);

		bIsTakingWhipDamage = true;
		LastDamageAmount = DamageAmount;
		LastValidAttacker = EHazePlayer::Cody;
		SetAnimBoolParam(n"IsTakingDamage", true);
		SpawnBloodDecal();

		if(SickleCuttableComp.Health > 0 && DamageAmount > 0)
		{
			SetCapabilityActionState(n"AudioVineDamage", EHazeActionState::ActiveForOneFrame);
		}

		if(SickleCuttableComp.Health <= 0 && !AiSettings.bHasBeenKilled)
		{
			AiSettings.bHasBeenKilled = true;
			SickleCuttableComp.bOwnerIsDead = true;
			BlockCapabilities(n"SickleEnemyAlive", this);
			CrumbComponent.LockTrail(this, false, true);
			BlockMovementSyncronization(this);
			OnKilled.Broadcast(this, false);
			if(AreaToMoveIn != nullptr)
			{
				AreaToMoveIn.OnEnemyKilled.Broadcast(this, Game::GetCody());
			}

			System::SetTimer(this, n"FinalizeDeath", AiSettings.WhipDeathDelay, false);

			SetCapabilityActionState(n"AudioVineKill", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnTurretPlantDamageReceived(int DamageAmount, bool bInvulerable)
	{
		SickleCuttableComp.ApplyDamage(DamageAmount, Game::GetCody(), bInvulerable);

		LastDamageAmount = DamageAmount;
		LastValidAttacker = EHazePlayer::Cody;
		SetAnimBoolParam(n"IsTakingDamage", true);
		SpawnBloodDecal();

		if(SickleCuttableComp.Health > 0)
		{
			SetCapabilityActionState(n"AudioTurretDamage", EHazeActionState::ActiveForOneFrame);
		}

		if(SickleCuttableComp.Health > 0 && DamageAmount == 0)
		{
			SetCapabilityActionState(n"AudioTurretShieldBlock", EHazeActionState::ActiveForOneFrame);
		}

		if(SickleCuttableComp.Health <= 0 && !AiSettings.bHasBeenKilled)
		{
			AiSettings.bHasBeenKilled = true;
			SickleCuttableComp.bOwnerIsDead = true;
			BlockCapabilities(n"SickleEnemyAlive", this);
			CrumbComponent.LockTrail(this, false, true);
			BlockMovementSyncronization(this);
			OnKilled.Broadcast(this, false);
			if(AreaToMoveIn != nullptr)
			{
				AreaToMoveIn.OnEnemyKilled.Broadcast(this, Game::GetCody());
			}

			System::SetTimer(this, n"FinalizeDeath", AiSettings.TurretPlantDeathDelay, false);

			SetCapabilityActionState(n"AudioTurretKill", EHazeActionState::ActiveForOneFrame);
		}
	}

	void SpawnBloodDecal()
	{
		auto SickleComponent = USickleComponent::Get(Game::GetMay());
		SickleComponent.EnableBloodDecal(GetActorTransform());
	}

	UFUNCTION()
	void ManuallyKillEnemy(bool bInstant = false)
	{
		if(AiSettings.bHasBeenKilled)
			return;

		if(bInstant)
		{
			AiSettings.bHasBeenKilled = true;
			SickleCuttableComp.bOwnerIsDead = true;
			BlockCapabilities(n"SickleEnemyAlive", this);
			CrumbComponent.LockTrail(this, false, true);
			BlockMovementSyncronization(this);
			OnKilled.Broadcast(this, false);
			if(AreaToMoveIn != nullptr)
			{
				AreaToMoveIn.OnEnemyKilled.Broadcast(this, nullptr);
			}

			System::SetTimer(this, n"FinalizeDeath", 0.1f, false);
			SetCapabilityActionState(n"AudioForceKill", EHazeActionState::ActiveForOneFrame);
		}
		else
		{

			SickleCuttableComp.ApplyDamage(SickleCuttableComp.Health, nullptr, false);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetManuallyKillEnemy()
	{
		Log("Force kill: " + this);
		ManuallyKillEnemy();
	}

	void KilledByTomato()
	{
		if(!AiSettings.bHasBeenKilled)
		{
			SickleCuttableComp.ApplyDamage(SickleCuttableComp.Health, Game::GetCody(), false);
			bIsTakingSickleDamage = true;
			LastValidAttacker = EHazePlayer::Cody;
			AiSettings.bHasBeenKilled = true;
			SetAnimBoolParam(n"IsTakingDamage", true);
			SpawnBloodDecal();
			OnKilled.Broadcast(this, false);
			if(AreaToMoveIn != nullptr)
			{
				AreaToMoveIn.OnEnemyKilled.Broadcast(this, Game::GetCody());
			}

			SickleCuttableComp.bOwnerIsDead = true;	
			BlockCapabilities(n"SickleEnemyAlive", this);
			CrumbComponent.LockTrail(this, false, true);
			BlockMovementSyncronization(this);
			System::SetTimer(this, n"FinalizeDeath_FromTomato", 0.3f, false);
			SetCapabilityActionState(n"AudioTomatoKill", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FinalizeDeath_FromTomato()
	{
		OnKilled.Broadcast(this, true);
		if(!bHasDelayedDeath)
			DestroyActor();
		else
		{
			RemoveFromCombat();
			InitalizeDelayDeath(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FinalizeDeath()
	{
		OnKilled.Broadcast(this, true);
		if(AiSettings.DestroyEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiSettings.DestroyEffect, Mesh.GetSocketLocation(AiSettings.DestroyEffectAttachBoneName));

		if(!bHasDelayedDeath)
			DestroyActor();
		else
		{
			RemoveFromCombat();
			InitalizeDelayDeath(this);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsAlive() const
	{
		return SickleCuttableComp.Health > 0 || !AiComponentBase.bHasBeenKilled;
	}

	bool CanMove() const
	{
		if(GetIsTakingDamage())
			return false;

		if(CurrentStunnedDuration > 0)
			return false;

		if(BlockMovementDuration != 0)
			return false;

		if(bHasMovementData)
			return false;

		if(bIsSpawning)
			return false;
		
		for(int i = 0; i < MovementIsBlockedInstigators.Num(); ++i)
		{
			if(MovementIsBlockedInstigators[i] != nullptr)
				return false;
		}

		return true;
	}

	bool CanAttack() const
	{
		if(GetIsTakingDamage())
			return false;

		if(CurrentStunnedDuration > 0)
			return false;

		if(bIsBeeingHitByVine)
			return false;

		if(bIsSpawning)
			return false;

		for(int i = 0; i < AttackIsBlockedInstigators.Num(); ++i)
		{
			if(AttackIsBlockedInstigators[i].Instigator != nullptr)
				return false;
		}

		return true;
	}

	bool CanStandOn(FHitResult Ground) const
	{
		return IsHitSurfaceWalkableDefault(
			Ground, 
			AiComponentBase.WalkableAngle, 
			FVector::UpVector);
	}

	void ApplyStunnedDuration(float Amount)
	{
		CurrentStunnedDuration = FMath::Max(CurrentStunnedDuration, Amount);
	}

	void BlockMovement(float Duration)
	{
		BlockMovementDuration = FMath::Max(BlockMovementDuration, Duration);
	}

	void BlockMovementWithInstigator(UObject Blocker)
	{
		MovementIsBlockedInstigators.AddUnique(Blocker);
	}

	void UnblockMovementWithInstigator(UObject Blocker)
	{
		MovementIsBlockedInstigators.RemoveSwap(Blocker);
	}

	void BlockAttack(float Duration)
	{
		BlockAttackWithInstigator(this);
		if(Duration >= 0)
			UnblockAttackWithInstigator(this, Duration);
	}

	void BlockAttackWithInstigator(UObject Blocker)
	{
		// Check if we already have that blocker and reset the timer
		for(int i = 0; i < AttackIsBlockedInstigators.Num(); ++i)
		{
			if(AttackIsBlockedInstigators[i].Instigator == Blocker)
			{
				AttackIsBlockedInstigators[i].DelayTime = -1;
				return;
			}
		}

		FBlockAttackInstigator NewEntry;
		NewEntry.Instigator = Blocker;
		NewEntry.DelayTime = -1;
		AttackIsBlockedInstigators.Add(NewEntry);
	}
	
	void UnblockAttackWithInstigator(UObject Blocker, float DelayTime = 0)
	{
		int FoundIndex = -1;
		for(int i = 0; i < AttackIsBlockedInstigators.Num(); ++i)
		{
			if(AttackIsBlockedInstigators[i].Instigator == Blocker)
			{
				FoundIndex = i;
				break;
			}
		}

		if(FoundIndex < 0)
			return;

		if(DelayTime <= KINDA_SMALL_NUMBER)
		{
			AttackIsBlockedInstigators.RemoveAtSwap(FoundIndex);
		}
		else
		{
			AttackIsBlockedInstigators[FoundIndex].DelayTime = DelayTime;
		}
	}

	bool GetRandomLocationInShape(FVector& OutFoundLocation, float DistanceToTrace = -1, bool bUseBiggestDistance = false) const
	{	
		OutFoundLocation = GetActorLocation();
		if(!devEnsure(AreaToMoveIn != nullptr, GetName() + " has no area to move in."))
			return false;

		UBrushComponent Collision = nullptr;
		if(RestrictedAreaToMoveIn != nullptr)
			Collision = Cast<UBrushComponent>(RestrictedAreaToMoveIn.RootComponent);
		else
			Collision = Cast<UBrushComponent>(AreaToMoveIn.RootComponent);

		const float ActorRadius = GetCollisionSize().X;
		const FVector WorldUp = GetMovementWorldUp();

		// Use the entire shape
		float MaxDistanceToTrace = DistanceToTrace;
		if(MaxDistanceToTrace < 0)
		{
			FCollisionShape Shape = Collision.GetCollisionShape();
			MaxDistanceToTrace = Shape.GetExtent().Size();
		}

		const int PointsCount = 16;
		TArray<FVector> ValidPoints;
		ValidPoints.Reserve(PointsCount);

		FRotator TestRotation;
		float BiggestDistance = 0;
		int MostValidIndex = -1;
		const FVector CurrentLocation = GetActorLocation();

		for(int i = 0; i < PointsCount; ++i)
		{
			TestRotation.Yaw += 360 / PointsCount;
			FVector TestLocation = TestRotation.RotateVector(FVector(MaxDistanceToTrace, 0.f, 0.f));
			TestLocation += InitialLocation;

			Collision.GetClosestPointOnCollision(TestLocation, TestLocation);
			TestLocation += (Collision.GetWorldLocation() - TestLocation).GetSafeNormal() * GetCollisionSize().X * 2;

		#if EDITOR
			if(bHazeEditorOnlyDebugBool)
				System::DrawDebugSphere(TestLocation, Duration = 1, LineColor = FLinearColor::White);
		#endif

			float Distance = TestLocation.DistSquared2D(CurrentLocation, WorldUp);
			if(Distance > FMath::Square(ActorRadius * 1.5f))
			{
				ValidPoints.Add(TestLocation);
				if(Distance > BiggestDistance)
				{
					BiggestDistance = Distance;
					MostValidIndex = ValidPoints.Num() - 1;
				}
			}
		}

		if(ValidPoints.Num() > 0)
		{
			if(bUseBiggestDistance)
			{

			#if EDITOR
			if(bHazeEditorOnlyDebugBool)
				System::DrawDebugSphere(ValidPoints[MostValidIndex], Thickness = 4, Duration = 1, LineColor = FLinearColor::Red);
			#endif

				OutFoundLocation = ValidPoints[MostValidIndex];
				return true;
			}
			else
			{
				const int RandomIndex = FMath::RandRange(0, ValidPoints.Num() - 1);

			#if EDITOR
			if(bHazeEditorOnlyDebugBool)
				System::DrawDebugSphere(ValidPoints[RandomIndex], Thickness = 4, Duration = 1, LineColor = FLinearColor::Red);
			#endif

				OutFoundLocation = ValidPoints[RandomIndex];
				return true;
			}
		}

		return false;
	}

	bool GetBestMoveToPoint(FVector WantedLocation, FVector& OutFoundLocation) const
	{
		OutFoundLocation = WantedLocation;
		if(!devEnsure(AreaToMoveIn != nullptr, GetName() + " has no area to move in."))
			return false;

		UBrushComponent Collision = nullptr;
		if(RestrictedAreaToMoveIn != nullptr)
			Collision = Cast<UBrushComponent>(RestrictedAreaToMoveIn.RootComponent);
		else
			Collision = Cast<UBrushComponent>(AreaToMoveIn.RootComponent);

		const float Dist = Collision.GetClosestPointOnCollision(WantedLocation, OutFoundLocation);
		return Dist >= 0;
	}

	bool IsInsideMoveArea(FVector& OutFoundLocation) const
	{
		OutFoundLocation = GetActorLocation();
		if(!devEnsure(AreaToMoveIn != nullptr, GetName() + " has no area to move in."))
			return false;

		UBrushComponent Collision = nullptr;
		if(RestrictedAreaToMoveIn != nullptr)
			Collision = Cast<UBrushComponent>(RestrictedAreaToMoveIn.RootComponent);
		else
			Collision = Cast<UBrushComponent>(AreaToMoveIn.RootComponent);

		const float Dist = Collision.GetClosestPointOnCollision(OutFoundLocation, OutFoundLocation);
		if(Dist < 0) // No collision
			return true;
		return Dist < GetCollisionSize().X;
	}

	FVector GetAttackLocation() const
	{
		if(AiComponentBase.CurrentPlayerTarget != nullptr)
		{
			const FVector WorldUp = GetMovementWorldUp();
			const FVector TargetPosition = AiComponentBase.CurrentPlayerTarget.GetActorLocation();
			const FVector DirToTarget = (TargetPosition - GetActorLocation()).ConstrainToPlane(WorldUp).GetSafeNormal();
			
			return TargetPosition - (DirToTarget * (AiSettings.AttackDistance + GetCollisionSize().X + AiComponentBase.CurrentPlayerTarget.GetCollisionSize().X));
		}
		else
		{
			return GetActorLocation() + (GetActorForwardVector() * (AiSettings.AttackDistance + GetCollisionSize().X ));
		}
	}

	UFUNCTION(BlueprintPure)
	float GetAngleToAttacker() const
	{
		AHazePlayerCharacter Attacker = GetCurrentAttacker();
		if(Attacker != nullptr)
		{
			const FVector MyLocation = GetActorLocation();
			const FVector TargetLocation = Attacker.GetActorLocation();
			const FVector DirToTarget = (TargetLocation - MyLocation).ConstrainToPlane(GetMovementWorldUp()).GetSafeNormal();

			float Direction = 1;
			if(GetActorRightVector().DotProduct(DirToTarget) < 0)
				Direction = -Direction;
		
			if(DirToTarget.Size() > 0)
			{
				return FRotator::ClampAxis(Math::GetAngle(GetActorForwardVector(), DirToTarget) * Direction);
			}
				
		}
		
		return -1;	
	}

	float GetHorizontalDistanceToTarget(AHazePlayerCharacter PlayerTarget) const
	{
		const float SafetyAmount = 10.f;
		const float Distance = PlayerTarget.GetHorizontalDistanceTo(this);
		const float MyHorizotalCollisionSize = GetCollisionSize().X;
		const float TargetHorizotalCollisionSize = PlayerTarget.GetCollisionSize().X;
		return FMath::Max(Distance - MyHorizotalCollisionSize - TargetHorizotalCollisionSize - SafetyAmount, 0.f);
	}

	private AHazePlayerCharacter GetCurrentAttacker() const
	{
		if(LastValidAttacker != EHazePlayer::MAX)
			return Game::GetPlayer(LastValidAttacker);
		else
			return nullptr;
	}
}

// This is the restricted movement area. The ai will just move around in here
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication",)
class ASickleEnemyRestrictedMovementArea : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"Trigger");
	default bGenerateOverlapEventsDuringLevelStreaming = false;
	default BrushComponent.bGenerateOverlapEvents = false;

	/* Some enemies follow movement splines */
	UPROPERTY(EditInstanceOnly)
	TArray<AHazeSplineActor> MovementSplines;
}

// This is the combat area. The enemies will attack players inside this area
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication",)
class ASickleEnemyMovementArea : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"Trigger");
	default bGenerateOverlapEventsDuringLevelStreaming = true;
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickInterval = 1.f;

	/* If true, the enemies in this area will be counted
	 * and players entering the area will count as inside combat area
	*/
	UPROPERTY(EditInstanceOnly, Category = "Activation")
	bool bStartEnabled = true;

	/* If true, this area will complete when all enemies are dead
	*/
	UPROPERTY(EditInstanceOnly, Category = "Activation")
	bool bCanBeCompleted = true;

	/* If true, this area will trigger all audio connected events.
	*/
	UPROPERTY(EditInstanceOnly, Category = "Activation")
	bool bTriggerAudioEvents = true;

	/* The enemies that blocks the 'OnCombatComplete' from firing until they are complete.
	*/
	UPROPERTY(Transient, EditConst)
	TArray<ASickleEnemy> SickleEnemiesControlled;

	/* The spawnmanagers that blocks the 'OnCombatComplete' from firing until they are complete.
	*/
	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> SpawnManagersThatShouldComplete;

	UPROPERTY(Transient, EditConst)
	TArray<AHazePlayerCharacter> PlayersInArea;
	TArray<AHazePlayerCharacter> PlayersTriggeredCombat;

	UPROPERTY(Category = "Events")
	FPlayerCombatAreaEvent OnPlayerEnter;

	UPROPERTY(Category = "Events")
	FPlayerCombatAreaEvent OnPlayerExit;

	UPROPERTY(Category = "Events")
	FSickleEnemySpawnManagerActivated OnCombatActivated;

	UPROPERTY(Category = "Events")
	FPlayerCombatAreaCompleteEvent OnCombatComplete;

	UPROPERTY(Category = "Events")
	FOnKilledInArea OnEnemyKilled;

	bool bAreaIsUsedForCombat = false;
	bool bTriggeredAudioCombatState = false;
	bool bTriggeredAudioCombatStateDuringLoad = false;
	
	int CompleteSpawnManagerCount = 0;
	bool bHasBeenCompleted = false;

	UPROPERTY(Transient, NotEditable)
	TArray<AHazeActor> DebugSpawnManagers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bStartEnabled)
		{
			EnableAreaForCombat();
		}

		for(auto SpawnManagerActor : SpawnManagersThatShouldComplete)
		{
			if(!BindAreaOnCompleteEvent(this, SpawnManagerActor))
			{
				FString DebugText = "Cant bind the 'OnCombatComplete' event from ";
				DebugText += GetName();
				DebugText += " on ";
				if(SpawnManagerActor != nullptr)
					DebugText += SpawnManagerActor.GetName();
				else
					DebugText += "nullptr";
				DebugText += " because it dont have a spawnmanager component ";
				devEnsure(false, DebugText);
			}
		}

		// // Initially collect the actors
		// TArray<AActor> OverlappingActors;
		// GetOverlappingActors(OverlappingActors);
		// for(AActor OverlappingActor : OverlappingActors)
		// {
		// 	ActorBeginOverlap(OverlappingActor);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(auto Enemy : SickleEnemiesControlled)
		{
			if(Enemy == nullptr)
				continue;
			
			if(Enemy.AreaToMoveIn != this)
				continue;

			Enemy.AreaToMoveIn = nullptr;	
		}

		SetAudioExitedCombat();
		SickleEnemiesControlled.Empty();
		bAreaIsUsedForCombat = false;
	}

	void DrawDebug(bool bShowExtendedEnemyInfo)
	{
		if(!HasControl())
			return;

		FString DebugInfo = "";
		if(!bHasBeenCompleted)
		{
			DebugInfo += (bAreaIsUsedForCombat ? "(Active)" : "(Inactive)") + "\n";
			DebugInfo += "Active Enemies: " + SickleEnemiesControlled.Num() + "\n";

			if(DebugSpawnManagers.Num() > 0)
			{
				DebugInfo += "Waiting for spawnmanager to complete: " + (SpawnManagersThatShouldComplete.Num() - CompleteSpawnManagerCount) + "\n";
				for(auto SpawnManagerActor : DebugSpawnManagers)
				{
					DebugInfo += "\n* " + GetSpawnManagerDebugInfo(this, SpawnManagerActor, bShowExtendedEnemyInfo) + "\n";	
				}
			}
		}
		else
		{
			DebugInfo += "Completed: " + bHasBeenCompleted + "\n";
		}
		
		PrintToScreen(DebugInfo);
		
		FString Header = "Combat Area: " + GetName() + " ";
		PrintToScreenScaled(Header, Color = FLinearColor::Red, Scale = 1.5);

	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr && Player.HasControl())
		{
			NetAddPlayer(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr && Player.HasControl())
		{
			NetRemovePlayer(Player);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetAddPlayer(AHazePlayerCharacter Player)
	{
		if(PlayersInArea.AddUnique(Player))
		{
			if(bAreaIsUsedForCombat)
			{
				SetAudioEnteredArea();
				EnableCombatInternal(Player);
			}
		}	
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		if(PlayersInArea.RemoveSwap(Player))
		{
			SetAudioExitedArea();
			DisableCombatInternal(Player);
		}
	}

	private void EnableCombatInternal(AHazePlayerCharacter Player)
	{
		auto SickleComponent = USickleComponent::Get(Game::GetMay());
		if(SickleComponent == nullptr)
			return;

		if(PlayersTriggeredCombat.AddUnique(Player))
		{
			SickleComponent.EnableCombat(Player);
			OnPlayerEnter.Broadcast(this, Player);
			SetAudioEnteredCombat();
		}
	}

	private void DisableCombatInternal(AHazePlayerCharacter Player)
	{
		auto SickleComponent = USickleComponent::Get(Game::GetMay());
		if(SickleComponent == nullptr)
			return;

		if(PlayersTriggeredCombat.RemoveSwap(Player))
		{
			SickleComponent.DisableCombat(Player);
			OnPlayerExit.Broadcast(this, Player);
			SetAudioExitedCombat();
		}
	}

	// This will make the area used by the enemies and the players
	UFUNCTION()
	void EnableAreaForCombat()
	{
		if(bAreaIsUsedForCombat)
			return;

		if(!HasControl())
			return;

		NetEnableAreaForCombat(true);
	}

	// This will make the area not count as if it is on combat anymore
	UFUNCTION()
	void DisableAreaFromCombat()
	{
		if(!bAreaIsUsedForCombat)
			return;

		if(!HasControl())
			return;

		NetEnableAreaForCombat(false);
	}

	UFUNCTION(NetFunction)
	void NetEnableAreaForCombat(bool bStatus)
	{
		bAreaIsUsedForCombat = bStatus;

		if(bStatus)
		{
			SetActorTickEnabled(true);
			OnCombatActivated.Broadcast();	
			for(auto Player : PlayersInArea)
			{
				EnableCombatInternal(Player);
			}
		}
		else
		{
			SetActorTickEnabled(false);
			for(auto Player : PlayersInArea)
			{
				DisableCombatInternal(Player);
			}
		}
	}

	void EnemyAdded(ASickleEnemy NewEnemy)
	{
		if(SickleEnemiesControlled.AddUnique(NewEnemy))
		{
			NewEnemy.InitializeRandomSeed(SickleEnemiesControlled.Num());
		}
	}

	void EnemyLost(ASickleEnemy LostEnemy)
	{
		if(SickleEnemiesControlled.RemoveSwap(LostEnemy))
		{
			TryComplete();
		}
	}

	void TryComplete()
	{
		if(!bCanBeCompleted)
			return;
		if(bHasBeenCompleted)
			return;

		if(CompleteSpawnManagerCount < SpawnManagersThatShouldComplete.Num())
			return;

		if(SickleEnemiesControlled.Num() > 0)
			return;
		
		bHasBeenCompleted = true;
		SetAudioAllEnemiesDefeated();
		OnCombatComplete.Broadcast(this);
		DisableAreaFromCombat();
	}

	void OnSpawnManagerComplete()
	{
		CompleteSpawnManagerCount++;
		TryComplete();
	}

	
	void SetAudioEnteredArea() 
	{
		if (!bTriggerAudioEvents)
			return;

		if (PlayersInArea.Num() == 1)
			Game::GetMay().SetCapabilityActionState(GardenAudioActions::SickleAreaEntered, EHazeActionState::Active);
	}

	void SetAudioExitedArea() 
	{
		if (!bTriggerAudioEvents)
			return;
			
		if (PlayersInArea.Num() == 0)
 			Game::GetMay().SetCapabilityActionState(GardenAudioActions::SickleAreaExited, EHazeActionState::Active);
	}

	void SetAudioEnteredCombat() 
	{
		if (!bTriggerAudioEvents)
			return;

		if (!bTriggeredAudioCombatState) 
		{
			Game::GetMay().SetCapabilityActionState(GardenAudioActions::SickleAreaCombatActivated, EHazeActionState::Active);
			bTriggeredAudioCombatState = true;
		}
	}
	
	void SetAudioExitedCombat() 
	{
		if (!bTriggerAudioEvents)
			return;

		if (bTriggeredAudioCombatState)
		{
			Game::GetMay().SetCapabilityActionState(GardenAudioActions::SickleAreaCombatDeactivated, EHazeActionState::Active);
			bTriggeredAudioCombatState = false;	
		}
	}

	void SetAudioAllEnemiesDefeated() 
	{
		Game::GetMay().SetCapabilityActionState(GardenAudioActions::SickleAreaAllEnemiesDefeated, EHazeActionState::Active);
	}
}

UCLASS(Abstract)
class USickleEnemySpawningEffect : UObject
{
	ASickleEnemy Owner;

	void OnSpawned()
	{

	}

	void OnSpawnedComplete()
	{

	}

	void Tick(float DeltaTime)
	{
		
	}

	bool IsComplete() const
	{
		return true;
	}
}