import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Peanuts.Aiming.AutoAimTarget;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;
import Peanuts.Health.BossHealthBarWidget;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArmsContainerComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateOctopusArtillerySpawner;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArmSecondSequence;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusThirdArmSlamLocation;

event void FOnPirateOctopusSlamAttackPrepared();
event void FOnPirateOctopusFightStarted();
event void FOnPirateOctopusDeath();
event void FOnPirateOctopusArmSpawned(AActor Arm);
event void FOnPirateOctopusArmDespawned(AActor Arm);
event void FOnThirdPhaseAllArmsKilled();
event void FOnPirateOctopusEmerge();
event void FOnPirateOctopusSubmerge();

delegate void FOnNextAttackSequenceReadySignature(int NextIndex);
event void FOnNextAttackSequenceReady(int NextIndex);
event void FOnSecondSequenceActivateCancel();

UCLASS(Abstract)
class APirateOctopusActor : AHazeActor
{
	default CannonBallDamageableComponent.DelayBeforeDestroyed = 1.5f; 
	default CannonBallDamageableComponent.bDestroyAfterExploding = false;

//Actor Components
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase OctoMesh;

	UPROPERTY(DefaultComponent, Attach = OctoMesh)
	UCapsuleComponent Collider;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;
	
	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;

	UPROPERTY(DefaultComponent)
	UCannonBallDamageableComponent CannonBallDamageableComponent;

	UPROPERTY(DefaultComponent)
	UPirateEnemyComponent EnemyComponent;

	UPROPERTY(DefaultComponent)
	UPirateOctopusArmsContainerComponent ArmsContainerComponent;

//General Variables
	UPROPERTY(Category = "References")
	APirateOceanStreamActor StreamSpline;

	UPROPERTY(Category = "References")
	AActor BossWavesActor;

	UPROPERTY(Category = "References")
	AActor BoatSecondPhaseTransformActor;

	// UPROPERTY(Category = "References")
	TArray<APirateOctopusArtillerySpawner> OctopusArtillerySpawners;
	
	UPROPERTY(NotEditable)
	EPirateOctopusFirstAttackMode CurrentFirstAttackMode;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusDeath OnPirateOctopusDeath;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusFightStarted OnPirateOctopusFightStarted;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusFightStarted OnPirateOctopusSecondPartStarting;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusFightStarted OnPirateOctopusSecondPartStarted;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusFightStarted OnPirateOctopusThirdPartStarting;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusFightStarted OnPirateOctopusThirdPartStarted;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusArmSpawned OnPirateOctopusArmSpawned;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusArmDespawned OnPirateOctopusArmDespawned;

	UPROPERTY(Category = "Events")
	FOnThirdPhaseAllArmsKilled OnThirdPhaseAllArmsKilled;

	// UPROPERTY(Category = "Events")
	// FOnSecondSequenceActivateCancel OnSecondSequenceActivateCancel;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusEmerge OnPirateOctopusEmerge;

	UPROPERTY(Category = "Events")
	FOnPirateOctopusSubmerge OnPirateOctopusSubmerge;
 
	UPROPERTY(Category = "Audio")
	UAkAudioEvent PirateOctopusCannonballHitEvent;

	UPROPERTY(Category = "Audio", EditDefaultsOnly)
	UGoldbergVOBank VOBank;

    UPROPERTY(NotEditable)
	bool bActivated;	

	bool bBarkPlayed = false;

	// FTimerHandle AttackTimerHandle;
	// FTimerHandle CoolDownTimerHandle;

    UPROPERTY(NotEditable)
	int CurrentAttackSequence = 0;
	
    UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TSubclassOf<APirateOctopusArm> SlamArmType;

    UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TSubclassOf<APirateOctopusArm> JabArmType;

	UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TSubclassOf<APirateOctopusArm> SecondSequenceSlamArmType;

	UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TSubclassOf<APirateOctopusArm> ThirdSequenceSlamArmType;

	UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TArray<APirateOctopusThirdArmSlamLocation> ArmSlamLocsThirdPhaseArray;

	UPROPERTY(EditDefaultsOnly, Category = "Arms")
	TArray<bool> bArmSlamThirdPhaseActive;

	UPROPERTY(Category = "Arms")
	TArray<APirateOctopusArmSecondSequence> PirateOctopusArmsSecondSequenceArray;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	TArray<UHazeCapabilitySheet> SequenceSheets;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams MHAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SpawnSlamAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SpawnJabAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams SubmergeAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams EmergeAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams ShotArmAnim;

