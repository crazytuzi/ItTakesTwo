import Cake.LevelSpecific.PlayRoom.Castle.Audio.CastleAudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

UCLASS(Abstract)
class UCastleEnemyAudioBaseCapability : UHazeCapability
{
	UPROPERTY(Category = "Castle Enemy Basic Audio")
	UAkAudioEvent OnStartMovingEvent;

	UPROPERTY(Category = "Castle Enemy Basic Audio")
	UAkAudioEvent OnStopMovingEvent;

	UPROPERTY(Category = "Castle Enemy Basic Audio")
	UAkAudioEvent OnKilledEvent;

	UPROPERTY(Category = "Castle Enemy Basic Audio")
	UAkAudioEvent OnDamagedEvent;

	UPROPERTY(Category = "Castle Enemy Basic Audio")
	UAkAudioEvent OnKnockbackEvent;

	UPROPERTY()
	ECastleEnemyVOTypes EnemyVOType;

	FCastleEnemyTypeVOEventData VoEventData;
	FHazeAudioEventInstance AggroEventInstance;
	FHazeAudioEventInstance IdleEventInstance;

	ACastleEnemy CastleEnemy;
	UHazeAkComponent EnemyHazeAkComp;

	FVector LastLocation;
	bool bIsMoving = false;
	bool bIsInCombat = false;
	bool bBlockMovementAudio = false;
	bool bWasKilled = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CastleEnemy = Cast<ACastleEnemy>(Owner);
		CastleEnemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		CastleEnemy.OnKilled.AddUFunction(this, n"OnKilled");
		CastleEnemy.OnKnockedBack.AddUFunction(this, n"OnKnockback");

		EnemyHazeAkComp = UHazeAkComponent::GetOrCreateHazeAkComponent(CastleEnemy, NAME_None, true, true);
		EnemyHazeAkComp.SetTrackVelocity(true, 500.f);
		EnemyHazeAkComp.SetTrackDistanceToPlayer(true, MaxRadius = 3000.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;	
	}
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(EnemyVOType != ECastleEnemyVOTypes::None)
		{
			UCastleEnemyVOEffortsManager VOManager = GetCastleEnemyVOManager();
			if(VOManager != nullptr)
				VoEventData = VOManager.GetQueuedVOEvents(EnemyVOType);
		}

		LastLocation = CastleEnemy.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Pos = GetObjectScreenPos(CastleEnemy);
		HazeAudio::SetPlayerPanning(EnemyHazeAkComp, nullptr, Pos);

		FVector Location = CastleEnemy.GetActorLocation();
		const float Speed = (Location - LastLocation).Size() / DeltaTime;

		if(Speed > 0 && !bIsMoving && !bBlockMovementAudio)
		{
			EnemyHazeAkComp.HazePostEvent(OnStartMovingEvent);
			bIsMoving = true;

			if(EnemyHazeAkComp.EventInstanceIsPlaying(IdleEventInstance))
				EnemyHazeAkComp.HazeStopEvent(IdleEventInstance.PlayingID, FadeOutTimeMs = 300.f);
		}

		if(Speed == 0)
		{	
			if(!bIsInCombat && !bWasKilled)
			{
				if(VoEventData.OnIdleEvent != nullptr && !EnemyHazeAkComp.EventInstanceIsPlaying(IdleEventInstance))
					IdleEventInstance = EnemyHazeAkComp.HazePostEvent(VoEventData.OnIdleEvent);				
			}

			if(bIsMoving)
			{
				EnemyHazeAkComp.HazePostEvent(OnStopMovingEvent);
				bIsMoving = false;
			}
		}
		
		if(ConsumeAction(n"AudioStartedAggro") == EActionStateStatus::Active)
		{
			AggroEventInstance = EnemyHazeAkComp.HazePostEvent(VoEventData.OnAggroEvent);
			bIsInCombat = true;
		}

		if(ConsumeAction(n"AudioStoppedAggro") == EActionStateStatus::Active)
		{
			EnemyHazeAkComp.HazeStopEvent(AggroEventInstance.PlayingID, FadeOutTimeMs = 500.f);
			bIsInCombat = false;
		}

		if(ConsumeAction(n"AudioStartAttack") == EActionStateStatus::Active)
			if(VoEventData.OnAttackPlayerEvent != nullptr)
				EnemyHazeAkComp.HazePostEvent(VoEventData.OnAttackPlayerEvent);

		LastLocation = Location;
	}

	UFUNCTION()
	void OnTakeDamage(ACastleEnemy CastleEnemy, FCastleEnemyDamageEvent DamagedEvent)
	{
		EnemyHazeAkComp.HazePostEvent(OnDamagedEvent);
		if(VoEventData.OnTakeDamageEvent != nullptr)
			EnemyHazeAkComp.HazePostEvent(VoEventData.OnTakeDamageEvent);
	}

	UFUNCTION()
	void OnKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		EnemyHazeAkComp.HazePostEvent(OnKilledEvent);
		if(VoEventData.OnKilledEvent != nullptr)
			EnemyHazeAkComp.HazePostEvent(VoEventData.OnKilledEvent);

		if(EnemyHazeAkComp.EventInstanceIsPlaying(IdleEventInstance))
			EnemyHazeAkComp.HazeStopEvent(IdleEventInstance.PlayingID);

		bWasKilled = true;
	}

	UFUNCTION()
	void OnKnockback(ACastleEnemy Enemy, FCastleEnemyKnockbackEvent Event)
	{
		EnemyHazeAkComp.HazePostEvent(OnKnockbackEvent);
		if(VoEventData.OnTakeDamageEvent != nullptr)
			EnemyHazeAkComp.HazePostEvent(VoEventData.OnTakeDamageEvent);
	}
}