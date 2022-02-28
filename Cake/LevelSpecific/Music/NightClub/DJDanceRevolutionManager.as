import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Cake.LevelSpecific.Music.NightClub.DJRoundInfo;
import Cake.LevelSpecific.Music.NightClub.BassDropOMeter;
import Cake.LevelSpecific.Music.NightClub.RhythmActor;

enum EDJDanceRevolutionState
{
	Inactive,
	PreparingToStart,
	Active,
	DoneWaitingToStop
}

enum EDJDanceRevolutionTargetRound
{
	DJStation,
	Dance,
	None
}

// This is used for debugging when we only want to dance or touch dj stations etc.
enum EDJDanceDebugState
{
	Dance,
	DJStation,
	None
}

void SetDebugEnabled_DJStations(AActor DanceManagerActor, bool bInDebugEnabled)
{
	ADJDanceRevolutionManager DanceManager = Cast<ADJDanceRevolutionManager>(DanceManagerActor);

	if(DanceManager != nullptr)
	{
		DanceManager.SetDebugEnabled_DJStations(bInDebugEnabled);
	}
}

bool IsSuperDanceMode(AHazeActor DJDanceActor)
{
	ADJDanceRevolutionManager DJDanceManager = Cast<ADJDanceRevolutionManager>(DJDanceActor);
	if(DJDanceManager != nullptr)
	{
		return DJDanceManager.IsSuperDanceMode();
	}
	return false;
}

int GetCurrentRoundIndex(AHazeActor DJDanceActor)
{
	ADJDanceRevolutionManager DJDanceManager = Cast<ADJDanceRevolutionManager>(DJDanceActor);
	if(DJDanceManager != nullptr)
	{
		return DJDanceManager.CurrentRoundIndex;
	}
	return 0;
}

class ADJDanceRevolutionManager : AHazeActor
{
#if TEST
	default PrimaryActorTick.bStartWithTickEnabled = true;
#endif // TEST

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY()
	ABassDropOMeter BassDropOMeter;

	// In addition to the regular round delay, add extra delay after a dance round.
	UPROPERTY()
	float DelayAfterDance = 5.0f;

	UPROPERTY()
	float UnlimitedDanceAtBassDrop = 0.7f;

	UPROPERTY()
	float DanceTempo = 4.0f;

	UPROPERTY()
	TArray<ARhythmActor> DanceStations;

	UPROPERTY()
	TArray<ADJVinylPlayer> DJStations;

	// Loop rounds starting from somewhere else than the beginning until the end
	UPROPERTY()
	bool bLoopRounds = true;

	// This is the index in the DJRounds list. Make sure this does not exceed the number of rounds or looping will be disabled.
	UPROPERTY(meta = (EditCondition = "bLoopRounds", EditConditionHides))
	int LoopRoundRangeStart = 7;

	// When these rounds are done it will pass over to InfiniteDJRounds.
	UPROPERTY(meta = (DisplayName = "Start DJ Rounds"))
	TArray<FDJRoundInfo> DJRounds;

	// Save next round data in here and read from it when appropriate capability turn activates.
	FDJRoundInfo CurrentRoundInfo;

	private int _NumActiveDJStations = 0;
	private int _NumActiveDJStationsRemote = 0;
	private int _NumActiveDanceStations = 0;
	private int _NumActiveDanceStationsRemote = 0;
	bool bStartDJ = false;
	bool bStopDancing = false;

	EDJDanceRevolutionState DJState = EDJDanceRevolutionState::Inactive;

	int CurrentRoundIndex = -1;

	EDJDanceRevolutionTargetRound RoundTarget = EDJDanceRevolutionTargetRound::None;
	EDJDanceRevolutionTargetRound RoundCurrent = EDJDanceRevolutionTargetRound::None;

	// Set the dj manager to only run either dance or dj-stations
	UPROPERTY(Category = Debug)
	EDJDanceDebugState DebugState = EDJDanceDebugState::None;

