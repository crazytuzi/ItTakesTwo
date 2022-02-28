import Peanuts.Audio.VO.PatrolActorAudioManagerComponent;
import Peanuts.Audio.VO.PatrolActorAudioComponent;

class UPatrolActorAudioManagerCapability : UHazeCapability
{
	UPROPERTY()
	TArray<FPatrolAudioEvents> PatrolDatas;

	UPatrolActorAudioManagerComponent PatrolAudioManager;

	const int32 PER_FRAME_DISTANCE_CHECKS = 10;
	int32 CurrentLookupIndex = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PatrolAudioManager = GetPatrolAudioManager();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PatrolAudioManager == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(PatrolAudioManager.PendingPatrolActorComps.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PatrolAudioManager.PatrolDataPool = PatrolDatas;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PatrolAudioManager == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PatrolAudioManager.PatrolActorComps.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasPendingControlActors())
		{
			HandlePendingPatrolActors();
		}

		QueryPatrolActorsActiveState();
		QueryPatrolActorsTriggerState(DeltaTime);
	}

	void HandlePendingPatrolActors()
	{
		for(int i = PatrolAudioManager.PendingPatrolActorComps.Num() - 1; i >= 0; i--)
		{
			FPatrolAudioEvents PatrolEvents;
			PatrolAudioManager.GetAvaliablePatrolEventData(PatrolAudioManager.PendingPatrolActorComps[i], PatrolEvents);

			PatrolAudioManager.AddPatrolActorComp(PatrolAudioManager.PendingPatrolActorComps[i], PatrolEvents);
			PatrolAudioManager.PendingPatrolActorComps.RemoveAtSwap(i);
		}
	}

	void QueryPatrolActorsActiveState()
	{
		for(int i = CurrentLookupIndex; i < CurrentLookupIndex + PER_FRAME_DISTANCE_CHECKS && i < PatrolAudioManager.PatrolActorComps.Num(); ++i)
		{
			auto& AudioComp = PatrolAudioManager.PatrolActorComps[i];

			if(!AudioComp.PatrolActorHazeAkComp.bIsEnabled)
				continue;

			if(AudioComp.HasListenerInRange() && !AudioComp.CheckVOIsActive())
			{
				AudioComp.UpdateCanTrigger(true);
			}			
			else if(!AudioComp.HasListenerInRange() && AudioComp.CheckVOIsActive())
			{
				AudioComp.UpdateCanTrigger(false);
				AudioComp.SetRandomTriggerTime(AudioComp.MinTriggerTime, AudioComp.MaxTriggerTime);
			}
		}

		CurrentLookupIndex += PER_FRAME_DISTANCE_CHECKS;
		if(CurrentLookupIndex > PatrolAudioManager.PatrolActorComps.Num())
			CurrentLookupIndex = 0;
	}

	void QueryPatrolActorsTriggerState(float DeltaSeconds)
	{
		for(UPatrolActorAudioComponent& AudioComp : PatrolAudioManager.PatrolActorComps)
		{
			if(!AudioComp.bCanTrigger || !AudioComp.PatrolActorHazeAkComp.bIsEnabled)
				continue;			

			AudioComp.ActiveTime += DeltaSeconds;
			if(AudioComp.ActiveTime >= AudioComp.TriggerTime && !AudioComp.CheckVOIsActive())
			{
				PatrolAudioManager.PerformPatrolActorIdleEvent(AudioComp);
				AudioComp.SetRandomStopTime(AudioComp.MinActiveTime, AudioComp.MaxActiveTime);
			}
			else if(AudioComp.ActiveTime >= AudioComp.StopTime && AudioComp.CheckVOIsActive())
			{
				PatrolAudioManager.BreakPatrolActorIdleEvent(AudioComp);
				AudioComp.SetRandomTriggerTime(AudioComp.MinTriggerTime, AudioComp.MaxTriggerTime);
			}	

			AudioComp.SetMovementRTPC();		
		}
	}

	bool HasPendingControlActors()
	{
		return PatrolAudioManager.PendingPatrolActorComps.Num() > 0;
	}

}