	UPROPERTY(Category = "Animations")
	FHazePlayOverrideAnimationParams HurtAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBar;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	float WheelBoatZOffset = 330;

	float ArmsRootRotationSpeed = 3.0f;
	FRotator AddedRotation = FRotator(0.0f, 50.0f, 0.0f);

	//FVector BossCentreLocation;

	bool bLastAttackHitPlayer = false;

	UPROPERTY(NotEditable)
	bool bParticipatingInCutscene = false;

	//bool bTryingToActiveNextAttackSequence = false;
	// int PendingAttackSequence = 0;
	// FOnNextAttackSequenceReady NextSequenceIsReady;

	bool bSpawnedQuickJabArm = false;
	private int ArmsActive = 0;
	private TPerPlayer<int> NextLevelPrepared;

	UPROPERTY(Category = References)
	TArray<APirateOctopusArm> ThirdPhaseSlamArray;

	APirateOctopusArm ActiveFirstPhaseArm;

	int SlamPhaseThreeKillCount;
	int MaxSlamPhaseThreeKillCount = 3;

	int PhaseThreeHitCounter;

//Functions
	UFUNCTION(BlueprintOverride)
	void BeginPlay()	
	{
		AkComponent.SetStopWhenOwnerDestroyed(false);
		CurrentFirstAttackMode = EPirateOctopusFirstAttackMode::Slam;

		ArmsContainerComponent.Initialize(WheelBoat, StreamSpline.Spline);

		PlayMHAnim();

		//BossCentreLocation = ActorLocation;

		GetAllActorsOfClass(ArmSlamLocsThirdPhaseArray);
		GetAllActorsOfClass(OctopusArtillerySpawners);

		EnemyComponent.RotationRoot = Root;
	
		CannonBallDamageableComponent.OnExploded.AddUFunction(this, n"StopBossFightWithDelay");
		CannonBallDamageableComponent.OnCannonBallHit.AddUFunction(this, n"OnHitByCannonBall");

		//BossWavesActor.SetActorHiddenInGame(true);
		//BossStillWaterActor.SetActorHiddenInGame(true);

		BossWavesActor.SetActorHiddenInGame(true);
		BossWavesActor.SetActorEnableCollision(false);

		SetSpawnersActive(false, this);

		for (APirateOctopusArmSecondSequence Arm : PirateOctopusArmsSecondSequenceArray)
		{
			Arm.DisableActor(this);
		}

		for (APirateOctopusArm Arm : ThirdPhaseSlamArray)
		{
			Arm.FollowBoatComponent.bFollowBoat = false;
			Arm.Initialize(this, nullptr);
			Arm.FinishAttack();
		}

		NextLevelPrepared[0] = -1;
		NextLevelPrepared[1] = -1;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		DestroySecondSequenceArms();
		DestroyBossActors();

		for (APirateOctopusArmSecondSequence Arm : PirateOctopusArmsSecondSequenceArray)
		{
			Arm.DestroyActor();
		}
	}

