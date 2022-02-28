import Peanuts.Audio.VO.PatrolActorAudioComponent;

UPatrolActorAudioManagerComponent GetPatrolAudioManager()
{
	return UPatrolActorAudioManagerComponent::GetOrCreate(Game::GetMay());	
}

void RegisterPatrolAudioComp(UPatrolActorAudioComponent PatrolAudioComp)
{
	UPatrolActorAudioManagerComponent PatrolAudioManager = GetPatrolAudioManager();

	FPatrolAudioEvents OutPatrolEvents;
	if(PatrolAudioManager.PendingPatrolActorComps.Contains(PatrolAudioComp))
		return;	

	if(PatrolAudioManager.PatrolActorComps.Contains(PatrolAudioComp))
		return;
	
	if(PatrolAudioManager.PendingPatrolActorComps.Num() == 0)
		Reset::RegisterPersistentComponent(PatrolAudioManager);	

	PatrolAudioManager.PendingPatrolActorComps.Add(PatrolAudioComp);
}

void UnregisterPatrolAudioComp(UPatrolActorAudioComponent PatrolAudioComp)
{
	FPatrolAudioEvents OutPatrolEvents;
	UPatrolActorAudioManagerComponent PatrolAudioManager = GetPatrolAudioManager();

	if(PatrolAudioManager.PendingPatrolActorComps.Contains(PatrolAudioComp))
	{
		PatrolAudioManager.PendingPatrolActorComps.RemoveSwap(PatrolAudioComp);
		return;
	}

	if(!PatrolAudioManager.PatrolActorComps.Contains(PatrolAudioComp))
		return;

	PatrolAudioManager.PatrolActorComps.RemoveSwap(PatrolAudioComp);

	if(PatrolAudioComp.PatrolActorHazeAkComp.EventInstanceIsPlaying(PatrolAudioComp.PatrolIdleEventInstance))
		PatrolAudioComp.PatrolActorHazeAkComp.HazeStopEvent(PatrolAudioComp.PatrolIdleEventInstance.PlayingID, 100.f);

	if(PatrolAudioManager.PatrolActorComps.Num() == 0)
		Reset::UnregisterPersistentComponent(PatrolAudioManager);	
}

class UPatrolActorAudioManagerComponent : UActorComponent
{
	TArray<UPatrolActorAudioComponent> PatrolActorComps;
	private TArray<FPatrolAudioEvents> AvaliablePatrolDatas;
	TArray<FPatrolAudioEvents> PatrolDataPool;
	UClass CapabilityClass;

	TArray<UPatrolActorAudioComponent> PendingPatrolActorComps;
	private TMap<UPatrolActorAudioComponent, FPatrolAudioEvents> CompPatrolDataPairs;
	
	void GetAvaliablePatrolEventData(UPatrolActorAudioComponent PatrolComp, FPatrolAudioEvents& OutData)
	{
		if(AvaliablePatrolDatas.Num() == 0)
			AvaliablePatrolDatas = PatrolDataPool;

		if(PatrolComp.OverridePatrolEvents.IsEmptyPatrolData())
		{
			// If patrol event data is not set up to be for a specific actor type, return first index
			if(PatrolComp.PatrolActorType == EPatrolAudioActorType::None)
			{
				OutData = AvaliablePatrolDatas[0];
				AvaliablePatrolDatas.RemoveAtSwap(0);
			}
			else
			{
				// Loop all avaliable datas until we find the corresponding actor type
				bool bFoundMatch = false;
				for(int i = 0; i < AvaliablePatrolDatas.Num(); ++i)
				{
					if(AvaliablePatrolDatas[i].ActorType == PatrolComp.PatrolActorType)
					{
						OutData = AvaliablePatrolDatas[i];
						AvaliablePatrolDatas.RemoveAtSwap(i);
						bFoundMatch = true;
						break;
					}
				}

				// If we looped through avaliable datas and didn't find a match, re-populate it with all datas and try again
				if(!bFoundMatch)
				{
					TArray<FPatrolAudioEvents> TempAvaliableEvents = PatrolDataPool;
					for(int i = 0; i < TempAvaliableEvents.Num(); ++i)
					{
						if(TempAvaliableEvents[i].ActorType == PatrolComp.PatrolActorType)
						{
							OutData = TempAvaliableEvents[i];	
							break;
						}
					}
				}
			}
		}
		else
			OutData = PatrolComp.OverridePatrolEvents;

		CompPatrolDataPairs.FindOrAdd(PatrolComp) = OutData;
	}

	void AddPatrolActorComp(UPatrolActorAudioComponent& PatrolActorComp, FPatrolAudioEvents PatrolEvents)
	{
		PatrolActorComp.IdleEvent = PatrolEvents.IdleEvent;
		PatrolActorComp.OnInterruptedEvent = PatrolEvents.OnTackledEvent;
		PatrolActorComp.OnPerformDeathEvent = PatrolEvents.OnDeathEvent;
		PatrolActorComp.bIsRegistered = true;
		PatrolActorComps.Add(PatrolActorComp);
	}

	void RemovePatrolActorComp(UPatrolActorAudioComponent& PatrolActorComp)
	{
		PatrolActorComp.IdleEvent = nullptr;
		PatrolActorComp.OnInterruptedEvent = nullptr;
		PatrolActorComp.MovementEvent = nullptr;
		PatrolActorComp.OnPerformDeathEvent = nullptr;
		PatrolActorComp.bIsRegistered = false;

		PatrolActorComps.Remove(PatrolActorComp);
	}

	void PerformPatrolActorIdleEvent(UPatrolActorAudioComponent& PatrolAudioComp)
	{
		PatrolAudioComp.PatrolIdleEventInstance = PatrolAudioComp.PatrolActorHazeAkComp.HazePostEvent(PatrolAudioComp.IdleEvent);
		PatrolAudioComp.ActiveTime = 0.f;
		PatrolAudioComp.bIsPlaying = true;
	}

	void BreakPatrolActorIdleEvent(UPatrolActorAudioComponent& PatrolAudioComp)
	{
		if(!PatrolAudioComp.CheckVOIsActive())
			return;

		AkGameplay::ExecuteActionOnPlayingID(AkActionOnEventType::Break, PatrolAudioComp.PatrolIdleEventInstance.PlayingID);
		PatrolAudioComp.TimeSincePlaying = 0.f;
		PatrolAudioComp.ActiveTime = 0.f;	
		PatrolAudioComp.bPendingStop = true;
	}

	void ForceStopPatrolActorEvent(UPatrolActorAudioComponent& PatrolAudioComp)
	{
		if(PatrolAudioComp.PatrolActorHazeAkComp.EventInstanceIsPlaying(PatrolAudioComp.PatrolIdleEventInstance))
			PatrolAudioComp.PatrolActorHazeAkComp.HazeStopEvent(PatrolAudioComp.PatrolIdleEventInstance.PlayingID);		
	}

	bool GetComponentVODatas(const UPatrolActorAudioComponent& PatrolAudioComp, FPatrolAudioEvents& OutPatrolEvents)
	{
		if(CompPatrolDataPairs.Find(PatrolAudioComp, OutPatrolEvents))
			return true;
		
		return false;
	}
}