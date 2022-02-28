import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkLastBossRecordCrusherClockFace;

event void FOnCrusherBombedPlayer(AClockworkLastBossRecordBomb Crusher, AHazePlayerCharacter Player);

enum EClockworkRecordBombState
{
	None,
	Following,
	WaitingForSmash,
	Smashing,
	WaitingForReverse,
	ReversingFx,
	ReversingBomb,
};


class AClockworkLastBossRecordBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SmasherRoot;
	default SmasherRoot.RelativeLocation = FVector(0.f, 0.f, 5000.f);

	UPROPERTY(DefaultComponent, Attach = SmasherRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DamageCollision;
	default DamageCollision.bHiddenInGame = true;
	default DamageCollision.CollisionProfileName = n"NoCollision";
	default DamageCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleCollision;
	default CapsuleCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = SmasherRoot)
	UTextRenderComponent DebugText;
	default DebugText.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionFX;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AActor CrusherTarget;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExploEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GlassDestructionEvent;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	/* Event is only broadcast on that player's control side. */
	UPROPERTY()
	FOnCrusherBombedPlayer OnBombedPlayer_ControlSide;

	private bool bAllowDamage = false;
	private TArray<AHazePlayerCharacter> DamagedPlayers;

	private EClockworkRecordBombState State = EClockworkRecordBombState::None;
	private float FollowDuration = 0.f;
	private float SmashDelayDuration = 0.f;
	private float SmashDuration = 0.f;
	private float ReverseDelayDuration = 0.f;
	private float ReverseDuration = 0.f;

	private float StateTimer = 0.f;

	private bool bTickFxTimer = false;
	private bool bFxTimerForward = false;
	private float FxTimer = 0.f;
	private float FxTimerBeforeStateSwitch = 0.f;
	private float PrevFxTimer = MIN_flt;

	// Set from ClockworkRecordCrusherManager to  determine when to smash this crusher
	float SmasherPhaseDuration = 0.f;
	// ClockworkRecordCrusherManager fills out this array
	TArray<AClockworkLastBossRecordCrusherClockFace> ClockFaces;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void FollowAndSmash(AActor ActorToFollow, float FollowTime, float SmashDelay, float SmashTime, float ReverseDelay, float BombReverseTime)
	{
		State = EClockworkRecordBombState::Following;
		CrusherTarget = ActorToFollow;
		FollowDuration = FollowTime;
		SmashDelayDuration = SmashDelay;
		SmashDuration = SmashTime;
		ReverseDelayDuration = ReverseDelay;
		ReverseDuration = BombReverseTime;
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
			case EClockworkRecordBombState::Following:
			{
				BP_UpdateRunningProgress(StateTimer / FollowDuration);

				FVector PrevLocation = ActorLocation;
				FVector NewLocation = CrusherTarget.ActorLocation;
				NewLocation.Z = PrevLocation.Z;

				ActorLocation = NewLocation;

				if (StateTimer >= FollowDuration)
				{
					State = EClockworkRecordBombState::WaitingForSmash;
					StateTimer = 0.f;

					BP_AboutToSmash();
				}
			}
			break;
			case EClockworkRecordBombState::WaitingForSmash:
				if (StateTimer >= SmashDelayDuration)
				{
					State = EClockworkRecordBombState::Smashing;
					StateTimer = 0.f;

					BP_StartSmashing();

					bAllowDamage = true;
				}
			break;
			case EClockworkRecordBombState::Smashing:
				{
					float SmashPct = FMath::Clamp(StateTimer / SmashDuration, 0.f, 1.f);
					BP_UpdateSmashingProgress(SmashPct);

					SmasherRoot.RelativeLocation = FVector(0.f, 0.f, (1.f - SmashPct) * 5000.f);

				}

				if (StateTimer >= SmashDuration)
				{
					BP_FinishedSmashing();
					OverlapCheck();
					DamageCollision.SetHiddenInGame(true);
					bTickFxTimer = true;
					bFxTimerForward = true;
					State = EClockworkRecordBombState::WaitingForReverse;
					StateTimer = 0.f;
				}
			break;
			case EClockworkRecordBombState::WaitingForReverse:
				{
					FxTimer = StateTimer;
				}
				if (StateTimer >= ReverseDelayDuration - (SmashDuration + SmashDelayDuration))
				{
					State = EClockworkRecordBombState::ReversingFx;
					StateTimer = 0.f;
					FxTimerBeforeStateSwitch = FxTimer;
					
					bAllowDamage = false;

					BP_StartRetracting();
					bFxTimerForward = false;
				}
			break;
			case EClockworkRecordBombState::ReversingFx:
				{
					FxTimer = 1.f - FMath::Clamp(StateTimer / (ReverseDuration / 2), 0.f, 1.f);
					FxTimer = FMath::Lerp(FxTimerBeforeStateSwitch, 0.f, FMath::Clamp(StateTimer / (ReverseDuration / 2), 0.f, 1.f));
				}

				if (StateTimer >= (ReverseDuration / 2))
				{
					DamageCollision.SetHiddenInGame(false);
					State = EClockworkRecordBombState::ReversingBomb;
					StateTimer = 0.f;
					CrusherTarget = nullptr;
				}
				
			break;
			case EClockworkRecordBombState::ReversingBomb:
				{
					float SmashPct = 1.f - FMath::Clamp(StateTimer / (ReverseDuration / 2), 0.f, 1.f);
					BP_UpdateSmashingProgress(SmashPct);

					SmasherRoot.RelativeLocation = FVector(0.f, 0.f, (1.f - SmashPct) * 5000.f);
				}

				if (StateTimer >= (ReverseDuration / 2))
				{
					State = EClockworkRecordBombState::None;
					StateTimer = 0.f;
					CrusherTarget = nullptr;

					BP_FullyRetracted();
					BP_CrusherDone();
				}
			break;
		}

	#if EDITOR
		FString DebugString = "FX: " + FxTimer;
		DebugText.SetText(FText::FromString(DebugString));
	#endif

		if (PrevFxTimer != FxTimer)
		{
			ExplosionFX.SetNiagaraVariableFloat("User.Time", FMath::Max(FxTimer, 0.001f));	
			PrevFxTimer = FxTimer;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartCrusher() { }

	UFUNCTION(BlueprintEvent)
	void BP_UpdateRunningProgress(float Progress) { }

	UFUNCTION(BlueprintEvent)
	void BP_AboutToSmash() { }

	UFUNCTION(BlueprintEvent)
	void BP_StartSmashing() { }

	UFUNCTION(BlueprintEvent)
	void BP_UpdateSmashingProgress(float Progress) { }

	UFUNCTION(BlueprintEvent)
	void BP_FinishedSmashing() { }

	UFUNCTION(BlueprintEvent)
	void BP_StartRetracting() { }

	UFUNCTION(BlueprintEvent)
	void BP_FullyRetracted() { }

	UFUNCTION(BlueprintEvent)
	void BP_CrusherDone() { }

	UFUNCTION()
	void OverlapCheck()
	{
		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -10.f);

		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(ExploEvent, CrusherTarget.GetActorTransform(), Rtpcs);
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player != nullptr && Player.HasControl())
			{
				if (Trace::ComponentOverlapComponent(Player.CapsuleComponent, CapsuleCollision))
				{
					if (bAllowDamage && !DamagedPlayers.Contains(Player) /*&& !CanPlayerBeDamaged(Player)*/)
					{
						KillPlayer(Player);

						//Player.DamagePlayerHealth(0.2f, DamageEffect);
						DamagedPlayers.Add(Player);

						OnBombedPlayer_ControlSide.Broadcast(this, Player);
					}
				}
			}
		}

		for (AClockworkLastBossRecordCrusherClockFace ClockFace : ClockFaces)
		{
			if (ClockFace != nullptr && HasControl())
			{
				if (Trace::ComponentOverlapComponent(ClockFace.DestroyClockCollision, CapsuleCollision))
				{
					ClockFace.NetDestroyClockFace(true);

					UHazeAkComponent::HazePostEventFireForget(GlassDestructionEvent, CrusherTarget.GetActorTransform());
				}
			}
		}
	}
}