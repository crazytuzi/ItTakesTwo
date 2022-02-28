import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnCrusherDamagedPlayer(AClockworkRecordCrusher Crusher, AHazePlayerCharacter Player);

enum EClockworkRecordCrusherState
{
	None,
	Following,
	WaitingForSmash,
	Smashing,
	WaitingForRetract,
	Retracting,
};

class AClockworkRecordCrusher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SmasherRoot;
	default SmasherRoot.RelativeLocation = FVector(0.f, 0.f, 5000.f);

	UPROPERTY(DefaultComponent, Attach = SmasherRoot)
	UStaticMeshComponent DamageCollision;
	default DamageCollision.bHiddenInGame = true;
	default DamageCollision.CollisionProfileName = n"OverlapAll";
	default DamageCollision.bGenerateOverlapEvents = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AActor CrusherTarget;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	/* Event is only broadcast on that player's control side. */
	UPROPERTY()
	FOnCrusherDamagedPlayer OnDamagedPlayer_ControlSide;

	private bool bAllowDamage = false;
	private TArray<AHazePlayerCharacter> DamagedPlayers;

	private EClockworkRecordCrusherState State = EClockworkRecordCrusherState::None;
	private float FollowDuration = 0.f;
	private float SmashDelayDuration = 0.f;
	private float SmashDuration = 0.f;
	private float RetractDelayDuration = 0.f;
	private float RetractDuration = 0.f;

	private float StateTimer = 0.f;

	// Set from ClockworkRecordCrusherManager to  determine when to smash this crusher
	float SmasherPhaseDuration = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageCollision.OnComponentBeginOverlap.AddUFunction(this, n"DamageOverlap");
	}

	void FollowAndSmash(AActor ActorToFollow, float FollowTime, float SmashDelay, float SmashTime, float RetractDelay, float RetractTime)
	{
		State = EClockworkRecordCrusherState::Following;
		CrusherTarget = ActorToFollow;
		FollowDuration = FollowTime;
		SmashDelayDuration = SmashDelay;
		SmashDuration = SmashTime;
		RetractDelayDuration = RetractDelay;
		RetractDuration = RetractTime;
		StateTimer = 0.f;	

		bAllowDamage = false;
		DamagedPlayers.Empty();

		BP_StartCrusher();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		StateTimer += DeltaTime;

		switch (State)
		{
			case EClockworkRecordCrusherState::Following:
				BP_UpdateRunningProgress(StateTimer / FollowDuration);
				ActorLocation = CrusherTarget.ActorLocation;

				if (StateTimer >= FollowDuration)
				{
					
					State = EClockworkRecordCrusherState::WaitingForSmash;
					StateTimer = 0.f;

					BP_AboutToSmash();
				}
			break;
			case EClockworkRecordCrusherState::WaitingForSmash:
				if (StateTimer >= SmashDelayDuration)
				{
					
					State = EClockworkRecordCrusherState::Smashing;
					StateTimer = 0.f;

					BP_StartSmashing();

					bAllowDamage = true;
				}
			break;
			case EClockworkRecordCrusherState::Smashing:
				{
					
					float SmashPct = FMath::Clamp(StateTimer / SmashDuration, 0.f, 1.f);
					BP_UpdateSmashingProgress(SmashPct);

					SmasherRoot.RelativeLocation = FVector(0.f, 0.f, (1.f - SmashPct) * 5000.f);
				}

				if (StateTimer >= SmashDuration)
				{
					State = EClockworkRecordCrusherState::WaitingForRetract;
					StateTimer = 0.f;
				}
			break;
			case EClockworkRecordCrusherState::WaitingForRetract:
				if (StateTimer >= SmashDuration)
				{
					
					State = EClockworkRecordCrusherState::Retracting;
					StateTimer = 0.f;

					bAllowDamage = false;

					BP_StartRetracting();
				}
			break;
			case EClockworkRecordCrusherState::Retracting:
				{
					
					float SmashPct = 1.f - FMath::Clamp(StateTimer / RetractDuration, 0.f, 1.f);
					BP_UpdateSmashingProgress(SmashPct);

					SmasherRoot.RelativeLocation = FVector(0.f, 0.f, (1.f - SmashPct) * 5000.f);
				}

				if (StateTimer >= RetractDuration)
				{
					State = EClockworkRecordCrusherState::None;
					StateTimer = 0.f;
					CrusherTarget = nullptr;

					BP_FullyRetracted();
					BP_CrusherDone();
				}
			break;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartCrusher() { }

	UFUNCTION(BlueprintEvent)
	void BP_UpdateRunningProgress(float Progress) { }

	UFUNCTION(BlueprintEvent)
	void BP_AboutToSmash() 
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_StartSmashing() { }

	UFUNCTION(BlueprintEvent)
	void BP_UpdateSmashingProgress(float Progress) { }

	UFUNCTION(BlueprintEvent)
	void BP_StartRetracting() { }

	UFUNCTION(BlueprintEvent)
	void BP_FullyRetracted() { }

	UFUNCTION(BlueprintEvent)
	void BP_CrusherDone() { }

	UFUNCTION()
    void DamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
		UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
		bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
		{
			if (bAllowDamage && !DamagedPlayers.Contains(Player) /*&& !CanPlayerBeDamaged(Player)*/)
			{
				Player.KillPlayer();

				//Player.DamagePlayerHealth(0.2f, DamageEffect);
				DamagedPlayers.Add(Player);

				OnDamagedPlayer_ControlSide.Broadcast(this, Player);
			}
		}
	}
};