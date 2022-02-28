import Peanuts.Foghorn.FoghornDebugStatics;
import Peanuts.Foghorn.FoghornEfforts;
import Peanuts.Foghorn.FoghornEventBase;
import Peanuts.Foghorn.FoghornEventBark;
import Peanuts.Foghorn.FoghornEventDialogue;
import Peanuts.Foghorn.FoghornVoiceLineHelpers;
import Rice.TemporalLog.TemporalLogComponent;

enum EFoghornManagerState
{
	Active,
	Stopped
}

enum EFoghornLaneState
{
	Idle,
	Playing,
	ResumePlaying,
	QueueHold
}

enum EFoghornPlayType
{
	Bark,
	Dialogue,
};

struct FFoghornQueueData
{
	int Priority;
	EFoghornPlayType PlayType;

	UFoghornBarkDataAsset BarkAsset;
	UFoghornDialogueDataAsset DialogueAsset;
	AActor Actor;
	FFoghornMultiActors Actors;
}

class UFoghornLane
{
	EFoghornLaneName LaneName;
	EFoghornLaneState CurrentState = EFoghornLaneState::Idle;

	FFoghornResumeInfo ResumeInfo;
	AActor ResumePlayingActor;
	float ResumeDelayTimer = 0.0f;

	TArray<FFoghornQueueData> PlayQueue;

	UFoghornEventBase CurrentEvent;
}

#if !RELEASE
// These "structs" are UObject classes so we can read the properties automatically
class UFoghornLaneDebugState
{
	FString Status;
	FFoghornEventDebugInfo EventDebugInfo;
	FString OnResume;
	TArray<FString> Queue;
	TArray<FString> Rejected;
};

class UFoghornDebugState
{
	FString Status;
	TArray<UFoghornLaneDebugState> Lanes;
	TArray<FString> Efforts;
	TArray<FString> Paused;
	TArray<FString> RejectedEfforts;
};
struct FFoghornDebugRejectedEvent
{
	int Lane;
	FString Text;
}
#endif

class UFoghornManagerComponent : UHazeFoghornManagerBaseComponent
{
	UPROPERTY()
	UFoghornBarkDataAsset DefaultTransitionBarkDataAsset;

	UPROPERTY()
	TMap<FName, int> VOBankState;

	FoghornEfforManager EffortManager = FoghornEfforManager();

	private TMap<FName, FFoghornBarkRuntimeData> BarkRuntimeData;
	private TMap<FName, FFoghornDialogueRuntimeData> DialogueRuntimeData;

	private EFoghornManagerState ManagerState = EFoghornManagerState::Active;

	private bool bMinigameMode = false;

	private TArray<AActor> PausedActors;

	private TArray<UFoghornLane> Lanes;

	#if !RELEASE
	private TArray<FFoghornDebugRejectedEvent> DebugRejectedEvents;
	private UFoghornDebugState DebugState = UFoghornDebugState();

	private void DebugEventRejected(FString Text)
	{
		FFoghornDebugRejectedEvent Event;
		Event.Lane = -1;
		Event.Text = Text;
		DebugRejectedEvents.Add(Event);
	}