	AWheelBoatActor GetWheelBoat() const property
	{
		return EnemyComponent.GetWheelBoat();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	void IncrementSlamPhaseThreeKillCount()
	{
		SlamPhaseThreeKillCount++;
	}

	void ResetSlamPhaseThreeKillCount()
	{
		SlamPhaseThreeKillCount = 0;
	}

	bool SlamPhaseThreeComplete()
	{
		if (SlamPhaseThreeKillCount < MaxSlamPhaseThreeKillCount - 1)
			return false;
		else
			return true;
	}

	UFUNCTION(BlueprintCallable)
	void StartBossFight()
	{
		if(StreamSpline == nullptr)
		{
			Print("There is no boss spline!", 3.0f);
			return;
		}

		AddCapability(n"PirateEnemyFaceWheelBoatCapability");	
		// AddCapability(n"PirateOctopusFirstSequenceCapability");	
		// AddCapability(n"PirateOctopusSecondSequenceCapability");
		// AddCapability(n"PirateOctopusThirdSequenceCapability");	

		OnPirateOctopusFightStarted.Broadcast();
		
		BossWavesActor.SetActorHiddenInGame(false);
		BossWavesActor.SetActorEnableCollision(true);

		EnemyComponent.bFacePlayer = true;
		ActivatePirateOctopus();
		ShowHealthBar();
		WheelBoat.StartBossFight(StreamSpline, this, WheelBoatZOffset);
		//this.SetCapabilityActionState(n"StartAttackSequence", EHazeActionState::Active);

	}

	UFUNCTION()
	void ActivatePirateOctopus()
	{
		bActivated = true;
		CurrentAttackSequence = 1;
		//PendingAttackSequence = CurrentAttackSequence;
		WheelBoat.bBossIsPreparingNextAttackSequence = false;
		RemoveAllCapabilitySheetsByInstigator(this);
		AddCapabilitySheet(SequenceSheets[CurrentAttackSequence - 1], EHazeCapabilitySheetPriority::High, this);
		WheelBoat.OctopusBossAttackSequence = CurrentAttackSequence;
		CannonBallDamageableComponent.EnableDamageTaking();
	}

	UFUNCTION()
	void StopBossFightWithDelay()
	{
		System::SetTimer(this, n"StopBossFight", CannonBallDamageableComponent.DelayBeforeDestroyed, false);
	}

	//TEMP FUNCTION - NEED ANIMATIONS
	UFUNCTION()
	void SubmergeBoss()
	{
		PlaySubmergeAnim();
		System::SetTimer(this, n"HideOctopusBody", 1.7f, false);
		Collider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		OnPirateOctopusSubmerge.Broadcast();
	}

	UFUNCTION()
	void EmergeBoss()
	{
		PlayEmergeAnim();
		System::SetTimer(this, n"ShowOctopusBody", 0.4f, false);
		OnPirateOctopusEmerge.Broadcast();
	}

	UFUNCTION()
	void StopBossFight()
	{
		OnPirateOctopusDeath.Broadcast();

		// BossThirdLayerOfWaterActor.SetActorHiddenInGame(true);
		// BossThirdLayerOfWaterActor.SetActorEnableCollision(false);

		BossWavesActor.SetActorEnableCollision(false);

		DestroyBossActors();
		CurrentAttackSequence = 0;
		//PendingAttackSequence = CurrentAttackSequence;
		WheelBoat.OctopusBossAttackSequence = CurrentAttackSequence;
		RemoveAllCapabilitySheetsByInstigator(this);

		if(WheelBoat != nullptr && WheelBoat.bBossFightActive)
			WheelBoat.ResetAfterBoss();

		if(HealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthBar);
			HealthBar = nullptr;
		}
	}

	UFUNCTION()
	void DeleteOctopusBossAndBossWater()
	{
		if(BossWavesActor != nullptr)
			BossWavesActor.DestroyActor();

		// if(BossStillWaterActor != nullptr)
		// 	BossStillWaterActor.DestroyActor();

		CannonBallDamageableComponent.DestroyOwningActor();
	}

	UFUNCTION()
	APirateOctopusArmSecondSequence ActivateSecondSequenceArm(FVector Location)
	{
		APirateOctopusArmSecondSequence ArmToReturn = nullptr;

		for (APirateOctopusArmSecondSequence Arm : PirateOctopusArmsSecondSequenceArray)
		{
			if (Arm.IsActorDisabled())
			{
				Arm.EnableActor(this);
				FVector LookDirection = Location - WheelBoat.ActorLocation;
				LookDirection.Normalize();
				FRotator LookRot = FRotator::MakeFromX(LookDirection);

				FVector OffsetLocation = Location + FVector(0.f, 0.f, /*-18*/0.f); //second sequence offset
				OffsetLocation -= LookDirection * 1000.f;

				Arm.InitiateArm(OffsetLocation, LookRot);
				return Arm;
			}
		}

		return nullptr;
	}

	UFUNCTION()
	void DeactivateAllSecondSequenceArm()
	{
		for (APirateOctopusArmSecondSequence Arm : PirateOctopusArmsSecondSequenceArray)
		{
			if (!Arm.IsActorDisabled())
			{
				Arm.DisableActor(this);
			}
		}
	}

	void DestroySecondSequenceArms()
	{
		for (APirateOctopusArmSecondSequence Arm : PirateOctopusArmsSecondSequenceArray)
		{
			Arm.DestroyActor();
		}
	}
	
	UFUNCTION()
	void ShowHealthBar()
	{
		FText BossName = NSLOCTEXT("PirateOctopus", "Name", "Giant Octopus");
		HealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarClass, EHazeWidgetLayer::Gameplay));
		HealthBar.InitBossHealthBar(BossName, CannonBallDamageableComponent.MaximumHealth);
	}
	
