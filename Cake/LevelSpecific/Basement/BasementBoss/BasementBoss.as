import Peanuts.Health.BossHealthBarWidget;
import Cake.LevelSpecific.Basement.BasementBoss.BasementBossWeakPoint;
import Cake.LevelSpecific.Basement.BasementBoss.ShadowWall;
import Cake.LevelSpecific.Basement.BasementBoss.BasementBossShootingTarget;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.Interactions.ParentBlobKineticBackpack;

event void FFearBossAttackEvent();
event void FFearBossTakenDamageEvent(EBasementBossPhase Phase);

UCLASS(Abstract)
class ABasementBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase BossMesh;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;

	float Health = 1.f;

	UPROPERTY()
	FFearBossAttackEvent OnSweepAttackHit;

	UPROPERTY()
	FFearBossTakenDamageEvent OnTakenDamage;

	UPROPERTY()
	AShadowWall ShadowWall;

	UPROPERTY()
	ABasementBossShootingTarget ShootingTarget;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet AttackSheet;

	UPROPERTY()
	int CurrentPhaseIndex = 0;

	UPROPERTY()
	EBasementBossPhase CurrentPhase = EBasementBossPhase::Bat;

	float ShadowWallDelay = 10.5f;
	FTimerHandle ShadowWallTimerHandle;

	FTimerHandle HandAttackTimerHandle;
	FTimerHandle HandRecoveryTimerHandle;
	bool bSpawnHands = false;

	UPROPERTY(BlueprintReadOnly)
	bool bLeftSweep = false;

	bool bCanTakeDamage = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(AttackSheet);

		TArray<AParentBlobKineticBackpack> Backpacks;
		GetAllActorsOfClass(Backpacks);
		for (AParentBlobKineticBackpack CurBackpack : Backpacks)
		{
			CurBackpack.Interaction.OnCompleted.AddUFunction(this, n"BackpackCompleted");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void BackpackCompleted(FParentBlobKineticInteractionCompletedDelegateData Data)
	{
		if (!bCanTakeDamage)
			return;

		bCanTakeDamage = false;
		OnTakenDamage.Broadcast(CurrentPhase);
		TriggerRetreat();

		if (HealthBarWidget != nullptr)
		{
			Health -= 0.25f;
			HealthBarWidget.TakeDamage(0.25f);
			if (Health <= 0.f)
				System::SetTimer(this, n"RemoveHealthBar", 1.5f, false);
		}
	}

	UFUNCTION()
	void SetCanTakeDamage(bool bTrue)
	{
		bCanTakeDamage = bTrue;
	}

	UFUNCTION()
	void AddHealthBar(float InitialHealth = 1.f)
	{
		FText BossName = NSLOCTEXT("BasementBoss", "Name", "Deepest Darkest Fear");
		HealthBarWidget = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarClass));
		HealthBarWidget.InitBossHealthBar(BossName, 1.f, 4);
		HealthBarWidget.SnapHealthTo(InitialHealth);
		Health = InitialHealth;
	}

	UFUNCTION()
	void RemoveHealthBar()
	{
		if (HealthBarWidget == nullptr)
			return;

		Widget::RemoveFullscreenWidget(HealthBarWidget);
	}

	UFUNCTION()
	void UpdateCurrentPhase(EBasementBossPhase Phase)
	{
		CurrentPhase = Phase;
	}

	UFUNCTION()
	void TriggerAttack()
	{
		BossMesh.SetAnimBoolParam(n"Attack", true);
	}

	UFUNCTION()
	void TriggerBatAttack()
	{
		if (CurrentPhase == EBasementBossPhase::Bat)
		{
			BossMesh.SetAnimBoolParam(n"Attack", true);

			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Actor = this;
			PoISettings.FocusTarget.WorldOffset = FVector(0.f, 0.f, 2000.f);
			PoISettings.Duration = 5.f;
			PoISettings.Blend.BlendTime = 4.f;

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				Player.ApplyPointOfInterest(PoISettings, this);
			}
		}
	}

	UFUNCTION()
	void StartShadowWallSequence()
	{
		BossMesh.SetAnimBoolParam(n"Attack", true);
		
		ShadowWallTimerHandle = System::SetTimer(this, n"TriggerShadowWallAttack", ShadowWallDelay, true);
	}

	UFUNCTION()
	void TriggerShadowWallAttack()
	{
		BossMesh.SetAnimBoolParam(n"Attack", true);
	}

	void SpawnShadowWall()
	{
		ShadowWall.ActivateShadowWall();
	}

	UFUNCTION()
	void StartSpawningHands()
	{
		bSpawnHands = true;
		System::SetTimer(this, n"TriggerHandAttack", 1.55f, false);
	}

	UFUNCTION()
	void StopSpawningHands()
	{
		bSpawnHands = false;
	}

	UFUNCTION()
	void TriggerHandAttack()
	{
		if (!bSpawnHands)	
			return;

		BossMesh.SetAnimBoolParam(n"Attack", true);
		HandRecoveryTimerHandle = System::SetTimer(this, n"TriggerHandRecovery", 1.5f, false);
	}

	UFUNCTION()
	void TriggerHandRecovery()
	{
		BossMesh.SetAnimBoolParam(n"RecoverArm", true);
		HandAttackTimerHandle = System::SetTimer(this, n"TriggerHandAttack", 1.5, false);
	}

	UFUNCTION()
	void TriggerRetreat()
	{
		CurrentPhaseIndex++;
		CurrentPhase++;
		SetCapabilityActionState(n"InterruptAttack", EHazeActionState::ActiveForOneFrame);
		BossMesh.SetAnimBoolParam(n"Retreat", true);
	}

	UFUNCTION()
	void InterruptAttack()
	{
		BossMesh.SetAnimBoolParam(n"Interrupt", true);
		System::ClearAndInvalidateTimerHandle(ShadowWallTimerHandle);
	}
}

enum EBasementBossPhase
{
	Bat,
	Breath,
	Sweep,
	Tsunami,
	Hands
}