	private void DebugEventRejected(FString Text, EFoghornLaneName LaneName)
	{
		FFoghornDebugRejectedEvent Event;
		Event.Lane = int(LaneName);
		Event.Text = Text;
		DebugRejectedEvents.Add(Event);
	}
	#endif

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void BeginPlay()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		// Disable tick on Non-May players
		if(Player == nullptr || !Player.IsMay())
		{
			SetComponentTickEnabled(false);
		}
		else
		{
			SetupLanes();
		}
	}

	private void SetupLanes()
	{
		for (int i = 0; i< int(EFoghornLaneName::EFoghornLaneName_MAX); ++i)
		{
			UFoghornLane NewLane = UFoghornLane();
			NewLane.LaneName = EFoghornLaneName(i);
			Lanes.Add(NewLane);
		}
	}

	private UFoghornLane GetLane(EFoghornLaneName LaneName)
	{
		int LaneIndex = int(LaneName);
		if (!Lanes.IsValidIndex(LaneIndex))
		{
			PrintError("Invalid LaneName " + LaneName);
			return nullptr;
		}
		return Lanes[LaneIndex];
	}

	private void TickCooldowns(float DeltaTime)
	{
		for (TMapIterator<FName, FFoghornBarkRuntimeData>& BarkDataIt : BarkRuntimeData)
		{
			FFoghornBarkRuntimeData& BarkData = BarkDataIt.GetValue();
			if (BarkData.CooldownTimer > 0.0f)
			{
				BarkData.CooldownTimer -= DeltaTime;

				#if !RELEASE
					if (BarkData.CooldownTimer <= 0.0f)
						FoghornDebugLog("Cooldown on bark " + BarkDataIt.Key + " has ended" );
				#endif
			}
		}

		for (TMapIterator<FName, FFoghornDialogueRuntimeData>& DialogueDataIt: DialogueRuntimeData)
		{
			FFoghornDialogueRuntimeData& DialogueData = DialogueDataIt.GetValue();
			if (DialogueData.CooldownTimer > 0.0f)
			{
				DialogueData.CooldownTimer -= DeltaTime;

				#if !RELEASE
					if (DialogueData.CooldownTimer <= 0.0f)
						FoghornDebugLog("Cooldown on dialogue " + DialogueDataIt.Key + " has ended" );
				#endif
			}
		}
	}

	private bool InternalTickPlaying(UFoghornLane Lane, float DeltaTime)
	{
		bool Finished = Lane.CurrentEvent.Tick(DeltaTime);
		if (!Finished)
		{
			AActor CurrentActor = Lane.CurrentEvent.ActiveActor;
			if (PausedActors.Contains(CurrentActor))
			{
				int StopBitshift = 1 << int(Lane.LaneName);
				NetPause(CurrentActor, StopBitshift);
			}

			// TODO: whill this check make the checks on begin play uncessesary?
			StopActorsOnOtherLanes(Lane.LaneName, CurrentActor);
		}
		return Finished;
	}

	private void InternalPlayResumeEvent(UFoghornLane Lane)
	{
		Lane.CurrentState = EFoghornLaneState::Idle;
		const FFoghornResumeInfo& ResumeInfo = Lane.ResumeInfo;
		if (ResumeInfo.BarkAsset != nullptr)
		{
			NetPlayBark(ResumeInfo.BarkAsset, ResumeInfo.Actor, ResumeInfo.VoiceLineIndex, ResumeInfo.Playime, true);
		}
		else if (ResumeInfo.DialogueAsset != nullptr)
		{
			NetResumePlayDialogue(ResumeInfo.DialogueAsset, ResumeInfo.Actors, ResumeInfo.VoiceLineIndex, EFoghornLaneState::Playing, ResumeInfo.Playime, false);
		}
		Lane.ResumeInfo = FFoghornResumeInfo();
	}

	private void AdvanceQueue(UFoghornLane Lane)
	{
		Lane.CurrentState = EFoghornLaneState::Idle;

		#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Advancing Queue. Queue size " + Lane.PlayQueue.Num());
		#endif

		bool StartedPlaying = false;
		while (Lane.PlayQueue.Num() > 0 && StartedPlaying == false)
		{
			if (Lane.PlayQueue[0].PlayType == EFoghornPlayType::Bark)
			{
				StartedPlaying = PlayBark(Lane.PlayQueue[0].BarkAsset, Lane.PlayQueue[0].Actor);
			}
			else if (Lane.PlayQueue[0].PlayType == EFoghornPlayType::Dialogue)
			{
				AActor DialogueActor = FoghornEventDialogueGetActorForVoiceLine(Lane.PlayQueue[0].DialogueAsset.VoiceLines[0], Lane.PlayQueue[0].Actors);
				// Transition to QueueHold if the first actor in a dialoge is paused instead of discarding the Dialogue
				if (PausedActors.Contains(DialogueActor))
				{
					// Discard all barks from queue when entering QueueHold
					for (int i = Lane.PlayQueue.Num()-1; i > 0; --i)
					{
						if (Lane.PlayQueue[i].PlayType == EFoghornPlayType::Bark)
						{
							Lane.PlayQueue.RemoveAtSwap(i);
						}
					}
					Lane.CurrentState = EFoghornLaneState::QueueHold;
					break;
				}
				StartedPlaying = PlayDialogue(Lane.PlayQueue[0].DialogueAsset, Lane.PlayQueue[0].Actors);
			}

			Lane.PlayQueue.RemoveAt(0);
		}
	}

	private void TickPlaying(UFoghornLane Lane, float DeltaTime)
	{
		bool Finished = InternalTickPlaying(Lane, DeltaTime);
		if (Finished)
		{
			AdvanceQueue(Lane);
		}
	}

	private void TickResumePlaying(UFoghornLane Lane, float DeltaTime)
	{
		if (Lane.ResumeDelayTimer > 0.0f)
		{
			Lane.ResumeDelayTimer -= DeltaTime;
			if (Lane.ResumeDelayTimer <= 0.0f)
			{
				InternalPlayResumeEvent(Lane);
			}
			return;
		}

		bool Finished = InternalTickPlaying(Lane, DeltaTime);
		if (Finished)
		{
			if (Lane.ResumeInfo.ActiveActor == Lane.ResumePlayingActor)
			{
				// Hardcoded delay set to 1s
				Lane.ResumeDelayTimer = 1.0f;
			}
			else
			{
				AdvanceQueue(Lane);
			}
		}
	}

	private void TickLane(UFoghornLane Lane, float DeltaTime)
	{
		switch(Lane.CurrentState)
		{
			case EFoghornLaneState::Idle:
			case EFoghornLaneState::QueueHold:
				break;
			case EFoghornLaneState::Playing:
				TickPlaying(Lane, DeltaTime);
				break;
			case EFoghornLaneState::ResumePlaying:
				TickResumePlaying(Lane, DeltaTime);
				break;
		}
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void Tick(float DeltaTime)
	{
		// Remove destroyed actors from PausedActors
		for (int i = PausedActors.Num()-1; i>=0; --i)
		{
			if (PausedActors[i] == nullptr || PausedActors[i].IsActorBeingDestroyed())
			{
				PausedActors.RemoveAtSwap(i);
				#if !RELEASE
					FoghornDebugLog("Removed destroyed actor from PausedActors");
				#endif
			}
		}

		#if !RELEASE
		BuildDebugState();
		PrintDebugTick();
		#endif

		TickCooldowns(DeltaTime);
		EffortManager.Tick(DeltaTime);

		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			TickLane(Lanes[LaneIndex], DeltaTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		for (auto Lane : Lanes)
		{
			StopCurrentIfPlaying(Lane);
		}
		EffortManager.Reset();
		bMinigameMode = false;

		// Only save stuff between levels if marked as super persist
		bool bRequireSuper = ResetType == EComponentResetType::LevelChange;

		TMap<FName, FFoghornBarkRuntimeData> PersistentBarkRuntimeData;
		for (TMapIterator<FName, FFoghornBarkRuntimeData>& BarkDataIt : BarkRuntimeData)
		{
			if ((BarkDataIt.Value.PersistPlayOnce && !bRequireSuper) || BarkDataIt.Value.SuperPersistPlayOnce)
			{
				#if !RELEASE
					FoghornDebugLog("Persisting " + BarkDataIt.Key);
				#endif

				BarkDataIt.Value.NextIndex = -1;
				BarkDataIt.Value.CooldownTimer = 0.0f;

				PersistentBarkRuntimeData.Add(BarkDataIt.Key, BarkDataIt.Value);
			}
		}
		if (PersistentBarkRuntimeData.Num() > 0)
		{
			BarkRuntimeData = PersistentBarkRuntimeData;
		}
		else
		{
			BarkRuntimeData.Reset();
		}

		TMap<FName, FFoghornDialogueRuntimeData> PersistentDialogueRuntimeData;
		for (TMapIterator<FName, FFoghornDialogueRuntimeData>& DialogueDataIt: DialogueRuntimeData)
		{
			if ((DialogueDataIt.Value.PersistPlayOnce && !bRequireSuper) || DialogueDataIt.Value.SuperPersistPlayOnce)
			{
				#if !RELEASE
					FoghornDebugLog("Persisting " + DialogueDataIt.Key);
				#endif

				DialogueDataIt.Value.CooldownTimer = 0.0f;

				PersistentDialogueRuntimeData.Add(DialogueDataIt.Key, DialogueDataIt.Value);
			}
		}
		if (PersistentDialogueRuntimeData.Num() > 0)
		{
			DialogueRuntimeData = PersistentDialogueRuntimeData;
		}
		else
		{
			DialogueRuntimeData.Reset();
		}

		VOBankState.Reset();
		ManagerState = EFoghornManagerState::Active;
		PausedActors.Reset();

		Lanes.Reset();
		SetupLanes();

		#if !RELEASE
			DebugRejectedEvents.Reset();
			DebugState = UFoghornDebugState();
			FoghornDebugLog("OnResetComponent " + ResetType + ", RequireSuper " + bRequireSuper);
		#endif
	}

	void SetupBarkRuntimeData(UFoghornBarkDataAsset BarkAsset)
	{
		FFoghornBarkRuntimeData TempBarkData;
		bool Found = BarkRuntimeData.Find(BarkAsset.Name, TempBarkData);
		if (!Found)
		{
			FFoghornBarkRuntimeData NewBarkData;
			NewBarkData.PersistPlayOnce = BarkAsset.PersistPlayOnce && (BarkAsset.PlayOnce || BarkAsset.PlayAllOnce);
			NewBarkData.SuperPersistPlayOnce = BarkAsset.bSuperPersistPlayOnce;
			FoghornVoiceLineHelpers::SetupShuffle(NewBarkData, BarkAsset);
			BarkRuntimeData.Add(BarkAsset.Name, NewBarkData);
		}
		else if (TempBarkData.NextIndex == -1)
		{
			FoghornVoiceLineHelpers::SetupShuffle(BarkRuntimeData[BarkAsset.Name], BarkAsset);
		}
	}

	private void StopActorsOnOtherLanes(EFoghornLaneName Lane, AActor Actor)
	{
		int CurrentLaneIndex = int(Lane);
		for (int LaneIndex = CurrentLaneIndex+1; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			if (IsCurrentlyActive(Lanes[LaneIndex]) && Lanes[LaneIndex].CurrentEvent.ActiveActor == Actor)
			{
				#if !RELEASE
					FoghornDebugLog(Lane, "Lane " + Lanes[LaneIndex].LaneName + " stopped from Actor " + Actor.Name + " playing on Lane " + EFoghornLaneName(Lane));
				#endif

				Lanes[LaneIndex].CurrentEvent.Stop();
			}
		}
	}

	private int FindBlockingLane(EFoghornLaneName Lane, AActor Actor)
	{
		int CurrentLaneIndex = int(Lane);
		for (int LaneIndex = 0; LaneIndex < CurrentLaneIndex; ++LaneIndex)
		{
			if (IsCurrentlyActive(Lanes[LaneIndex]) && Lanes[LaneIndex].CurrentEvent.ActiveActor == Actor)
			{
				return LaneIndex;
			}
		}
		return -1;
	}

	// TODO: Rename since this does shit like adding to queue when it sounds like its a check only
	private bool InternalShouldTriggerBark(UFoghornLane Lane, UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		const FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];

		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Foghorn is globally stopped. Not playing Bark " + BarkAsset.Name);
				DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Foghorn Stopped", Lane.LaneName);
			#endif
			return false;
		}

		if (bMinigameMode == true && BarkAsset.bPlayDuringMinigameMode == false)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Foghorn is in Minigame Mode. Not playing Bark " + BarkAsset.Name);
				DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Foghorn in MinigameMode", Lane.LaneName);
			#endif
			return false;
		}

		#if !RELEASE
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && BarkAsset.PlayOnce && BarkData.PlayedOnce)
			{
				FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " is set to PlayOnce and has already been played");
				DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Play Once", Lane.LaneName);
				return false;
			}
		#else
			if (BarkAsset.PlayOnce && BarkData.PlayedOnce)
			{
				return false;
			}
		#endif

		#if !RELEASE
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && BarkAsset.PlayAllOnce && BarkData.AllPlayedOnce)
			{
				#if !RELEASE
					FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " is set to PlayAllOnce and all has already been played once");
					DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Play All Once", Lane.LaneName);
				#endif
				return false;
			}
		#else
			if (BarkAsset.PlayAllOnce && BarkData.AllPlayedOnce)
			{
				return false;
			}
		#endif

		if (BarkData.CooldownTimer > 0.0f)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " is still on cooldown with " + BarkData.CooldownTimer + " left");
				DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  On Cooldown", Lane.LaneName);
			#endif
			return false;
		}

		if (BarkAsset.Probability < 100)
		{
			int Rand = FMath::RandRange(1,100);
			if (Rand > BarkAsset.Probability) {
				#if !RELEASE
					FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " failed probability check");
					DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Failed Probability", Lane.LaneName);
				#endif
				return false;
			}
		}

		AActor Actor = FoghornVoiceLineHelpers::GetActorForBark(BarkAsset.Character, ActorOverride);

		// Check if any lane with higher priority is playing from the same actor
		int BlockingLane = FindBlockingLane(Lane.LaneName, Actor);
		if (BlockingLane >= 0)
		{
			#if !RELEASE
					FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " has Actor " + Actor.Name + " blocked by Lane " + EFoghornLaneName(BlockingLane));
					DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Blocked by other Lane", Lane.LaneName);
			#endif
			return false;
		}

		bool bPlay = !IsCurrentlyActive(Lane);
		if (!bPlay)
			bPlay = BarkAsset.UseQueue ? BarkAsset.Priority > Lane.CurrentEvent.Priority : BarkAsset.Priority >= Lane.CurrentEvent.Priority;

		if (bPlay)
		{
			#if !RELEASE
				if (IsCurrentlyActive(Lane))
					FoghornDebugLog(Lane.LaneName, "Interrupting currently playing, new vs old priority " + BarkAsset.Priority + " vs " + Lane.CurrentEvent.Priority);
			#endif

			if (PausedActors.Contains(Actor))
			{
				#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Actor is Paused. Not playing Bark " + BarkAsset.Name);
				DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Actor Paused", Lane.LaneName);
				#endif
				return false;
			}

			return true;
		}
		else if(BarkAsset.UseQueue == true)
		{
			FFoghornQueueData NewQueueData;
			NewQueueData.Priority = BarkAsset.Priority;
			NewQueueData.PlayType = EFoghornPlayType::Bark;
			NewQueueData.BarkAsset = BarkAsset;
			NewQueueData.Actor = ActorOverride;

			QueueInsertSorted(Lane, NewQueueData);
		}
		#if !RELEASE
		else
		{
			FoghornDebugLog(Lane.LaneName, "Bark " + BarkAsset.Name + " not staring with priority " + BarkAsset.Priority + " vs current priority " + Lane.CurrentEvent.Priority);
			DebugEventRejected("Bark  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Priority/Not Queued", Lane.LaneName);
		}
		#endif

		return false;
	}

	bool PlayBark(UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		SetupBarkRuntimeData(BarkAsset);

		UFoghornLane Lane = GetLane(BarkAsset.Lane);
		bool ShouldTrigger = InternalShouldTriggerBark(Lane, BarkAsset, ActorOverride);
		if (ShouldTrigger)
		{
			FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];
			BarkData.PlayedOnce = true;
			BarkData.CooldownTimer = BarkAsset.Cooldown;

			int VoiceLineIndex = FoghornVoiceLineHelpers::GetNextVoiceLine(BarkData, BarkAsset);
			FFoghornVoiceLine VoiceLine = BarkAsset.VoiceLines[VoiceLineIndex];

			AActor Actor = FoghornVoiceLineHelpers::GetActorForBark(BarkAsset.Character, ActorOverride);
			NetPlayBark(BarkAsset, Actor, VoiceLineIndex);

			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Playing Bark " + BarkAsset.Name + " -> " + VoiceLine.AudioEvent.Name + " on Actor " + (Actor == nullptr ? "null" : Actor.Name.ToString()));
			#endif
		}
		return ShouldTrigger;
	}

	private bool InternalShouldTriggerEffort(UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];

		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
				FoghornDebugLog("Foghorn is globally stopped. Not playing Effort " + BarkAsset.Name);
				DebugEventRejected("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Foghorn Stopped");
			#endif
			return false;
		}

		#if !RELEASE
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && BarkAsset.PlayOnce && BarkData.PlayedOnce)
			{
				FoghornDebugLog("Effort " + BarkAsset.Name + " is set to PlayOnce and has already been played");
				DebugEventRejected("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Play Once");
				return false;
			}
		#else
			if (BarkAsset.PlayOnce && BarkData.PlayedOnce)
			{
				return false;
			}
		#endif

		#if !RELEASE
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && BarkAsset.PlayAllOnce && BarkData.AllPlayedOnce)
			{
				FoghornDebugLog("Effort " + BarkAsset.Name + " is set to PlayAllOnce and all has already been played once");
				DebugEventRejected("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Play Once");
				return false;
			}
		#else
			if (BarkAsset.PlayAllOnce && BarkData.AllPlayedOnce)
			{
				return false;
			}
		#endif

		if (BarkData.CooldownTimer > 0.0f)
		{
			#if !RELEASE
				FoghornDebugLog("Effort " + BarkAsset.Name + " is still on cooldown with " + BarkData.CooldownTimer + " left");
				DebugEventRejected("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  On Cooldown");
			#endif
			return false;
		}

		if (BarkAsset.Probability < 100)
		{
			int Rand = FMath::RandRange(1,100);
			if (Rand > BarkAsset.Probability) {
				#if !RELEASE
					FoghornDebugLog("Effort " + BarkAsset.Name + " failed probability check");
					DebugEventRejected("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Failed Probability");
				#endif
				return false;
			}
		}

		return true;
	}

	void PlayEffort(UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		SetupBarkRuntimeData(BarkAsset);

		bool ShouldTrigger = InternalShouldTriggerEffort(BarkAsset, ActorOverride);
		if (ShouldTrigger)
		{
			FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];
			EffortManager.PlayEffort(BarkAsset, ActorOverride, BarkData);
		}
	}

	private bool InternalShouldTriggerDialogue(UFoghornLane Lane, UFoghornDialogueDataAsset DialogueAsset, const FFoghornMultiActors& ExtraActors)
	{
		if (!DialogueRuntimeData.Contains(DialogueAsset.Name))
		{
			FFoghornDialogueRuntimeData NewDialogueData;
			NewDialogueData.PersistPlayOnce = DialogueAsset.PersistPlayOnce && DialogueAsset.PlayOnce;
			NewDialogueData.SuperPersistPlayOnce = DialogueAsset.bSuperPersistPlayOnce;
			DialogueRuntimeData.Add(DialogueAsset.Name, NewDialogueData);
		}

		const FFoghornDialogueRuntimeData& DialogueData = DialogueRuntimeData[DialogueAsset.Name];

		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Foghorn is globally stopped. Not playing Dialogue " + DialogueAsset.Name);
				DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Foghorn Stopped", Lane.LaneName);
			#endif
			return false;
		}

		if (bMinigameMode == true && DialogueAsset.bPlayDuringMinigameMode == false)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Foghorn is in Minigame Mode. Not playing Dialogue " + DialogueAsset.Name);
				DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Foghorn in MinigameMode", Lane.LaneName);
			#endif
			return false;
		}

		#if !RELEASE
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && DialogueAsset.PlayOnce && DialogueData.PlayedOnce)
			{
				FoghornDebugLog(Lane.LaneName, "Dialogue " + DialogueAsset.Name + " is set to PlayOnce and has already been played");
				DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Play Once", Lane.LaneName);
				return false;
			}
		#else
			if (DialogueAsset.PlayOnce && DialogueData.PlayedOnce)
			{
				return false;
			}
		#endif

		if (DialogueData.CooldownTimer > 0.0f)
		{
			#if !RELEASE
				FoghornDebugLog(Lane.LaneName, "Dialogue " + DialogueAsset.Name + " is still on cooldown with " + DialogueData.CooldownTimer + " left");
				DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  On Cooldown", Lane.LaneName);
			#endif
			return false;
		}

		if (DialogueAsset.Probability < 100)
		{
			int Rand = FMath::RandRange(1,100);
			if (Rand > DialogueAsset.Probability) {
				#if !RELEASE
					FoghornDebugLog(Lane.LaneName, "Dialogue " + DialogueAsset.Name + " failed probability check");
					DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Failed Probability", Lane.LaneName);
				#endif
				return false;
			}
		}

		AActor FirstDialogueActor = FoghornEventDialogueGetActorForVoiceLine(DialogueAsset.VoiceLines[0], ExtraActors);
		if (PausedActors.Contains(FirstDialogueActor))
		{
			#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Actor is Paused. Not playing Dialogue " + DialogueAsset.Name);
			DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Actor Paused", Lane.LaneName);
			#endif
			return false;
		}

		// Check if any lane with higher priority is playing from the same actor
		int BlockingLane = FindBlockingLane(Lane.LaneName, FirstDialogueActor);
		if (BlockingLane >= 0)
		{
			#if !RELEASE
					FoghornDebugLog(Lane.LaneName, "Dialogue " + DialogueAsset.Name + " has Actor " + FirstDialogueActor.Name + " blocked by Lane " + EFoghornLaneName(BlockingLane));
					DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Blocked by other Lane", Lane.LaneName);
			#endif
			return false;
		}

		bool bPlay = !IsCurrentlyActive(Lane);
		if (!bPlay)
			bPlay = DialogueAsset.UseQueue ? DialogueAsset.Priority > Lane.CurrentEvent.Priority : DialogueAsset.Priority >= Lane.CurrentEvent.Priority;

		if (bPlay)
		{
			#if !RELEASE
				if (IsCurrentlyActive(Lane))
					FoghornDebugLog(Lane.LaneName, "Interrupting currently playing, new vs old priority " + DialogueAsset.Priority + " vs " + Lane.CurrentEvent.Priority);
			#endif

			return true;
		}
		else if(DialogueAsset.UseQueue == true)
		{
			FFoghornQueueData NewQueueData;
			NewQueueData.Priority = DialogueAsset.Priority;
			NewQueueData.PlayType = EFoghornPlayType::Dialogue;
			NewQueueData.DialogueAsset = DialogueAsset;
			NewQueueData.Actors = ExtraActors;

			QueueInsertSorted(Lane, NewQueueData);
		}
		#if !RELEASE
		else
		{
			FoghornDebugLog(Lane.LaneName, "Dialogue " + DialogueAsset.Name + " not staring with priority " + DialogueAsset.Priority + " vs current priority " + Lane.CurrentEvent.Priority);
			DebugEventRejected("Dialogue  " + DialogueAsset.Priority + "  " + DialogueAsset.Name + "  Priority/Not Queued", Lane.LaneName);
		}
		#endif
		return false;
	}

	bool PlayDialogue(UFoghornDialogueDataAsset DialogueAsset, const FFoghornMultiActors& ExtraActors)
	{
		UFoghornLane Lane = GetLane(DialogueAsset.Lane);
		bool ShouldTrigger = InternalShouldTriggerDialogue(Lane, DialogueAsset, ExtraActors);
		if (ShouldTrigger)
		{
			FFoghornDialogueRuntimeData& DialogueData = DialogueRuntimeData[DialogueAsset.Name];
			DialogueData.PlayedOnce = true;
			DialogueData.CooldownTimer = DialogueAsset.Cooldown;

			NetPlayDialogue(DialogueAsset, ExtraActors);
		}
		return ShouldTrigger;
	}

	void Pause(AActor ActorToPause)
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
			FoghornDebugLog("Foghorn is stopped");
			#endif
			return;
		}

		if (!PausedActors.Contains(ActorToPause))
		{
			PausedActors.Add(ActorToPause);
		}

		int LanesToStopBitshift = 0;
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			UFoghornLane Lane = Lanes[LaneIndex];
			if (IsCurrentlyActive(Lane) && Lane.CurrentEvent.ActiveActor == ActorToPause)
			{
				LanesToStopBitshift |= (1 << LaneIndex);
			}
		}

		NetPause(ActorToPause, LanesToStopBitshift);
	}

	void PauseWithEffort(AActor ActorToPause, UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
			FoghornDebugLog("Foghorn is stopped");
			#endif
			return;
		}

		if (!PausedActors.Contains(ActorToPause))
		{
			PausedActors.Add(ActorToPause);
		}

		int LanesToStopBitshift = 0;
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			UFoghornLane Lane = Lanes[LaneIndex];
			if (IsCurrentlyActive(Lane) && Lane.CurrentEvent.ActiveActor == ActorToPause)
			{
				LanesToStopBitshift |= (1 << LaneIndex);
			}
		}
		NetPauseWithEffort(ActorToPause, LanesToStopBitshift, BarkAsset, ActorOverride);
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void Stop()
	{
		bMinigameMode = false;
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			#if !RELEASE
			FoghornDebugLog("Foghorn is already stopped");
			#endif
			return;
		}

		if (PausedActors.Num() > 0)
		{
			PausedActors.Reset();
			#if !RELEASE
			FoghornDebugLog("Foghorn had paused actors when stopped");
			#endif
		}

		for (auto Lane : Lanes)
		{
			Lane.PlayQueue.Empty();
			Lane.ResumeInfo = FFoghornResumeInfo();
			Lane.ResumePlayingActor = nullptr;
			Lane.ResumeDelayTimer = 0.0f;
		}

		NetStop();
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void ResumeAllIfStopped()
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			NetSetActive();
			#if !RELEASE
				FoghornDebugLog("ResumeAllIfStopped Resumed");
			#endif
			return;
		}
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void SetGamePaused(bool bPaused)
	{
		#if !RELEASE
			FoghornDebugLog("SetGamePaused " + bPaused);
		#endif
		if (bPaused)
		{
			for (UFoghornLane Lane : Lanes)
			{
				if (IsCurrentlyActive(Lane))
				{
					Lane.CurrentEvent.PauseAkEvent();
				}
			}
		}
		else
		{
			for (UFoghornLane Lane : Lanes)
			{
				if (IsCurrentlyActive(Lane))
				{
					Lane.CurrentEvent.ResumeAkEvent();
				}
			}
		}
	}

	void ResumeAll()
	{
		Resume(nullptr);
	}

	void Resume(AActor ActorToResume)
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			NetSetActive();
			return;
		}

		if (ActorToResume == nullptr)
		{
			NetResumeAll();
			PausedActors.Reset();
			// Resume lane with highest priority
			for (auto Lane : Lanes)
			{
				const FFoghornResumeInfo& ResumeInfo = Lane.ResumeInfo;
				if (ResumeInfo.BarkAsset != nullptr)
				{
					NetPlayBark(ResumeInfo.BarkAsset, ResumeInfo.Actor, ResumeInfo.VoiceLineIndex, ResumeInfo.Playime, true);
					break;
				}
				else if (ResumeInfo.DialogueAsset != nullptr)
				{
					NetResumePlayDialogue(ResumeInfo.DialogueAsset, ResumeInfo.Actors, ResumeInfo.VoiceLineIndex, EFoghornLaneState::Playing, ResumeInfo.Playime, false);
					break;
				}
			}

			// Clear resume info for all Lanes
			for (auto Lane : Lanes)
				Lane.ResumeInfo = FFoghornResumeInfo();
		}
		else if (PausedActors.Contains(ActorToResume))
		{
			NetResumeActor(ActorToResume);
			PausedActors.RemoveSwap(ActorToResume);

			// Resume Lane with highest priority and the unpaused actor in ResumeInfo
			for (auto Lane : Lanes)
			{
				if (Lane.ResumeInfo.ActiveActor != ActorToResume)
					continue;

				const FFoghornResumeInfo& ResumeInfo = Lane.ResumeInfo;
				if (ResumeInfo.BarkAsset != nullptr)
				{
					NetPlayBark(ResumeInfo.BarkAsset, ResumeInfo.Actor, ResumeInfo.VoiceLineIndex, ResumeInfo.Playime, false, true);
					Lane.ResumeInfo = FFoghornResumeInfo();
					break;
				}
				else if (ResumeInfo.DialogueAsset != nullptr)
				{
					NetResumePlayDialogue(ResumeInfo.DialogueAsset, ResumeInfo.Actors, ResumeInfo.VoiceLineIndex, EFoghornLaneState::Playing, ResumeInfo.Playime, true);
					Lane.ResumeInfo = FFoghornResumeInfo();
					break;
				}
			}
		}

		for (auto Lane : Lanes)
		{
			// Advance all on QueueHold, nothing will happen if the hold actor still is paused.
			// CurrentState will be playing for Lanes that where started above.
			if (Lane.CurrentState == EFoghornLaneState::QueueHold)
			{
				AdvanceQueue(Lane);
			}
		}

		#if !RELEASE
			FoghornDebugLog("Resumed Foghorn");
		#endif
	}

	void ResumeWithBark(AActor ActorToResume, UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			NetSetActive();
			return;
		}

		if (!PausedActors.Contains(ActorToResume))
		{
			return;
		}

		NetResumeActor(ActorToResume);
		PausedActors.RemoveSwap(ActorToResume);

		UFoghornLane Lane = GetLane(BarkAsset.Lane);
		Lane.ResumePlayingActor = ActorToResume;
		if ((Lane.ResumeInfo.BarkAsset != nullptr || Lane.ResumeInfo.DialogueAsset != nullptr) && Lane.ResumeInfo.SkipResumeTransitions)
		{
			InternalPlayResumeEvent(Lane);
			return;
		}

		SetupBarkRuntimeData(BarkAsset);
		bool ShouldTrigger = InternalShouldTriggerBark(Lane, BarkAsset, ActorOverride);
		if (ShouldTrigger)
		{
			FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];
			BarkData.PlayedOnce = true;
			BarkData.CooldownTimer = BarkAsset.Cooldown;

			int VoiceLineIndex = FoghornVoiceLineHelpers::GetNextVoiceLine(BarkData, BarkAsset);
			FFoghornVoiceLine VoiceLine = BarkAsset.VoiceLines[VoiceLineIndex];

			AActor Actor = FoghornVoiceLineHelpers::GetActorForBark(BarkAsset.Character, ActorOverride);
			NetResumePlayBark(BarkAsset, Actor, VoiceLineIndex);

			#if !RELEASE
				FoghornDebugLog("Playing Bark " + BarkAsset.Name + " -> " + VoiceLine.AudioEvent.Name + " on Actor " + Actor.Name);
			#endif
		}

		for (auto HoldCheckLane : Lanes)
		{
			if (HoldCheckLane.CurrentState == EFoghornLaneState::QueueHold)
			{
				AdvanceQueue(HoldCheckLane);
			}
		}
	}

	void ResumeWithDialogue(AActor ActorToResume, UFoghornDialogueDataAsset DialogueAsset, const FFoghornMultiActors& ExtraActors)
	{
		if (ManagerState == EFoghornManagerState::Stopped)
		{
			NetSetActive();
			return;
		}

		if (!PausedActors.Contains(ActorToResume))
		{
			return;
		}

		NetResumeActor(ActorToResume);
		PausedActors.RemoveSwap(ActorToResume);

		UFoghornLane Lane = GetLane(DialogueAsset.Lane);
		Lane.ResumePlayingActor = ActorToResume;
		if ((Lane.ResumeInfo.BarkAsset != nullptr || Lane.ResumeInfo.DialogueAsset != nullptr) && Lane.ResumeInfo.SkipResumeTransitions)
		{
			InternalPlayResumeEvent(Lane);
			return;
		}

		bool ShouldTrigger = InternalShouldTriggerDialogue(Lane, DialogueAsset, ExtraActors);
		if (ShouldTrigger)
		{
			FFoghornDialogueRuntimeData& DialogueData = DialogueRuntimeData[DialogueAsset.Name];
			DialogueData.PlayedOnce = true;
			DialogueData.CooldownTimer = DialogueAsset.Cooldown;

			NetResumePlayDialogue(DialogueAsset, ExtraActors, 0, EFoghornLaneState::ResumePlaying, 0.0f, false);
		}

		for (auto HoldCheckLane : Lanes)
		{
			if (HoldCheckLane.CurrentState == EFoghornLaneState::QueueHold)
			{
				AdvanceQueue(HoldCheckLane);
			}
		}
	}

	void SetMinigameModeEnabled(bool bEnabled)
	{
		#if !RELEASE
		if (bMinigameMode != bEnabled)
			FoghornDebugLog("Foghorn Minigame mode " + (bEnabled ? "Enabled" : "Disabled"));
		else
			FoghornDebugLog("Foghorn Minigame mode already "+ (bEnabled ? "Enabled" : "Disabled"));
		#endif

		bMinigameMode = bEnabled;
	}

	const float ForcedPreDelayTime = 1.0f;

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayBark(UFoghornBarkDataAsset BarkAsset, AActor Actor, int VoiceLineIndex, float StartTime = 0.0f, bool SkipPreDelay = false, bool ForcePreDelay = false)
	{
		UFoghornLane Lane = GetLane(BarkAsset.Lane);
		StopCurrentIfPlaying(Lane);
		StopActorsOnOtherLanes(Lane.LaneName, Actor);

		float PreDelayTime = ForcePreDelay ? ForcedPreDelayTime : 0.0f;

		// Starts playing automatically
		Lane.CurrentState = EFoghornLaneState::Playing;
		if (Lane.CurrentEvent != nullptr)
			Lane.CurrentEvent.OnReplacedInLane();
		Lane.CurrentEvent = UFoghornEventBark(EffortManager, BarkAsset, Actor, Lane.LaneName, VoiceLineIndex, StartTime, SkipPreDelay, PreDelayTime);
		Lane.CurrentEvent.Initialize();

		#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Starting NetPlayBark " + BarkAsset.Name);
		#endif
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetResumePlayBark(UFoghornBarkDataAsset BarkAsset, AActor Actor, int VoiceLineIndex)
	{
		UFoghornLane Lane = GetLane(BarkAsset.Lane);
		StopCurrentIfPlaying(Lane);
		StopActorsOnOtherLanes(Lane.LaneName, Actor);

		Lane.ResumeDelayTimer = 0.0f;
		Lane.CurrentState = EFoghornLaneState::ResumePlaying;

		// Starts playing automatically
		if (Lane.CurrentEvent != nullptr)
			Lane.CurrentEvent.OnReplacedInLane();
		Lane.CurrentEvent = UFoghornEventBark(EffortManager, BarkAsset, Actor, Lane.LaneName, VoiceLineIndex);
		Lane.CurrentEvent.Initialize();

		#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Starting NetResumePlayBark " + BarkAsset.Name);
		#endif
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayDialogue(UFoghornDialogueDataAsset DialogueAsset, const FFoghornMultiActors& ExtraActors)
	{
		UFoghornLane Lane = GetLane(DialogueAsset.Lane);
		#if !RELEASE
		FoghornDebugLog(Lane.LaneName, "NetPlayDialogue");
		#endif
		StopCurrentIfPlaying(Lane);

		// Starts playing automatically
		Lane.CurrentState = EFoghornLaneState::Playing;
		if (Lane.CurrentEvent != nullptr)
			Lane.CurrentEvent.OnReplacedInLane();
		Lane.CurrentEvent = UFoghornEventDialogue(EffortManager, DialogueAsset, ExtraActors, 0, Lane.LaneName);
		Lane.CurrentEvent.Initialize();

		#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Starting NetPlayDialogue " + DialogueAsset.Name);
		#endif
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetResumePlayDialogue(UFoghornDialogueDataAsset DialogueAsset, const FFoghornMultiActors& ExtraActors, int StartIndex, EFoghornLaneState PlayState, float StartTime, bool ForcePreDelay)
	{
		UFoghornLane Lane = GetLane(DialogueAsset.Lane);
		#if !RELEASE
		FoghornDebugLog(Lane.LaneName, "NetResumePlayDialogue StartIndex:" + StartIndex);
		#endif

		StopCurrentIfPlaying(Lane);
		Lane.CurrentState = PlayState;

		float PreDelayTime = ForcePreDelay ? ForcedPreDelayTime : 0.0f;

		// Starts playing automatically
		if (Lane.CurrentEvent != nullptr)
			Lane.CurrentEvent.OnReplacedInLane();
		Lane.CurrentEvent = UFoghornEventDialogue(EffortManager, DialogueAsset, ExtraActors, StartIndex, Lane.LaneName, StartTime, false, PreDelayTime);
		Lane.CurrentEvent.Initialize();

		#if !RELEASE
			FoghornDebugLog(Lane.LaneName, "Starting NetResumePlayDialogue " + DialogueAsset.Name);
		#endif
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetStop()
	{
		#if !RELEASE
			FoghornDebugLog("Stopped Foghorn");
		#endif
		
		StopAllLanes();
		EffortManager.Stop();
		ManagerState = EFoghornManagerState::Stopped;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetActive()
	{
		#if !RELEASE
			FoghornDebugLog("NetSetActive");
		#endif
		ManagerState = EFoghornManagerState::Active;
	}

	void CheckResumeCount(FFoghornResumeInfo& ResumeInfo, EFoghornLaneName LaneName)
	{
		// Only do this check on Mays control side
		if (!Game::GetMay().HasControl())
			return;

		const int ResumeCountLimit = 2;
		if (ResumeInfo.BarkAsset != nullptr && BarkRuntimeData.Contains(ResumeInfo.BarkAsset.Name))
		{
			FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[ResumeInfo.BarkAsset.Name];
			if (!ResumeInfo.BarkAsset.bMayHasMarkers)
				BarkData.ResumeCount++;

			#if !RELEASE
			FoghornDebugLog(LaneName, "Bark " + ResumeInfo.BarkAsset.Name + " ResumeCount " + BarkData.ResumeCount);
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && BarkData.ResumeCount > ResumeCountLimit)
			{
				FoghornDebugLog(LaneName, "Bark " + ResumeInfo.BarkAsset.Name + " hit resume limit, clearing resume info");
				ResumeInfo = FFoghornResumeInfo();
			}
			#else
			if (BarkData.ResumeCount > ResumeCountLimit)
			{
				ResumeInfo = FFoghornResumeInfo();
			}
			#endif
		}
		else if(ResumeInfo.DialogueAsset != nullptr && DialogueRuntimeData.Contains(ResumeInfo.DialogueAsset.Name))
		{
			FFoghornDialogueRuntimeData& DialogueData = DialogueRuntimeData[ResumeInfo.DialogueAsset.Name];
			if (!ResumeInfo.DialogueAsset.bMayHasMarkers)
				DialogueData.ResumeCount++;

			#if !RELEASE
			FoghornDebugLog(LaneName, "Dialogue " + ResumeInfo.DialogueAsset.Name + " ResumeCount " + DialogueData.ResumeCount);
			if (CVar_FoghornDebugDisablePlayOnce.GetInt() == 0 && DialogueData.ResumeCount > ResumeCountLimit)
			{
				FoghornDebugLog(LaneName, "Dialogue " + ResumeInfo.DialogueAsset.Name + " hit resume limit, clearing resume info");
				ResumeInfo = FFoghornResumeInfo();
			}
			#else
			if (DialogueData.ResumeCount > ResumeCountLimit)
			{
				ResumeInfo = FFoghornResumeInfo();
			}
			#endif
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPause(AActor ActorToPause, int LanesToStopBitshift)
	{
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			if (LanesToStopBitshift & (1 << LaneIndex) > 0)
			{
				UFoghornLane Lane = Lanes[LaneIndex];
				if (IsCurrentlyActive(Lane))
				{
					Lane.ResumeInfo = Lane.CurrentEvent.Stop();
					CheckResumeCount(Lane.ResumeInfo, Lane.LaneName);
				}
			}
		}

		EffortManager.BlockActor(ActorToPause);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPauseWithEffort(AActor ActorToPause, int LanesToStopBitshift, UFoghornBarkDataAsset BarkAsset, AActor ActorOverride)
	{
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			if (LanesToStopBitshift & (1 << LaneIndex) > 0)
			{
				UFoghornLane Lane = Lanes[LaneIndex];
				if (IsCurrentlyActive(Lane))
				{
					Lane.ResumeInfo = Lane.CurrentEvent.Stop();
					CheckResumeCount(Lane.ResumeInfo, Lane.LaneName);
				}
			}
		}

		SetupBarkRuntimeData(BarkAsset);
		bool ShouldTrigger = InternalShouldTriggerEffort(BarkAsset, ActorOverride);
		if (ShouldTrigger)
		{
			FFoghornBarkRuntimeData& BarkData = BarkRuntimeData[BarkAsset.Name];
			EffortManager.PlayEffort(BarkAsset, ActorOverride, BarkData, true);
		}
		else
		{
			AActor Actor = FoghornVoiceLineHelpers::GetActorForBark(BarkAsset.Character, ActorOverride);
			EffortManager.BlockActor(Actor);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetResumeActor(AActor Actor)
	{
		EffortManager.ClearBlockedActor(Actor);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetResumeAll()
	{
		EffortManager.ClearAllBlockedActors();
	}

	private bool IsCurrentlyActive(UFoghornLane Lane)
	{
		return (Lane.CurrentState == EFoghornLaneState::Playing || Lane.CurrentState == EFoghornLaneState::ResumePlaying);
	}

	private void StopCurrentIfPlaying(UFoghornLane Lane)
	{
		if (IsCurrentlyActive(Lane))
		{
			Lane.CurrentEvent.Stop();
		}
	}

	private void StopAllLanes()
	{
		for (auto Lane : Lanes)
		{
			StopCurrentIfPlaying(Lane);
		}
	}

	void QueueInsertSorted(UFoghornLane Lane, FFoghornQueueData QueueData)
	{
		int InsertIndex = 0;

		TArray<FFoghornQueueData>& PlayQueue = Lane.PlayQueue;
		for (int i=0; i<PlayQueue.Num(); ++i)
		{
			if (PlayQueue[i].Priority < QueueData.Priority)
			{
				break;
			}
			InsertIndex++;
		}
		PlayQueue.Insert(QueueData, InsertIndex);

		#if !RELEASE
		if (QueueData.PlayType == EFoghornPlayType::Bark)
			FoghornDebugLog(Lane.LaneName, "Queued Bark " + QueueData.BarkAsset.Name + " at index " + InsertIndex + "/" + PlayQueue.Num());
		else
			FoghornDebugLog(Lane.LaneName, "Queued Dialogue " + QueueData.DialogueAsset.Name + " at index " + InsertIndex + "/" + PlayQueue.Num());
		#endif
	}

	void DebugTemporalLog(UTemporalLogObject LogObject)
	{
		#if !RELEASE
		TMap<FName, FString> Data;
		DebugObjectProperties(DebugState, Data);
		for (TMapIterator<FName, FString> Iter : Data)
		{
			LogObject.LogValue(Iter.Key, Iter.Value);
		}

		for (int LaneIndex = 0; LaneIndex < FMath::Min(Lanes.Num(), DebugState.Lanes.Num()); ++LaneIndex)
		{
			const FString LanePropNameHax = "Lane|" + LaneIndex + "|.";
			Data.Reset();
			DebugObjectProperties(DebugState.Lanes[LaneIndex], Data);
			for (TMapIterator<FName, FString> Iter : Data)
			{
				LogObject.LogValue(FName(LanePropNameHax + Iter.Key), Iter.Value);
			}

			if (IsCurrentlyActive(Lanes[LaneIndex]) && DebugState.Lanes[LaneIndex].EventDebugInfo.Actor != nullptr)
			{
				UHazeAkComponent HazeAkComp = UHazeAkComponent::Get(DebugState.Lanes[LaneIndex].EventDebugInfo.Actor);
				FVector Location = HazeAkComp.GetWorldLocation();
				LogObject.LogSphere(FName(LanePropNameHax + "CurrentPlaying"), Location, 50.0f, FLinearColor::Blue);
			}
		}

		TArray<FFoghornDebugEffortLocation> EffortLocations;
		EffortManager.DebugGetEffortLocations(EffortLocations);

		for (auto EffortLocation : EffortLocations)
		{
			LogObject.LogSphere(EffortLocation.Name, EffortLocation.Location, 50.0f, FLinearColor::Yellow);
		}
		#endif
	}

	#if !RELEASE
	private void BuildDebugState()
	{
		bool MayControlSide = Game::GetMay().HasControl();
		FString Status = MayControlSide ? "Control Side" : "Slave Side";
		Status += " " + ManagerState;
		if (PausedActors.Num() > 0)
		{
			Status += ", " + PausedActors.Num() + " Paused";
		}

		DebugState.Status = Status;

		if (DebugState.Lanes.Num() != Lanes.Num())
		{
			DebugState.Lanes.Reset();
			for (int i = 0; i<Lanes.Num(); ++i)
			{
				DebugState.Lanes.Add(UFoghornLaneDebugState());
			}
		}

		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			UFoghornLane Lane = Lanes[LaneIndex];
			UFoghornLaneDebugState LaneDebugState = DebugState.Lanes[LaneIndex];
			LaneDebugState.Status = "Lane " + Lane.LaneName + "  " + Lane.CurrentState;
			if (IsCurrentlyActive(Lane))
			{
				LaneDebugState.EventDebugInfo = Lane.CurrentEvent.GetDebugInfo();
			}
			else
			{
				LaneDebugState.EventDebugInfo = FFoghornEventDebugInfo();
			}

			LaneDebugState.OnResume = "";
			if (PausedActors.Num() > 0)
			{
				const FFoghornResumeInfo& ResumeInfo = Lane.ResumeInfo;
				if (ResumeInfo.BarkAsset != nullptr)
				{
					LaneDebugState.OnResume = ResumeInfo.BarkAsset.Name;
				}
				else if(ResumeInfo.DialogueAsset != nullptr)
				{
					LaneDebugState.OnResume = ResumeInfo.DialogueAsset.Name + "  " + ResumeInfo.VoiceLineIndex;
				}
				else
				{
					LaneDebugState.OnResume = "Nothing";
				}
			}

			LaneDebugState.Queue.Empty();
			for (auto Queued : Lane.PlayQueue)
			{
				FString QueuedText = "";
				if (Queued.PlayType == EFoghornPlayType::Bark)
				{
					QueuedText += "Bark  " + Queued.BarkAsset.Name;
				}
				else if(Queued.PlayType == EFoghornPlayType::Dialogue)
				{
					QueuedText += "Dialogue  " + Queued.DialogueAsset.Name;
				}
				QueuedText += " " + Queued.Priority;
				LaneDebugState.Queue.Add(QueuedText);
			}
		}

		for (const FFoghornDebugRejectedEvent& Event : DebugRejectedEvents)
		{
			if (DebugState.Lanes.IsValidIndex(Event.Lane))
			{
				DebugState.Lanes[Event.Lane].Rejected.Add(Event.Text);
			}
			else
			{
				DebugState.RejectedEfforts.Add(Event.Text);
			}
		}

		DebugRejectedEvents.Empty();

		DebugState.Efforts.Empty();
		EffortManager.DebugGetLines(DebugState.Efforts, DebugState.RejectedEfforts);

		DebugState.Paused.Empty();
		for (auto Actor : PausedActors)
		{
			DebugState.Paused.Add(Actor.Name);
		}

		for (auto DbgLane : DebugState.Lanes)
		{
			while (DbgLane.Rejected.Num() > 10)
			{
				DbgLane.Rejected.RemoveAt(0);
			}
		}
	}
	private void PrintDebugTick()
	{
		if (CVar_FoghornDebugModeEnabled.GetInt() == 0)
		{
			return;
		}
		bool MayControlSide = Game::GetMay().HasControl();

		auto DebugLines = TArray<FString>();

		if (CVar_FoghornDebugDisablePlayOnce.GetInt() != 0 )
		{
			DebugLines.Add("PlayOnce Disabled");
		}

		if (bMinigameMode == true)
		{
			DebugLines.Add("Minigame Mode Enabled");
		}

		for (const auto LaneDbg : DebugState.Lanes)
		{
			DebugLines.Add(LaneDbg.Status);

			if (LaneDbg.EventDebugInfo.Asset != "")
			{
				FString DbgLine = LaneDbg.EventDebugInfo.Type
				+ "  "
				+ LaneDbg.EventDebugInfo.Asset
				+ " on "
				+ (LaneDbg.EventDebugInfo.Actor != nullptr ? LaneDbg.EventDebugInfo.Actor.Name.ToString() : "NullActor")
				+ "  prio  "
				+ LaneDbg.EventDebugInfo.Priority;

				if (LaneDbg.EventDebugInfo.PreDelayTimer > 0.0f)
					DbgLine += "  " + LaneDbg.EventDebugInfo.PreDelayTimer + " pre delay";

				DebugLines.Add("    " + DbgLine);
			}
			else
			{
				DebugLines.Add("    Not playing");
			}

			if (LaneDbg.OnResume != "")
			{
				DebugLines.Add("    On Resume: " + LaneDbg.OnResume);
			}

			if (LaneDbg.Queue.Num() > 0)
			{
				DebugLines.Add("    Queue:");
				for (FString Line : LaneDbg.Queue)
				{
					DebugLines.Add("        " + Line);
				}
			}
			else
			{
				if (MayControlSide)
					DebugLines.Add("    Queue Empty");
			}

			if (LaneDbg.Rejected.Num() > 0)
			{
				DebugLines.Add("    Latest Rejected:");
				// Add last 4 rejected in reverse
				int End = LaneDbg.Rejected.Num();
				int Start = FMath::Max(End-4, 0);
				for (int i=End-1; i>=Start; --i)
				{
					DebugLines.Add("        " + LaneDbg.Rejected[i]);
				}
			}
		}

		if (DebugState.Efforts.Num() > 0)
		{
			DebugLines.Add("Efforts:");
			for (FString Line : DebugState.Efforts)
			{
				DebugLines.Add("    " + Line);
			}
		}

		if (DebugState.Paused.Num() > 0)
		{
			DebugLines.Add("Paused:");
			for (FString Line : DebugState.Paused)
			{
				DebugLines.Add("    " + Line);
			}
		}

		if (DebugState.RejectedEfforts.Num() > 0)
		{
			DebugLines.Add("Latest Rejected Efforts:");

			// Add last 4 rejected in reverse
			int End = DebugState.RejectedEfforts.Num();
			int Start = FMath::Max(End-4, 0);
			for (int i=End-1; i>=Start; --i)
			{
				DebugLines.Add("    " + DebugState.RejectedEfforts[i]);
			}
		}

		FLinearColor PrintColor = MayControlSide ? FLinearColor::Green : FLinearColor::Purple;
		for (int i = DebugLines.Num()-1; i>=0; --i)
		{
			PrintToScreen("    " + DebugLines[i], 0, PrintColor);
		}
		PrintToScreen("Foghorn Debug, " + DebugState.Status, 0, PrintColor);
	}
	#endif
}