//ANIMATIONS
	UFUNCTION()
	void PlaySlammingAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMHAnim");
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, SpawnSlamAnim);
	}

	UFUNCTION()
	void PlayJabbingAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		// OnBlendingOut.BindUFunction(this, n"PlaySubmergeAnim");
		OnBlendingOut.BindUFunction(this, n"PlayMHAnim");
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, SpawnJabAnim);
	}

	UFUNCTION()
	void PlaySubmergeAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMHAnim");
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, SubmergeAnim);
	}

	UFUNCTION()
	void PlayEmergeAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMHAnim");
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, EmergeAnim);		
	}

	UFUNCTION()
	void PlayMHAnim()
	{ 
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, MHAnim);
	}

	UFUNCTION()
	void PlayHurtAnim()
	{
		FHazeAnimationDelegate OnBlendingOut;
		OctoMesh.PlayOverrideAnimation(OnBlendingOut, HurtAnim);
	}

	UFUNCTION()
	void PlayShotArmAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OctoMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, ShotArmAnim);
	}

	UFUNCTION()
	void SetHealthToHalf()
	{
		CannonBallDamageableComponent.CurrentHealth = CannonBallDamageableComponent.MaximumHealth/2;
		HealthBar.Health = CannonBallDamageableComponent.CurrentHealth;
	}