	UFUNCTION()
	void PushNextTempo()
	{
		for(ARhythmActor Rhythm : DanceStations)
		{
			Rhythm.PushNextTempo(DanceTempo);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetBassDropOMeterValue() const
	{
		return BassDropOMeter != nullptr ? BassDropOMeter.CurrentBassDropMaster : 0.0f;
	}
//
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BassDropOMeter.DJDanceManager = this;
		AddCapability(n"DJDanceRevolutionTurnCapability");
		AddCapability(n"DJDanceRevolutionDanceCapability");
		AddCapability(n"DJDanceRevolutionDJStationCapability");
		AddDebugCapability(n"DJDanceManagerDebugCapability");
		
		for(ADJVinylPlayer DJStation : DJStations)
		{
			if(DJStation != nullptr)
			{
				RegisterDJStation(DJStation);
			}
		}

		if(bLoopRounds)
		{
			devEnsureAlways(LoopRoundRangeStart < DJRounds.Num(), "LoopRoundRangeStart is " + LoopRoundRangeStart + " and the entries in DJRounds are " + DJRounds.Num() + ". Make sure LoopRoundRangeStart is less or equal to the number of entries in DJRounds.");
		}

		for(ARhythmActor Rhythm : DanceStations)
			Rhythm.OnStopDancing.AddUFunction(this, n"Handle_StopDancing");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_StopDancing(ARhythmActor RhythmActor)
	{
		_NumActiveDanceStations -= 1;
		if(!HasControl())
			NetDecrementActiveDanceStations();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetDecrementActiveDanceStations()
	{
		_NumActiveDanceStationsRemote -= 1;
	}

	UFUNCTION()
	void StartDJ()
	{
		bStartDJ = true;

		for(ADJVinylPlayer DJStation : DJStations)
		{
			if(DJStation != nullptr)
			{
				DJStation.OnStartDJ();
			}
		}
	}

	UFUNCTION()
	void StopDJ()
	{
		bStartDJ = false;
	}

	UFUNCTION()
	void TerminateGameplay()
	{
		StopDJ();

		for(ARhythmActor RhythmActor : DanceStations)
		{
			if(RhythmActor == nullptr)
				continue;

			RhythmActor.StopRhythm();
			RhythmActor.CleanupTempoActors();
		}

		for(ADJVinylPlayer DJPlayer : DJStations)
		{
			if(DJPlayer == nullptr)
				continue;

			DJPlayer.StopDJPlayer();
		}
	}

	UFUNCTION()
	void RegisterDJStation(ADJVinylPlayer DJStation)
	{
		DJStation.OnStartStation.AddUFunction(this, n"Handle_DJStationStart");
		DJStation.OnSuccess.AddUFunction(this, n"Handle_DJStationSuccess");
		DJStation.OnFailure.AddUFunction(this, n"Handle_DJStationFailure");
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Trigger Next Turn"))
	void BP_OnTriggerNextRound(bool bIsDanceTurn) {}

	FDJRoundInfo TriggerNextRound(bool& bRestarted)
	{
		bRestarted = false;
		IncrementRoundIndex();

		BP_OnTriggerNextRound(DJRounds[CurrentRoundIndex].bIsDanceRound);

		return DJRounds[CurrentRoundIndex];
	}

	// Will not increment but provide you with the next round index.
	int GetNextRoundIndex() const
	{
		int TempRoundIdx = CurrentRoundIndex + 1;

		if(TempRoundIdx >= DJRounds.Num())
			return GetLoopRoundRangeStartValue();

		return TempRoundIdx;
	}

	bool IsSuperDanceMode() const
	{
		return GetBassDropOMeterValue() >= UnlimitedDanceAtBassDrop;
	}

	void PeekNextRound(FDJRoundInfo& NextDJRound) const
	{
		int NextIdx = GetNextRoundIndex();
		NextDJRound = DJRounds[NextIdx];
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_DJStationSuccess(ADJVinylPlayer DJStation, AHazePlayerCharacter PlayerCharacter, float ValueToAdd)
	{
		DecrementActiveDJStations();
		BP_OnDJStationSuccess(DJStation, PlayerCharacter, ValueToAdd);
		BassDropOMeter.AddToMasterMeter(ValueToAdd);
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_DJStationFailure(ADJVinylPlayer DJStation, AHazePlayerCharacter PlayerCharacter, float ValueToAdd)
	{
		DecrementActiveDJStations();
		BP_OnDJStationFailure(DJStation, PlayerCharacter, ValueToAdd);
		BassDropOMeter.RemoveFromMasterMeter(ValueToAdd);
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_DJStationStart(ADJVinylPlayer DJStation)
	{
		BP_OnDJStationStart(DJStation);
	}

	private void DecrementActiveDJStations()
	{
		_NumActiveDJStations -= 1;
		if(!HasControl())
			NetDecrementActiveDJStations();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetDecrementActiveDJStations()
	{
		_NumActiveDJStationsRemote -= 1;
	}

	bool IsNextRoundDanceRound() const
	{
		FDJRoundInfo NextRound;
		PeekNextRound(NextRound);
		return NextRound.bIsDanceRound;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Station Success"))
	void BP_OnDJStationSuccess(ADJVinylPlayer DJStation, AHazePlayerCharacter PlayerCharacter, float ValueToAdd) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Station Failure"))
	void BP_OnDJStationFailure(ADJVinylPlayer DJStation, AHazePlayerCharacter PlayerCharacter, float ValueToRemove) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Station Start"))
	void BP_OnDJStationStart(ADJVinylPlayer DJStation) {}

	void CompleteAllDJStation()
	{
		for(ADJVinylPlayer VinylPlayer : DJStations)
		{
			if(VinylPlayer.bIsDJStandActive)
			{
				VinylPlayer.SetToComplete();
			}
		}
	}

	bool HasActiveDJStations() const
	{
		if(Network::IsNetworked())
		{
			return _NumActiveDJStations != 0 && _NumActiveDJStationsRemote != 0;
		}

		return _NumActiveDJStations != 0;
	}

	bool HasActiveDanceStations() const
	{
		if(Network::IsNetworked())
		{
			return _NumActiveDanceStations != 0 && _NumActiveDanceStationsRemote != 0;
		}

		return _NumActiveDanceStations != 0;
	}

	// For bp usage
	UFUNCTION(meta = (DevelopmentOnly))
	void Dev_CompleteAllStations()
	{
		CompleteAllDJStation();
	}

	UFUNCTION(meta = (DevelopmentOnly))
	void Dev_StopDancing()
	{
		bStopDancing = true;
	}

	UFUNCTION(meta = (DevelopmentOnly))
	void Dev_ResetDJRounds()
	{
		CurrentRoundIndex = -1;
		DJDanceCommon::DebugPrint("Reset DJ Rounds");
	}

	UFUNCTION(meta = (DevelopmentOnly))
	void Dev_SkipRound()
	{
		if(CurrentRoundInfo.bIsDanceRound)
		{
			bStopDancing = true;
		}
		else
		{
			CompleteAllDJStation();
		}
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "Start New Round"))
	void BP_StartNewRound() {}
	void StartNewRound(FDJRoundInfo RoundInfo)
	{
		if(RoundInfo.bIsDanceRound)
		{
			StartDanceRound();
		}
		else
		{
			if(HasControl())
			{
				TArray<ADJVinylPlayer> DJStationsToStart;
				
				for(ADJVinylPlayer VinylPlayer : DJStations)
				{
					if(RoundInfo.StationType.Contains(VinylPlayer.DJStandType))
					{
						DJStationsToStart.Add(VinylPlayer);
					}
				}

				_NumActiveDJStations = DJStationsToStart.Num();
				if(Network::IsNetworked())
				{
					_NumActiveDJStationsRemote = _NumActiveDJStations;
				}
				NetStartDJStations(DJStationsToStart);
			}

			BP_StartNewRound();
		}
	}

	UFUNCTION(NetFunction)
	private void NetStartDJStations(TArray<ADJVinylPlayer> DJStationsToStart)
	{
		for(ADJVinylPlayer VinylPlayer : DJStationsToStart)
		{
			VinylPlayer.StartDJStand();
		}
	}

	void IncrementRoundIndex()
	{
		CurrentRoundIndex++;

		if(CurrentRoundIndex >= DJRounds.Num())
		{
			if(bLoopRounds)
				CurrentRoundIndex = GetLoopRoundRangeStartValue();
			else
				CurrentRoundIndex = 0;
		}
	}

	int GetLoopRoundRangeStartValue() const
	{
		devEnsure(LoopRoundRangeStart < DJRounds.Num(), "LoopRounds seem to be enabled but the start index for looping is invalid because it is higher than the number of available entries in DJRounds.");
		return LoopRoundRangeStart < DJRounds.Num() ? LoopRoundRangeStart : 0;
	}

	void StartCurrentDJStations()
	{
		if(!HasControl())
			return;

		TArray<ADJVinylPlayer> DJStationsToStart;

		for(ADJVinylPlayer VinylPlayer : DJStations)
		{
			if(CurrentRoundInfo.StationType.Contains(VinylPlayer.DJStandType))
			{
				DJStationsToStart.Add(VinylPlayer);
			}
		}

		_NumActiveDJStations = DJStationsToStart.Num();
		if(Network::IsNetworked())
		{
			_NumActiveDJStationsRemote = _NumActiveDJStations;
		}
		NetStartDJStations(DJStationsToStart);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Start Dance Round"))
	void BP_OnStartDanceRound() {}
	void StartDanceRound()
	{
		_NumActiveDanceStations = _NumActiveDanceStationsRemote = DanceStations.Num();
		NetStartDanceRound();
	}

	UFUNCTION(NetFunction)
	private void NetStartDanceRound()
	{
		BP_OnStartDanceRound();
		for(ARhythmActor Rhythm : DanceStations)
			Rhythm.StartRhythm();
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Stop Dance Round"))
	void BP_OnStopDanceRound() {}
	// Called by capabilities
	void StopDanceRound()
	{
		NetStopDanceRound();
	}

	UFUNCTION(NetFunction)
	private void NetStopDanceRound()
	{
		BP_OnStopDanceRound();
		for(ARhythmActor Rhythm : DanceStations)
			Rhythm.StopRhythm();
	}

	void SetDebugEnabled_DJStations(bool bInDebugEnabled)
	{
		for(ADJVinylPlayer VinylPlayer : DJStations)
			VinylPlayer.SetDebugEnabled(bInDebugEnabled);
	}

#if TEST
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("ActiveDanceStations " + _NumActiveDanceStations + " | Remote " + _NumActiveDanceStationsRemote);
	}
#endif // TEST
}
