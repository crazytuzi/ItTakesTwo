import Peanuts.Health.BossHealthBarWidget;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBossSlam;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBossDebris;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBossMinefield;
import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

event void FOnVacuumBossTakenDamage();
event void FOnVacuumBossStunned();
event void FOnVacuumBossBombSequencePrepared();
event void FOnVacuumBossBombsLaunched();
event void FOnVacuumBossAttackSequencePrepared();
event void FOnVacuumBossHoseMounted(bool bLeftHose, AHazePlayerCharacter Player);
event void FVacuumBossMusicStateChangeEvent(EVacuumBossMusicState NewState);

UCLASS(Abstract, HideCategories = "Input Actor LOD Cooking Replication Debug")
class AVacuumBoss : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase BossMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent CollisionBox;
	default CollisionBox.BoxExtent = FVector(375.f, 600.f, 625.f);
	default CollisionBox.RelativeLocation = FVector(-50.f, 0.f, 800.f);
	default CollisionBox.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = LeftHand)
	UInteractionComponent LeftInteractionComp;
	default LeftInteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = RightHand)
	UInteractionComponent RightInteractionComp;
	default RightInteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = LeftHand)
	UNiagaraComponent LeftBlowEffect;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = RightHand)
	UNiagaraComponent RightBlowEffect;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = LeftHand)
	UNiagaraComponent LeftSuckEffect;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = RightHand)
	UNiagaraComponent RightSuckEffect;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = LeftHand)
	USceneComponent LeftAttachPoint;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = RightHand)
	USceneComponent RightAttachPoint;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftSuckSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightSuckSyncComp;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = LeftHand)
	UHazeAkComponent HazeAkCompLeftHand;

	UPROPERTY(DefaultComponent, Attach = BossMesh, AttachSocket = RightHand)
	UHazeAkComponent HazeAkCompRightHand;

	UPROPERTY(DefaultComponent, Attach = BossMesh)
	UHazeAkComponent HazeAkCompHead;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaunchBombAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CanExploEvent;

    UPROPERTY(Category = "Properties")
	EVacuumBossAttackMode NextAttackMode = EVacuumBossAttackMode::Bombs;
    EVacuumBossAttackMode CurrentAttackMode = EVacuumBossAttackMode::Bombs;

    UPROPERTY(Category = "Properties")
    float AttackSequencePause = 18.f;

	UPROPERTY(Category = "Properties")
	bool bLaunchBombsOnly = true;

    UPROPERTY(Category = "Properties")
    int MaximumBossHealth = 20.f;
    int CurrentBossHealth;

    UPROPERTY(Category = "Bombs")
    int AmountOfBombs = 5;

    UPROPERTY(Category = "Bombs")
    float BombLaunchDelay = 0.65f;

    UPROPERTY(Category = "Debris")
    int DebrisAmount = 10;
    int CurrentDebrisAmount = 0;

    UPROPERTY(Category = "Debris")
    float DebrisDelay = 1.f;

    UPROPERTY(Category = "Slam")
    int SlamAmount = 6;
    int CurrentSlamAmount = 0;

    UPROPERTY(Category = "Minefield")
    int MinefieldAmount = 16;
    int CurrentMinefieldAmount = 0;

    UPROPERTY(Category = "Minefield")
    float MinefieldDelay = 1.f;

    UPROPERTY(NotVisible)
    bool bStunned;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBar;

	UPROPERTY(EditDefaultsOnly)
	UVacuumVOBank VOBank;

    bool bPerformDoubleSlam = false;

	UPROPERTY()
	FOnVacuumBossTakenDamage OnVacuumBossTakenDamage;

    UPROPERTY()
    FOnVacuumBossStunned OnVacuumBossStunned;

    UPROPERTY()
    FOnVacuumBossBombSequencePrepared OnBombSequencePrepared;

    UPROPERTY()
    FOnVacuumBossAttackSequencePrepared OnAttackSequencePrepared;

    UPROPERTY()
    FOnVacuumBossBombsLaunched OnBombsLaunched;

	UPROPERTY()
	FOnVacuumBossHoseMounted OnHoseMounted;

	UPROPERTY()
	FVacuumBossMusicStateChangeEvent MusicStateChanged;

	UPROPERTY(EditDefaultsOnly, Category = "Slam")
	TSubclassOf<AVacuumBossSlam> SlamClass;
	TArray<AVacuumBossSlam> SlamActors;
	TArray<AVacuumBossSlam> AvailableSlamActors;

	UPROPERTY(EditDefaultsOnly, Category = "Bombs")
	TSubclassOf<AVacuumBossBomb> BombClass;
	TArray<AVacuumBossBomb> BombActors;
	TArray<AVacuumBossBomb> AvailableBombActors;
	TArray<AVacuumBossBomb> BombsTakenDamageFromThisPhase;
	FTimerHandle LeftBombHandle;
	FTimerHandle RightBombHandle;
	int AmountOfActiveBombs = 0;
	bool bAllBombsLaunched = false;

	UPROPERTY(EditDefaultsOnly, Category = "Debris")
	TSubclassOf<AVacuumBossDebris> DebrisClass;
	TArray<AVacuumBossDebris> DebrisActors;
	TArray<AVacuumBossDebris> AvailableDebrisActors;
	FTimerHandle MayDebrisTimerHandle;
	FTimerHandle CodyDebrisTimerHandle;
	
	UPROPERTY(Category = "Minefield")
	TArray<AVacuumBossMinefield> MinefieldActors;
	FTimerHandle MinefieldHandle;
	bool bLeftMinefield = true;
	UPROPERTY(EditDefaultsOnly, Category = "Minefield")
	TArray<FMinefieldSequence> MinefieldSequences;
	int CurrentMinefieldSequenceIndex = 0;
	bool bAllMinefieldsLaunched = false;

	FTimerHandle QueueAttackSequenceHandle;
	FTimerHandle DeactivateBackPlatformHandle;

	UPROPERTY()
	AVolume ReachableBombsArea;

	UPROPERTY(NotEditable)
	float LeftSuckValue = 0.f;
	UPROPERTY(NotEditable)
	float RightSuckValue = 0.f;
	bool bBothEyesSucked = false;
	int EyesSucked = 0;
	bool bOneArmSlightlyRaised = false;
	bool bOneArmMashStarted = false;
	bool bLeftArmIdle = true;
	bool bRightArmIdle = true;
	bool bMountArmBarkPlayed = false;
	FTimerHandle StunnedIdleBarkTimerHandle;
	FTimerHandle TubeSlightlyRaisedBarkTimerHandle;
	FTimerHandle ButtonMashBarkTimerHandle;

	UPROPERTY()
	FOnVacuumBossStunned OnBothEyesSucked;

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent LaunchMinefieldStartAudioEvent;

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent LaunchMinefieldStopAudioEvent;

	bool bEnrageTriggeredThisPhase = false;

	float MinimumBombSequenceDuration = 8.5f;
	float CurrentBombSequenceDuration = 0.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentBossHealth = MaximumBossHealth;

		for (int Index = 0, Count = 6; Index < Count; ++ Index)
		{
			AVacuumBossSlam CurSlam = Cast<AVacuumBossSlam>(SpawnActor(SlamClass, Level = GetLevel()));
			SlamActors.Add(CurSlam);
			CurSlam.MakeNetworked(this, Index);
		}

		AvailableSlamActors = SlamActors;

		for (int Index = 0, Count = AmountOfBombs * 2; Index < Count; ++ Index)
		{
			AVacuumBossBomb CurBomb = Cast<AVacuumBossBomb>(SpawnActor(BombClass, Level = GetLevel()));
			BombActors.Add(CurBomb);
			CurBomb.MakeNetworked(this, Index);
		}

		AvailableBombActors = BombActors;

		for (int Index = 0, Count = DebrisAmount; Index < Count; ++ Index)
		{
			AVacuumBossDebris CurDebris = Cast<AVacuumBossDebris>(SpawnActor(DebrisClass, Level = GetLevel()));
			DebrisActors.Add(CurDebris);
			CurDebris.Mesh.IgnoreActorWhenMoving(this, true);
			CurDebris.MakeNetworked(this, Index);
		}

		AvailableDebrisActors = DebrisActors;

		LeftInteractionComp.OnActivated.AddUFunction(this, n"LeftInteractionActivated");
		RightInteractionComp.OnActivated.AddUFunction(this, n"RightInteractionActivated");

		for (AVacuumBossMinefield CurMinefield : MinefieldActors)
			CurMinefield.SetBossMesh(BossMesh);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bStunned)
			return;

		if (CurrentAttackMode == EVacuumBossAttackMode::Bombs && HasControl())
		{
			CurrentBombSequenceDuration += DeltaTime;
		}

		if (CurrentAttackMode == EVacuumBossAttackMode::Bombs && bAllBombsLaunched && HasControl())
		{
			TArray<AActor> OverlappingActors;
			ReachableBombsArea.GetOverlappingActors(OverlappingActors, AVacuumBossBomb::StaticClass());

			bool bNoReachableBombs = true;
			for (AVacuumBossBomb CurBomb : BombActors)
			{
				if (CurBomb.bBeingLaunched || CurBomb.bShot || CurBomb.bGoingThroughHose)
					bNoReachableBombs = false;
				if (CurBomb.bLanded && CurBomb.IsOverlappingActor(ReachableBombsArea))
					bNoReachableBombs = false;
			}

			if (bNoReachableBombs)
			{
				if (bStunned)
					return;

				if (CurrentBombSequenceDuration <= MinimumBombSequenceDuration)
					return;

				DeactivateBackPlatform();
				QueueNextAttackSequence();
			}
		}
	}

	UFUNCTION()
	void BindPlayerDeathAndRespawnEvents()
	{
		FOnPlayerDied PlayerDiedDelegate;
		PlayerDiedDelegate.BindUFunction(this, n"PlayerDied");
		BindOnPlayerDiedEvent(PlayerDiedDelegate);
		
		FOnRespawnTriggered RespawnDelegate;
		RespawnDelegate.BindUFunction(this, n"PlayerRespawned");
		BindOnPlayerRespawnedEvent(RespawnDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerDied(AHazePlayerCharacter Player)
	{
		if (!bStunned)
			SetCapabilityActionState(n"FoghornVacuumBossKillTaunt", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		if (!bStunned)
			SetCapabilityActionState(n"FoghornVacuumBossRespawnTaunt", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void StartAttackSequence()
	{
		if (HasControl())
			NetStartAttackSequence(NextAttackMode);
	}

    UFUNCTION(NetFunction)
    void NetStartAttackSequence(EVacuumBossAttackMode AttackMode)
    {
		NextAttackMode = AttackMode;

        if (!bStunned)
        {
			if (bLaunchBombsOnly)
			{
				bPerformDoubleSlam = true;
				PrepareBombLaunch();
				Print("PREPARE IT!");
				return;
			}
			
            switch (NextAttackMode)
            {
            case EVacuumBossAttackMode::Debris:
                CurrentDebrisAmount = 0;
                StartDebrisLaunchSequence();
				MusicStateChanged.Broadcast(EVacuumBossMusicState::Debris);
            break;
            case EVacuumBossAttackMode::Slam:
                CurrentSlamAmount = 0;
                StartSlamSequence();
				MusicStateChanged.Broadcast(EVacuumBossMusicState::Slam);
            break;
            case EVacuumBossAttackMode::DebrisSlam:
				DebrisAmount /= 2;
				DebrisDelay *= 2;
                CurrentDebrisAmount = 0;
                CurrentSlamAmount = 0;
                StartSlamSequence();
                StartDebrisLaunchSequence();
				MusicStateChanged.Broadcast(EVacuumBossMusicState::DebrisSlam);
            break;
            case EVacuumBossAttackMode::Minefield:
                StartMinefieldSequence();
				MusicStateChanged.Broadcast(EVacuumBossMusicState::Minefield);
            break;
            }
        }
    }

    UFUNCTION()
    void QueueNextAttackSequence()
    {
		if (!HasControl())
			return;

		if (bStunned)
			return;

		System::ClearAndInvalidateTimerHandle(QueueAttackSequenceHandle);

        if (bPerformDoubleSlam)
        {
            NetTriggerDoubleSlam();
            System::SetTimer(this, n"StartAttackSequence", 1.75f, false);
        }
        else
        {
            StartAttackSequence();
        }
    }

	UFUNCTION()
	void DeactivateBackPlatform()
	{
		System::ClearAndInvalidateTimerHandle(DeactivateBackPlatformHandle);
		OnAttackSequencePrepared.Broadcast();
	}

    UFUNCTION()
    void StartDebrisLaunchSequence()
    {   
		if (bStunned)
			return;

		if (NextAttackMode != EVacuumBossAttackMode::DebrisSlam)
			CurrentAttackMode = EVacuumBossAttackMode::Debris;
		else
			CurrentAttackMode = EVacuumBossAttackMode::DebrisSlam;

		CodyDebrisTimerHandle = System::SetTimer(this, n"LaunchDebrisAtCody", DebrisDelay, true);
        MayDebrisTimerHandle = System::SetTimer(this, n"LaunchDebrisAtMay", DebrisDelay, true, DebrisDelay/2);

		SetEffectsActive(false, false);
    }

	UFUNCTION(NotBlueprintCallable)
	void LaunchDebrisAtCody()
	{
		if (bStunned)
			return;

		SetAnimBoolParam(n"FireDebris", true);
		AVacuumBossDebris Debris = AvailableDebrisActors[0];
		Debris.OnDebrisLanded.AddUFunction(this, n"AddDebrisToPool");
		FVector TargetLoc = FVector(Game::GetCody().ActorLocation.X, Game::GetCody().ActorLocation.Y, ActorLocation.Z);
        Debris.LaunchDebris(BossMesh.GetSocketLocation(n"Head"), TargetLoc);
		AvailableDebrisActors.Remove(Debris);

		CurrentDebrisAmount = CurrentDebrisAmount + 1;
	}

	UFUNCTION(NotBlueprintCallable)
	void LaunchDebrisAtMay()
	{
		if (bStunned)
			return;

		SetAnimBoolParam(n"FireDebris", true);
		AVacuumBossDebris Debris = AvailableDebrisActors[0];
		Debris.OnDebrisLanded.AddUFunction(this, n"AddDebrisToPool");
		FVector TargetLoc = FVector(Game::GetMay().ActorLocation.X, Game::GetMay().ActorLocation.Y, ActorLocation.Z);
        Debris.LaunchDebris(BossMesh.GetSocketLocation(n"Head"), TargetLoc);
		Debris.OnDebrisLanded.AddUFunction(this, n"AddDebrisToPool");
		AvailableDebrisActors.Remove(Debris);

		CurrentDebrisAmount = CurrentDebrisAmount + 1;
        
        if (CurrentDebrisAmount >= DebrisAmount * 2 && !bStunned)
        {
            PrepareBombLaunch();

			System::ClearAndInvalidateTimerHandle(CodyDebrisTimerHandle);
			System::ClearAndInvalidateTimerHandle(MayDebrisTimerHandle);

            if (CurrentAttackMode != EVacuumBossAttackMode::DebrisSlam)
            {
                NextAttackMode = EVacuumBossAttackMode::Slam;
                bPerformDoubleSlam = false;
            }
        }
	}

	UFUNCTION(NotBlueprintCallable)
	void AddDebrisToPool(AVacuumBossDebris Debris)
	{
		AvailableDebrisActors.Add(Debris);
	}

    UFUNCTION()
    void PrepareBombLaunch(float Delay = 2.f)
    {
        OnBombSequencePrepared.Broadcast();

        System::SetTimer(this, n"LaunchBombs", Delay, false);
    }

    UFUNCTION()
    void LaunchBombs()
    {
        if (!bStunned)
        {
			AvailableBombActors = BombActors;
			CurrentBombSequenceDuration = 0.f;
			bAllBombsLaunched = false;
			BombsTakenDamageFromThisPhase.Empty();
			CurrentAttackMode = EVacuumBossAttackMode::Bombs;
			RightBombHandle = System::SetTimer(this, n"SpawnRightBomb", BombLaunchDelay, true);
			LeftBombHandle = System::SetTimer(this, n"SpawnLeftBomb", BombLaunchDelay, true, BombLaunchDelay/2);
			MusicStateChanged.Broadcast(EVacuumBossMusicState::Bombs);

			if (bEnrageTriggeredThisPhase)
				bEnrageTriggeredThisPhase = false;

			SetEffectsActive(true, false);
        }
    }

	UFUNCTION()
	void SpawnRightBomb()
	{
		FVector SocketLocation = BossMesh.GetSocketLocation(n"RightHand");
		FRotator SocketRotation = BossMesh.GetSocketRotation(n"RightHand");
		AVacuumBossBomb Bomb = AvailableBombActors[0];

		HazeAkCompRightHand.HazePostEvent(LaunchBombAudioEvent);

        Bomb.CurrentTarget = Game::GetMay();
		if (Game::GetMay().HasControl())
        	Bomb.NetLaunchBomb(SocketLocation, Game::GetMay().ActorLocation, ActorLocation.Z, SocketRotation);
		SetAnimBoolParam(n"FireBombRight", true);
		Bomb.OnBombDestroyed.AddUFunction(this, n"AddBombToPool");
		AvailableBombActors.Remove(Bomb);

        AmountOfActiveBombs++;
	}

	UFUNCTION()
	void SpawnLeftBomb()
	{
		FVector SocketLocation = BossMesh.GetSocketLocation(n"LeftHand");
		FRotator SocketRotation = BossMesh.GetSocketRotation(n"LeftHand");
        AVacuumBossBomb Bomb = AvailableBombActors[0];

		HazeAkCompLeftHand.HazePostEvent(LaunchBombAudioEvent);

        Bomb.CurrentTarget = Game::GetCody();
		if (Game::GetCody().HasControl())
        	Bomb.NetLaunchBomb(SocketLocation, Game::GetCody().ActorLocation, ActorLocation.Z, SocketRotation);
		SetAnimBoolParam(n"FireBombLeft", true);
		Bomb.OnBombDestroyed.AddUFunction(this, n"AddBombToPool");
		AvailableBombActors.Remove(Bomb);

        AmountOfActiveBombs++;

        if (AmountOfActiveBombs >= AmountOfBombs * 2)
        {
            System::ClearAndInvalidateTimerHandle(LeftBombHandle);
			System::ClearAndInvalidateTimerHandle(RightBombHandle);
			AllBombsSpawned();
			QueueAttackSequenceHandle = System::SetTimer(this, n"QueueNextAttackSequence", AttackSequencePause, false);
			DeactivateBackPlatformHandle = System::SetTimer(this, n"DeactivateBackPlatform", AttackSequencePause - 2.f, false);
			AmountOfActiveBombs = 0;
			bAllBombsLaunched = true;
        }
	}

	UFUNCTION(NotBlueprintCallable)
	void AddBombToPool(AVacuumBossBomb Bomb)
	{
		AvailableBombActors.AddUnique(Bomb);
	}

    UFUNCTION()
    void AllBombsSpawned()
    {
        OnBombsLaunched.Broadcast();
		SetEffectsActive(false, false);
    }

    UFUNCTION()
    void StartSlamSequence()
    {
		if (NextAttackMode != EVacuumBossAttackMode::DebrisSlam)
		{
			CurrentAttackMode = EVacuumBossAttackMode::Slam;
			SetEffectsActive(false, false);
		}
    }

    UFUNCTION()
    void TriggerSlamAttack(bool bLeft)
    {
		if (bStunned)
			return;

		FVector SlamLoc = bLeft ? BossMesh.GetSocketLocation(n"LeftHand") : BossMesh.GetSocketLocation(n"RightHand");
		SlamLoc.Z = ActorLocation.Z;
		AvailableSlamActors[0].ActivateSlam(SlamLoc);
		AvailableSlamActors[0].OnSlamDeactivated.AddUFunction(this, n"AddSlamToPool");
		AvailableSlamActors.Remove(AvailableSlamActors[0]);

		if (CurrentSlamAmount >= SlamAmount || CurrentAttackMode == EVacuumBossAttackMode::DoubleSlam)
			return;

        CurrentSlamAmount += 1;

        if (CurrentSlamAmount >= SlamAmount && CurrentAttackMode != EVacuumBossAttackMode::DebrisSlam)
        {
            PrepareBombLaunch(1.f);
            NextAttackMode = EVacuumBossAttackMode::Minefield;
            bPerformDoubleSlam = true;
        }
    }

	UFUNCTION(NotBlueprintCallable)
	void AddSlamToPool(AVacuumBossSlam SlamActor)
	{
		AvailableSlamActors.Add(SlamActor);
	}

    UFUNCTION(NetFunction)
    void NetTriggerDoubleSlam()
    {
		CurrentAttackMode = EVacuumBossAttackMode::DoubleSlam;
		SetEffectsActive(false, false);
    }

    UFUNCTION()
    void StartMinefieldSequence()
    {
		if (!HasControl())
			return;

		if (CurrentMinefieldSequenceIndex == MinefieldSequences.Num() - 1)
			CurrentMinefieldSequenceIndex = 0;
		else
			CurrentMinefieldSequenceIndex++;

		NetStartMinefieldSequence(CurrentMinefieldSequenceIndex);
    }

	UFUNCTION(NetFunction)
	void NetStartMinefieldSequence(int MinefieldIndex)
	{
		bAllMinefieldsLaunched = false;
		CurrentMinefieldSequenceIndex = MinefieldIndex;
		bLeftMinefield = true;
		CurrentAttackMode = EVacuumBossAttackMode::Minefield;
        bPerformDoubleSlam = true;
        CurrentMinefieldAmount = 0;

		MinefieldHandle = System::SetTimer(this, n"SpawnMinefield", MinefieldDelay, true);
		SpawnMinefield();

		SetEffectsActive(true, false);
	}

	UFUNCTION()
	void SpawnMinefield()
	{
		AVacuumBossMinefield CurMinefield = MinefieldActors[MinefieldSequences[CurrentMinefieldSequenceIndex].Sequence[CurrentMinefieldAmount]];
		CurMinefield.ActivateMinefield();
		CurMinefield.OnAllMinesLaunched.AddUFunction(this, n"MinefieldFullyLaunched");

		UHazeAkComponent AkComp = bLeftMinefield ? HazeAkCompLeftHand : HazeAkCompRightHand;
		AkComp.HazePostEvent(LaunchMinefieldStartAudioEvent);

		CurrentMinefieldAmount++;

		if (CurrentMinefieldAmount >= MinefieldAmount)
		{
			PrepareBombLaunch(5.f);
			bPerformDoubleSlam = true;
			NextAttackMode = EVacuumBossAttackMode::Debris;
			System::ClearAndInvalidateTimerHandle(MinefieldHandle);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void MinefieldFullyLaunched(AVacuumBossMinefield Minefield, bool bLeft)
	{
		// UHazeAkComponent AkComp = bLeft ? HazeAkCompLeftHand : HazeAkCompRightHand;
		// AkComp.HazePostEvent(LaunchMinefieldStopAudioEvent);

		UHazeAkComponent AkComp = bLeftMinefield ? HazeAkCompLeftHand : HazeAkCompRightHand;
		AkComp.HazePostEvent(LaunchMinefieldStopAudioEvent);

		bLeftMinefield = !bLeftMinefield;
		if (!System::IsTimerActiveHandle(MinefieldHandle))
			bAllMinefieldsLaunched = true;
	}

    UFUNCTION(NetFunction)
    void NetTakeDamage(AVacuumBossBomb Bomb)
    {
		if (BombsTakenDamageFromThisPhase.Contains(Bomb))
			return;

		BombsTakenDamageFromThisPhase.Add(Bomb);

		// if (bEnrageTriggeredThisPhase)
			// return;

		if (CurrentBossHealth <= 0)
			return;

		SetAnimBoolParam(n"HitByBomb", true);
		OnVacuumBossTakenDamage.Broadcast();

		HazeAkCompHead.HazePostEvent(CanExploEvent);
		

        CurrentBossHealth = CurrentBossHealth - 1;
        HealthBar.SetHealthAsDamage(CurrentBossHealth);

        if (CurrentBossHealth <= MaximumBossHealth/3 && CurrentAttackMode != EVacuumBossAttackMode::DebrisSlam && NextAttackMode != EVacuumBossAttackMode::DebrisSlam)
        {
			// bEnrageTriggeredThisPhase = true;
            NextAttackMode = EVacuumBossAttackMode::DebrisSlam;
            bPerformDoubleSlam = false;
			// DeactivateBackPlatform();
			// QueueNextAttackSequence();
        }

        if (CurrentBossHealth == 0 && !bStunned)
        {
            StunBoss();
        }

        if (bLaunchBombsOnly)
        {
			bLaunchBombsOnly = false;
            NextAttackMode = EVacuumBossAttackMode::Slam;
        }
    }

    UFUNCTION()
    void StunBoss()
    {
        bStunned = true;
		RemoveHealthBar();
        OnVacuumBossStunned.Broadcast();
		LeftInteractionComp.Enable(n"Stunned");
		RightInteractionComp.Enable(n"Stunned");
		MusicStateChanged.Broadcast(EVacuumBossMusicState::Stunned);

		PlayStunnedIdleBark();
		StunnedIdleBarkTimerHandle = System::SetTimer(this, n"PlayStunnedIdleBark", 10.f, true);

		System::ClearAndInvalidateTimerHandle(CodyDebrisTimerHandle);
		System::ClearAndInvalidateTimerHandle(MayDebrisTimerHandle);

		SetEffectsActive(false, false);
    }

	UFUNCTION()
	void PlayStunnedIdleBark()
	{
		SetCapabilityActionState(n"FoghornEndingIdle", EHazeActionState::ActiveForOneFrame);
		SetCapabilityActionState(n"FoghornEndingRaiseTubesCough", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
    void LeftInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		LeftInteractionComp.Disable(n"Mounted");

		Player.SetCapabilityAttributeObject(n"VacuumBoss", this);
		Player.SetCapabilityActionState(n"LeftHose", EHazeActionState::Active);
		Player.SetCapabilityActionState(n"SuckEyes", EHazeActionState::Active);
		OnHoseMounted.Broadcast(true, Player);

		LeftSuckEffect.Activate(true);

		MusicStateChanged.Broadcast(EVacuumBossMusicState::HoseMounted);

		if (!bMountArmBarkPlayed)
		{
			bMountArmBarkPlayed = true;
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumBossFightDoubleInteractTubeCody");
		}
    }

	UFUNCTION()
    void RightInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		RightInteractionComp.Disable(n"Mounted");

		Player.SetCapabilityAttributeObject(n"VacuumBoss", this);
		Player.SetCapabilityActionState(n"LeftHose", EHazeActionState::Inactive);
		Player.SetCapabilityActionState(n"SuckEyes", EHazeActionState::Active);
		OnHoseMounted.Broadcast(false, Player);

		RightSuckEffect.Activate(true);

		MusicStateChanged.Broadcast(EVacuumBossMusicState::HoseMounted);

		if (!bMountArmBarkPlayed)
		{
			bMountArmBarkPlayed = true;
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumBossFightDoubleInteractTubeMay");
		}
    }

	void OneArmSlightlyRaised(bool bLeft)
	{
		if (bOneArmMashStarted)
			return;

		if (bLeft)
			bLeftArmIdle = false;
		else
			bRightArmIdle = false;

		if (bOneArmSlightlyRaised)
			return;

		bOneArmSlightlyRaised = true;
		System::ClearAndInvalidateTimerHandle(StunnedIdleBarkTimerHandle);
		PlaySlightlyRaisedBark();
		TubeSlightlyRaisedBarkTimerHandle = System::SetTimer(this, n"PlaySlightlyRaisedBark", 3.f, true);
	}

	void OneArmMashStarted()
	{
		if (bOneArmMashStarted)
			return;

		bOneArmMashStarted = true;
		PlayButtonMashBark();
		ButtonMashBarkTimerHandle = System::SetTimer(this, n"PlayButtonMashBark", 2.f, true);
		System::ClearAndInvalidateTimerHandle(TubeSlightlyRaisedBarkTimerHandle);

		VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumBossFightEndRaiseTubesHalfway");
	}

	void OneArmFullyReset(bool bLeft)
	{
		if (bOneArmMashStarted)
			return;

		if (bLeft)
			bLeftArmIdle = true;
		else
			bRightArmIdle = true;

		if (bLeftArmIdle && bRightArmIdle)
		{
			bOneArmSlightlyRaised = false;
			StunnedIdleBarkTimerHandle = System::SetTimer(this, n"PlayStunnedIdleBark", 10.f, true);
			System::ClearAndInvalidateTimerHandle(TubeSlightlyRaisedBarkTimerHandle);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlaySlightlyRaisedBark()
	{
		SetCapabilityActionState(n"FoghornEndingRaiseTubes", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayButtonMashBark()
	{
		SetCapabilityActionState(n"FoghornEndingRaiseTubesHalfway", EHazeActionState::ActiveForOneFrame);
		SetCapabilityActionState(n"FoghornEndingRaiseTubesCough", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void StopButonMashBarks()
	{
		System::ClearAndInvalidateTimerHandle(ButtonMashBarkTimerHandle);
	}

	UFUNCTION(NetFunction)
	void NetEyeFullySucked()
	{
		EyesSucked++;
		if (EyesSucked >= 2 && !bBothEyesSucked)
		{
			bBothEyesSucked = true;
			OnBothEyesSucked.Broadcast();
			MusicStateChanged.Broadcast(EVacuumBossMusicState::BothEyesSucked);
		}
		else
			MusicStateChanged.Broadcast(EVacuumBossMusicState::OneEyeSucked);
	}

	UFUNCTION()
	void ShowHealthBar()
	{
		FText BossName = NSLOCTEXT("VacuumTower", "Name", "Vacuum Tower");
		HealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarClass, EHazeWidgetLayer::Gameplay));
		HealthBar.InitBossHealthBar(BossName, MaximumBossHealth);
	}

	UFUNCTION()
	void RemoveHealthBar()
	{
		if (HealthBar == nullptr)
			return;

		Widget::RemoveFullscreenWidget(HealthBar);
	}

	void SetEffectsActive(bool bBlowActive, bool bSuckActive)
	{
		if (bBlowActive)
		{
			if (!LeftBlowEffect.IsActive() && !RightBlowEffect.IsActive())
			{
				LeftBlowEffect.Activate(true);
				RightBlowEffect.Activate(true);
			}
		}
		else
		{
			LeftBlowEffect.Deactivate();
			RightBlowEffect.Deactivate();
		}

		if (bSuckActive)
		{
			if (!LeftSuckEffect.IsActive() && !RightSuckEffect.IsActive())
			{
				LeftSuckEffect.Activate(true);
				RightSuckEffect.Activate();
			}
			
		}
		else
		{
			LeftSuckEffect.Deactivate();
			RightSuckEffect.Deactivate();
		}
	}
}

enum EVacuumBossAttackMode
{
    Debris,
    Slam,
	DoubleSlam,
    DebrisSlam,
    Minefield,
    Bombs
}

struct FMinefieldSequence
{
	UPROPERTY()
	TArray<int> Sequence;
}

enum EVacuumBossMusicState
{
	Debris,
	Slam,
	Minefield,
	Bombs,
	DebrisSlam,
	Stunned,
	HoseMounted,
	OneEyeSucked,
	BothEyesSucked
}