//
	UFUNCTION()
	void OnHitByCannonBall(FHitResult Hit)
	{
        HealthBar.TakeDamage(1.f);
		PlayHurtAnim();
		AkComponent.HazePostEvent(PirateOctopusCannonballHitEvent);
		PhaseThreeHitCounter++;

		if(CurrentAttackSequence == 1 && !bBarkPlayed && CannonBallDamageableComponent.CurrentHealth <= (CannonBallDamageableComponent.MaximumHealth * 0.8f))
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomGoldbergBossFightBossHint");
			bBarkPlayed = true;
		}
	}

	// UFUNCTION(NetFunction)
	// void NetSetNextAttackSequenceReady(AHazePlayerCharacter Player, int NextIndex)
	// {
	// 	NextLevelPrepared[Player.Player] = NextIndex;
	// 	if(NextLevelPrepared[Player.Player] != NextLevelPrepared[Player.GetOtherPlayer().Player])
	// 		return;

	// 	if(NextIndex == 2)
	// 		OnPirateOctopusSecondPartStarting.Broadcast();
	// 	else if(NextIndex == 3)
	// 		OnPirateOctopusThirdPartStarting.Broadcast();
	// }

	UFUNCTION(NotBlueprintCallable)
	void InitalizeSecondAttackSequence()
	{
		CurrentAttackSequence = 2;
		OnPirateOctopusSecondPartStarting.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void StartSecondAttackSequence()
	{
		ArmsActive = 0;

		//Log("[PirateOctopus] StartSecondAttackSequence called from BP");
		CurrentAttackSequence = 2;
		//PendingAttackSequence = CurrentAttackSequence;
		WheelBoat.OctopusBossAttackSequence = CurrentAttackSequence;
		WheelBoat.bBossIsPreparingNextAttackSequence = false;
		RemoveAllCapabilitySheetsByInstigator(this);
		AddCapabilitySheet(SequenceSheets[CurrentAttackSequence - 1], EHazeCapabilitySheetPriority::High, this);
		HideOctopusBody();

		WheelBoat.AngularAccelerationSettingsOverride = 80.0f;

		OnPirateOctopusSecondPartStarted.Broadcast();
		WheelBoat.StartBossFightSecondPart(BoatSecondPhaseTransformActor);
	}

	UFUNCTION(NotBlueprintCallable)
	void InitalizeThirdAttackSequence()
	{
		CurrentAttackSequence = 3;
		OnPirateOctopusThirdPartStarting.Broadcast();
	}

	UFUNCTION(BlueprintCallable)	
	void StartThirdAttackSequence()
	{
		ArmsActive = 0;
		
		CurrentAttackSequence = 3;
		//PendingAttackSequence = CurrentAttackSequence;
		WheelBoat.bBossIsPreparingNextAttackSequence = false;
		bSpawnedQuickJabArm = false;
		WheelBoat.OctopusBossAttackSequence = CurrentAttackSequence;
		RemoveAllCapabilitySheetsByInstigator(this);
		AddCapabilitySheet(SequenceSheets[CurrentAttackSequence - 1], EHazeCapabilitySheetPriority::High, this);
		// ShowOctopusBody();

		//BossStillWaterActor.SetActorEnableCollision(false);
		// BossSecondLayerOfWaterActor.SetActorHiddenInGame(false);
		
		// BossThirdLayerOfWaterActor.SetActorHiddenInGame(false);
		// BossThirdLayerOfWaterActor.SetActorEnableCollision(true);

		WheelBoat.AngularAccelerationSettingsOverride = -1;
		FVector SpawnLocation = StreamSpline.Spline.FindLocationClosestToWorldLocation(WheelBoat.ActorLocation, ESplineCoordinateSpace::World);

		//offset boat for third ENiagaraSystemSpawnSectionEndBehavior
		SpawnLocation += FVector(0.f, 0.f, 325.0f);

		OnPirateOctopusThirdPartStarted.Broadcast();
		WheelBoat.StartBossFightThirdPart(SpawnLocation);

		for(APirateOctopusArtillerySpawner Spawner : OctopusArtillerySpawners)
		{
			if(Spawner == nullptr)
				continue;
				
			float DistanceFromBoat = (WheelBoat.ActorLocation - Spawner.ActorLocation).Size();

			if (DistanceFromBoat >= 2500.f)
			{
				Spawner.Initialize(WheelBoat, StreamSpline.Spline);
				Spawner.EnableActor(this);
			}	
		}
	}

	void SetSpawnersActive(bool bStatus, UObject InInstigator)
	{
		for(APirateOctopusArtillerySpawner Spawner : OctopusArtillerySpawners)
		{
			if(Spawner == nullptr)
				continue;

			if(bStatus)
				Spawner.EnableActor(InInstigator);
			else
				Spawner.DisableActor(InInstigator);
		}
	}
	
	UFUNCTION()
	void ShowOctopusBody()
	{
		OctoMesh.SetHiddenInGame(false, false);
		Collider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	void HideOctopusBody()
	{
		OctoMesh.SetHiddenInGame(true, false);
		Collider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void SetOctopusArmsVisibility(bool bIsHidden)
	{
		BP_SetOctopusArmsVisibility(bIsHidden);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SetOctopusArmsVisibility(bool bIsHidden) {}


	void DestroyBossActors()
	{
		ArmsContainerComponent.Clear();

		for(APirateOctopusArtillerySpawner Spawner : OctopusArtillerySpawners)
		{
			if(Spawner == nullptr)
				continue;
			Spawner.DestroyActor();
		}
	}
	
//ARM EVENTS
	void ArmAttackStarted(APirateOctopusArm Arm)
	{
		ArmsActive++;
	}

	void ArmAttackFinished(APirateOctopusArm Arm)
	{
		OnPirateOctopusArmDespawned.Broadcast(Arm);
		ArmsContainerComponent.ReleaseArm(Arm);
		ArmsActive--;

		if (ArmsActive < 0)
			ArmsActive = 0;

		// if(!TryingToActiveNextAttackSequence())
		// {
		// 	if(HasControl() && CurrentAttackSequence == 1)
		// 		this.SetCapabilityActionState(n"StartAttackSequence", EHazeActionState::Active);
		// }
		// else
		// {	
		// 	UpdateNextAttackSequenceReadyStatus();
		// }
	}

	UFUNCTION()
	void ArmAttackHitPlayer(APirateOctopusArm Arm)
	{
		bLastAttackHitPlayer = true;
		// if(HasControl())
		// 	this.SetCapabilityActionState(n"ArmHitPlayer", EHazeActionState::Inactive);		
	}

	UFUNCTION()
	void ArmHitByCannonBall(APirateOctopusArm Arm)
	{
        // HealthBar.ModifyHealth(-0.5f);
		// CannonBallDamageableComponent.TakeDamage(0.5f);
		PlayShotArmAnim();
		AkComponent.HazePostEvent(PirateOctopusCannonballHitEvent);
	}

	int GetActiveArmsCount()const
	{
		return ArmsActive;
	}

	UFUNCTION()
	APirateOctopusArm GetPhaseThreeArm()
	{
		APirateOctopusArm ChosenArm;

		for (APirateOctopusArm Arm : ThirdPhaseSlamArray)
		{
			if (Arm.IsActorDisabled())
			{
				Arm.FollowBoatComponent.bFollowBoat = false;
				//Arm.ActivateArm();
				ChosenArm = Arm;
				return ChosenArm;
			}
		}

		return ChosenArm;
	}
}

enum EPirateOctopusFirstAttackMode
{
    Slam,
	Jab,
	StreamArm,
}