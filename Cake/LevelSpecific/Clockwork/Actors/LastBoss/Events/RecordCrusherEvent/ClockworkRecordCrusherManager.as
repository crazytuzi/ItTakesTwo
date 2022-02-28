import Vino.Checkpoints.Checkpoint;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkRecordCrusherPlayerGhost;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkRecordCrusher;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkLastBossRecordCrusherClockFace;
import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkLastBossRecordBomb;

event void FOnRecordCrusherPhaseStart();
event void FOnRecordCrusherGameplayFinished();
event void FOnRecordCrusherLoopBark();
event void FOnBothPlayersDied();

enum EClockworkRecordCrusherStage
{
	None,
	Running,
	WaitForReverse,
	Reversing,
};

class AClockworkRecordCrusherManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TSubclassOf<AClockworkLastBossRecordBomb> BombClass;

	UPROPERTY()
	TSubclassOf<AClockworkRecordCrusherPlayerGhost> CodyGhostClass;

	UPROPERTY()
	TSubclassOf<AClockworkRecordCrusherPlayerGhost> MayGhostClass;

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet;

	// Time that the players are running and followed by smashers
	UPROPERTY()
	float RunningTime = 2.f;

	// Amount of running time each phase runs longer than the previous
	UPROPERTY()
	float RunningTimeExtendPerPhase = 0.1f;

	// Time that the smasher hangs still before smashing
	UPROPERTY()
	float SmashWaitTime = .5f;

	// Time that the smasher spends smashing downward
	UPROPERTY()
	float SmashTime = 1.f;

	// Time after smashing before reversing time
	UPROPERTY()
	float ReverseWaitTime = 3.f;

	// Duration over which player time is reversed
	UPROPERTY()
	float ReverseTime = 1.f;

	// How many times the process repeats before the gameplay section is finished
	UPROPERTY()
	int PhaseCount = 70;

	// Maximum amount of times the player gets cloned
	UPROPERTY()
	int MaximumCloneCount = 5;

	bool bBothPlayersDied = false;
	bool bWaitingForReverse = false;

	//Clockfaces that we destroy with Crushers
	UPROPERTY()
	TArray<AClockworkLastBossRecordCrusherClockFace> ClockFaceArray;

	UPROPERTY()
	FOnRecordCrusherPhaseStart OnRecordCrusherPlayPhaseStartVO;

	UPROPERTY()
	FOnRecordCrusherGameplayFinished OnGameplayFinished;

	UPROPERTY()
	FOnRecordCrusherLoopBark OnRecordCrusherLoopBark;

	UPROPERTY()
	FOnBothPlayersDied OnBothPlayersDied;

	UPROPERTY(DefaultComponent, Attach = SmasherRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartForwardClockTickEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartBackwardClockTickEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartIdleClockTickEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopClockTickEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AboutToSmashEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BombIncomingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReverseEvent;

	UPostProcessingComponent PostProcComp;
	
	// Number of ClockFaces destroyed. Crusher event stops when all ClockFaces are destroyed
	int DestroyedClockFaces = 0;

	private TArray<AClockworkRecordCrusherPlayerGhost> PreviousGhosts;
	private TArray<AClockworkRecordCrusherPlayerGhost> CurrentGhosts;
	private TArray<AClockworkLastBossRecordBomb> PreviousBombs;
	private TArray<AClockworkLastBossRecordBomb> CurrentBombs;
	private EClockworkRecordCrusherStage State = EClockworkRecordCrusherStage::None;
	private int CurrentPhase = 0;
	private float TimerInState = 0.f;
	private float PhaseRunningDuration = 0.f;
	private TArray<AHazePlayerCharacter> PlayersDamagedDuringPhase;
	private TArray<AHazePlayerCharacter> LockedPlayers;
	private bool bHasPlayedBark = false;

	void StartCrusherGameplay()
	{
		State = EClockworkRecordCrusherStage::Running;

		for (auto Player : Game::Players)
			Player.AddCapabilitySheet(PlayerSheet, Priority = EHazeCapabilitySheetPriority::Interaction, Instigator = this);

		for(auto Clock : ClockFaceArray)
			Clock.ClockFaceDestroyed.AddUFunction(this, n"ClockFaceDestroyed");
	}

	void StopCrusherGameplay()
	{
		CurrentPhase = 0;
		TimerInState = 0.f;
		PhaseRunningDuration = 0.f;
		bBothPlayersDied = false;
		State = EClockworkRecordCrusherStage::None;
		SetVhsFX(false);

		HazeAkComp.HazePostEvent(StopClockTickEvent);

		for (auto Bomb : PreviousBombs)
			Bomb.DestroyActor();
		PreviousBombs.Empty();

		for (auto Bomb : CurrentBombs)
			Bomb.DestroyActor();
		CurrentBombs.Empty();

		for (auto Ghost : PreviousGhosts)
			Ghost.DestroyActor();
		PreviousGhosts.Empty();

		for (auto Ghost : CurrentGhosts)
			Ghost.DestroyActor();
		CurrentGhosts.Empty();

		for (auto Player : Game::Players)
			Player.RemoveCapabilitySheet(PlayerSheet, Instigator = this);

		for (auto Player : PlayersDamagedDuringPhase)
		{
			Player.UnblockCapabilities(n"GameplayAction", this);
			Player.UnblockCapabilities(n"Visibility", this);
			Player.UnblockCapabilities(n"Movement", this);
			Player.UnblockCapabilities(n"Respawn", this);
			Player.RemovePlayerInvulnerability(this);
		}

		devEnsure(LockedPlayers.Num() == 0);
		PlayersDamagedDuringPhase.Empty();
		LockedPlayers.Empty();
	}

	UFUNCTION()
	void StartNewCrusherPhase()
	{
		if (State == EClockworkRecordCrusherStage::None)
			StartCrusherGameplay();

		State = EClockworkRecordCrusherStage::Running;
		TimerInState = 0.f;
		SetVhsFX(false);

		if (CurrentPhase <= 2)
			OnRecordCrusherPlayPhaseStartVO.Broadcast();

		HazeAkComp.HazePostEvent(StartForwardClockTickEvent);

		PhaseRunningDuration = RunningTime + (RunningTimeExtendPerPhase * CurrentPhase);
		CurrentPhase += 1;

		for (auto Player : Game::Players)
		{
			// Spawn crusher that should follow the player
			AClockworkLastBossRecordBomb Bomb;
			AClockworkRecordCrusherPlayerGhost Ghost;
			if (PreviousBombs.Num() <= MaximumCloneCount * 2)
			{
				Bomb = Cast<AClockworkLastBossRecordBomb>(SpawnActor(
					BombClass.Get(),
					Player.ActorLocation,
					Player.ActorRotation));
				Bomb.ClockFaces = ClockFaceArray;

				Ghost = Cast<AClockworkRecordCrusherPlayerGhost>(SpawnActor(
					Player.IsCody() ? CodyGhostClass.Get() : MayGhostClass.Get(),
					Player.ActorLocation,
					Player.ActorRotation));
			}
			else
			{
				int PlayerIndex = int(Player.Player);
				Bomb = PreviousBombs[0];
				PreviousBombs.RemoveAt(0);

				Ghost = PreviousGhosts[0];
				PreviousGhosts.RemoveAt(0);
			}

			Bomb.OnBombedPlayer_ControlSide.AddUFunction(this, n"BombDamagedPlayer_ControlSide");
			Bomb.SmasherPhaseDuration = PhaseRunningDuration;
			Bomb.FollowAndSmash(
				Player,
				FollowTime = PhaseRunningDuration,
				SmashDelay = SmashWaitTime,
				SmashTime = SmashTime,
				ReverseDelay = ReverseWaitTime,
				BombReverseTime = ReverseTime
			);

			CurrentBombs.Add(Bomb);

			// Spawn recorded players that are currently just in record mode
			Ghost.StartRecording(Player);

			CurrentGhosts.Add(Ghost);
		}

		for (AClockworkLastBossRecordCrusherClockFace Clock : ClockFaceArray)
			Clock.RotateClockHands(true);
		

		// Follow correct targets with previous crushers
		for (int i = 0, Count = PreviousBombs.Num(); i < Count; ++i)
		{
			PreviousBombs[i].FollowAndSmash(
				PreviousGhosts[i],
				FollowTime = PreviousBombs[i].SmasherPhaseDuration,
				SmashDelay = SmashWaitTime,
				SmashTime = SmashTime,
				ReverseDelay = ReverseWaitTime,
				BombReverseTime = ReverseTime
			);
		}

		// Start playback on all ghosts from previous phases
		for (auto Ghost : PreviousGhosts)
			Ghost.Play(Ghost.GetTotalRecordedDuration());

		SetActorTickEnabled(true);
	}

	/**
	 * Reset the entire gameplay sequence of the crusher back to the start
	 */
	UFUNCTION()
	void ResetCrusherGameplay()
	{
		// If we haven't done the fully synced call to waiting for reverse yet we need to do it now 
		// (Should only happen with massive lag spike)
		if (!bWaitingForReverse)
		{
			bWaitingForReverse = true;
			Sync::FullSyncPoint(this, n"SyncPoint_WaitForReverse");
		}

		StopCrusherGameplay();
		StartNewCrusherPhase();
		RepairClocks();
		DestroyedClockFaces = 0;
	}

	void RepairClocks()
	{
		for (auto Clock : ClockFaceArray)
			Clock.RepairClockFace();
	}

	void WaitForReversing()
	{
		// We now allow a single full synced call to SyncPoint_WaitForReverse.
		bWaitingForReverse = false; 

		State = EClockworkRecordCrusherStage::WaitForReverse;
		TimerInState = 0.f;
		HazeAkComp.HazePostEvent(StartIdleClockTickEvent);
		HazeAkComp.HazePostEvent(AboutToSmashEvent);
		HazeAkComp.HazePostEvent(BombIncomingEvent);
	}

	void ReverseActors()
	{
		if (bBothPlayersDied)
			return;

		SetVhsFX(true);

		State = EClockworkRecordCrusherStage::Reversing;
		TimerInState = 0.f;

		HazeAkComp.HazePostEvent(StartBackwardClockTickEvent);
		HazeAkComp.HazePostEvent(ReverseEvent);

		// Prevent players from doing anything
		for (int i = 0, Count = CurrentGhosts.Num(); i < Count; ++i)
			LockPlayer(CurrentGhosts[i].RecordPlayer, CurrentGhosts[i]);

		// Stop recording on our current ghosts
		for (auto Ghost : CurrentGhosts)
			Ghost.StopRecording();

		for (auto Ghost : PreviousGhosts)
			Ghost.PlayReverse(ReverseTime);

		for (auto Ghost : CurrentGhosts)
			Ghost.PlayReverse(ReverseTime);

		for (AClockworkLastBossRecordCrusherClockFace Clock : ClockFaceArray)
			Clock.RotateClockHands(false);
	}

	void LockPlayer(AHazePlayerCharacter Player, AClockworkRecordCrusherPlayerGhost Ghost)
	{
		ensure(!LockedPlayers.Contains(Player));

		Player.TriggerMovementTransition(this, n"LockPlayerIntoCrusher");
		if (Ghost != nullptr)
			Player.AttachToActor(Ghost);
		LockedPlayers.Add(Player);

		if (!PlayersDamagedDuringPhase.Contains(Player))
		{
			Player.BlockCapabilities(n"Visibility", this);
			Player.BlockCapabilities(n"GameplayAction", this);
			Player.BlockCapabilities(n"Movement", this);
			Player.BlockCapabilities(n"Respawn", this);
		}
		else
		{
			PlayersDamagedDuringPhase.Remove(Player);
			Player.RemovePlayerInvulnerability(this);
		}
	}

	void UnlockPlayer(AHazePlayerCharacter Player)
	{
		ensure(LockedPlayers.Contains(Player));
		LockedPlayers.Remove(Player);

		Player.DetachRootComponentFromParent();

		Player.UnblockCapabilities(n"GameplayAction", this);
		Player.UnblockCapabilities(n"Visibility", this);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Respawn", this);
	}

	void FinishCrusherPhase()
	{
		// Allow players to move again
		for (auto Player : Game::Players)
			UnlockPlayer(Player);

		// Switch current smashers to record our ghosts
		for (int i = 0, Count = CurrentBombs.Num(); i < Count; ++i)
		{
			CurrentBombs[i].CrusherTarget = CurrentGhosts[i];
			PreviousBombs.Add(CurrentBombs[i]);
		}
		CurrentBombs.Empty();

		// Stop recording on our current ghosts
		for (auto Ghost : CurrentGhosts)
			PreviousGhosts.Add(Ghost);
		CurrentGhosts.Empty();

		if (DestroyedClockFaces < ClockFaceArray.Num())
		{
			StartNewCrusherPhase();
		}
		else
		{
			// Send completion event upwards
			State = EClockworkRecordCrusherStage::None;
			StopCrusherGameplay();
			OnGameplayFinished.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TimerInState += DeltaTime;

		float AudioState = 0.f;

		HazeAkComp.SetRTPCValue("Rtpc_Clockwork_UpperTower_Platform_RecordCrusher_PhaseCount", CurrentPhase);

		if (CurrentPhase >= 4 && !bHasPlayedBark)
		{
			bHasPlayedBark = true;
			OnRecordCrusherLoopBark.Broadcast();
		}

		switch (State)
		{
			case EClockworkRecordCrusherStage::None:
				SetActorTickEnabled(false);
			break;
			case EClockworkRecordCrusherStage::Running:
			{
				AudioState = 1.f;
				//PrintToScreenScaled("Running", 0.f);
				float PhaseDuration = RunningTime + (RunningTimeExtendPerPhase * (CurrentPhase - 1));
				float PhasePct = TimerInState / PhaseDuration;

				if (TimerInState >= PhaseDuration)
					WaitForReversing();
			}
			break;
			case EClockworkRecordCrusherStage::WaitForReverse:
			{
				AudioState = 2.f;
				//PrintToScreenScaled("WaitForReverse", 0.f);
				if (TimerInState >= ReverseWaitTime)
				{
					if (!bWaitingForReverse)
					{
						bWaitingForReverse = true;
						Sync::FullSyncPoint(this, n"SyncPoint_WaitForReverse");
					}
				}
			}
			break;
			case EClockworkRecordCrusherStage::Reversing:
			{
				AudioState = 3.f;
				//PrintToScreenScaled("Reversing", 0.f);
				if (TimerInState >= ReverseTime)
					FinishCrusherPhase();
			}
			break;
		}

		
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Clockwork_UpperTower_Platform_RecordCrusher_State", AudioState);
		//PrintToScreenScaled("AudioState: " + AudioState, 0.f);

	}

	UFUNCTION()
	private void SyncPoint_WaitForReverse()
	{
		if (bWaitingForReverse)
		{
			ReverseActors();
			// We do not rest bWaitingForReverse to false until we re-enter the waiting for reverse state
		}
	}

	UFUNCTION()
	void CheckIfBothPlayersWereSmashed()
	{
		if (PlayersDamagedDuringPhase.Num() == 2)
		{
			OnBothPlayersDied.Broadcast();
			bBothPlayersDied = true;
			HazeAkComp.HazePostEvent(StopClockTickEvent);
		}
	}

	UFUNCTION()
	void ClockFaceDestroyed()
	{
		DestroyedClockFaces++;
	}

	// Only called by the event on the PLAYER's control side
	UFUNCTION()
	void BombDamagedPlayer_ControlSide(AClockworkLastBossRecordBomb Crusher, AHazePlayerCharacter Player)
	{
		NetBombDamagedPlayer(Player);
	}

	UFUNCTION(NetFunction)
	void NetBombDamagedPlayer(AHazePlayerCharacter Player)
	{
		devEnsure(State == EClockworkRecordCrusherStage::Running
			|| State == EClockworkRecordCrusherStage::WaitForReverse);

		// To ensure we don't get desynced movement trail
		Player.TriggerMovementTransition(this, n"CrusherBombDamagedPlayer");

		if (!LockedPlayers.Contains(Player) && !PlayersDamagedDuringPhase.Contains(Player))
		{
			Player.AddPlayerInvulnerability(this);
			PlayersDamagedDuringPhase.Add(Player);

			Player.BlockCapabilities(n"Visibility", this);
			Player.BlockCapabilities(n"GameplayAction", this);
			Player.BlockCapabilities(n"Movement", this);
			Player.BlockCapabilities(n"Respawn", this);

			CheckIfBothPlayersWereSmashed();
		}
	}

	void SetVhsFX(bool bOn)
	{
		if (PostProcComp == nullptr)
			PostProcComp = UPostProcessingComponent::Get(Game::GetCody());

		PostProcComp.VHS = bOn ? 1.f : 0.f;
	}
};