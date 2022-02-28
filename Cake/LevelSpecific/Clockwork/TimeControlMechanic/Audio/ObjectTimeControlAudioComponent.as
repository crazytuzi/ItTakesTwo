import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

enum ETimelineSoundTriggerType
{
	AlwaysTrigger,
	TriggerInTimeline,
	TriggerOnRelease,
	TriggerAsTail
}

struct FTimeControlTimelineSound
{
	UPROPERTY()
	float TimelinePos = 0.f;

	UPROPERTY()
	float TimelineReversePos = 0.f;

	float TimelineDuration = 0.f;
	float TimelineReverseDuration = 0.f;

	UPROPERTY()
	FName AttachToMeshBoneOrComponent = n"";

	UPROPERTY()
	UAkAudioEvent ForwardProgressionSound = nullptr;

	UPROPERTY()
	UAkAudioEvent ReverseProgressionSound = nullptr;

	UPROPERTY()
	bool bStopIfIdle = false;

	UPROPERTY()
	bool bPauseIfIdle = false;

	UPROPERTY()
	int32 FadeOutMs = 0.f;

	UPROPERTY()
	ETimelineSoundTriggerType TriggerType = ETimelineSoundTriggerType::AlwaysTrigger;

	UHazeAkComponent HazeAkComp = nullptr;
	FHazeAudioEventInstance TimelineEventInstance = FHazeAudioEventInstance();	
}

class UObjectTimeControlAudioComponent : UActorComponent
{
	UPROPERTY()
	UAkAudioEvent ForwardEvent;

	UPROPERTY()
	ETimelineSoundTriggerType ForwardTriggerType = ETimelineSoundTriggerType::AlwaysTrigger;

	UPROPERTY()
	UAkAudioEvent ReverseEvent;

	UPROPERTY()
	ETimelineSoundTriggerType ReverseTriggerType = ETimelineSoundTriggerType::AlwaysTrigger;

	UPROPERTY()
	int32 FadeOutMs = 0.f;

	UPROPERTY()
	UAkAudioEvent StartLoopingEvent;

	UPROPERTY()
	UAkAudioEvent StopLoopingEvent;

	UPROPERTY()
	UAkAudioEvent FullyProgressedEvent;
	FHazeAudioEventInstance FullyProgressedEventInstance;

	UPROPERTY()
	UAkAudioEvent FullyReversedEvent;
	FHazeAudioEventInstance FullyReversedEventInstance;

	UPROPERTY()
	TArray<FTimeControlTimelineSound> TimelineSounds;

	UPROPERTY()
	bool bDebug = false;

	bool bHasPerformedFullyReversed = false;
	bool bHasPerformedFullyProgressed = false;

	UHazeAkComponent HazeAkComp;
	private FHazeAudioEventInstance ActiveDirectionEventInstance;
	private ETimeControlCrumbType ActiveDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<AHazeActor>(Owner).AddCapability(n"ObjectTimeControlAudioCapability");	
	}

	UFUNCTION()
	void UpdateSoundDirection(UAkAudioEvent CurrentEvent, const float& SeekTime)
	{
		StopActiveSound();

		if(CurrentEvent != nullptr)
		{
			ActiveDirectionEventInstance = HazeAkComp.HazePostEvent(CurrentEvent);
			HazeAkComp.SeekOnPlayingEvent(CurrentEvent, ActiveDirectionEventInstance.PlayingID, SeekTime, false, false, false);
		}	
	}

	UFUNCTION()
	void StopActiveSound()
	{
		if(HazeAkComp.EventInstanceIsPlaying(ActiveDirectionEventInstance))
			HazeAkComp.HazeStopEvent(ActiveDirectionEventInstance.PlayingID, FadeOutTimeMs = FadeOutMs);	
	}

	UFUNCTION()
	void StartLoop()
	{
		HazeAkComp.HazePostEvent(StartLoopingEvent);
	}

	UFUNCTION()
	void StopLoop()
	{
		HazeAkComp.HazePostEvent(StopLoopingEvent);
	}

	UFUNCTION()
	void PostTimelineSound(FTimeControlTimelineSound& TimelineSound, UAkAudioEvent TimelineSoundEvent, const ETimeControlCrumbType& CurrentAction)
	{			
		TimelineSound.TimelineEventInstance = TimelineSound.HazeAkComp.HazePostEvent(TimelineSoundEvent);	
		ActiveDirection = CurrentAction;		
	}

	UFUNCTION()
	void UpdateTimelineSound(FTimeControlTimelineSound& TimelineSound, const ETimeControlCrumbType& CurrentAction, const float& SeekTime, UAkAudioEvent CurrentEvent)
	{
		if(TimelineSound.HazeAkComp == nullptr)
			return;		

		// Stop current Timeline-sound
		if(TimelineSound.HazeAkComp.EventInstanceIsPlaying(TimelineSound.TimelineEventInstance))
			TimelineSound.HazeAkComp.HazeStopEvent(TimelineSound.TimelineEventInstance.PlayingID);		

		// Play new with needed seek Time
		TimelineSound.TimelineEventInstance = TimelineSound.HazeAkComp.HazePostEvent(CurrentEvent);	

		if(TimelineSound.TriggerType != ETimelineSoundTriggerType::TriggerAsTail && CurrentEvent != nullptr)
			TimelineSound.HazeAkComp.SeekOnPlayingEvent(CurrentEvent, TimelineSound.TimelineEventInstance.PlayingID, SeekTime, false, false, false);
		
		ActiveDirection = CurrentAction;
	}

	UFUNCTION()
	void StopTimelineSound(FTimeControlTimelineSound& TimelineSound)
	{
		if(TimelineSound.HazeAkComp.EventInstanceIsPlaying(TimelineSound.TimelineEventInstance))
			TimelineSound.HazeAkComp.HazeStopEvent(TimelineSound.TimelineEventInstance.PlayingID, FadeOutTimeMs = TimelineSound.FadeOutMs);
	}

	UFUNCTION()
	void TimelineFullyProgressed()
	{
		if(!bHasPerformedFullyProgressed)
		{
			FullyProgressedEventInstance = HazeAkComp.HazePostEvent(FullyProgressedEvent);
			bHasPerformedFullyProgressed = true;
		}
	}

	UFUNCTION()
	void StopPerformFullyProgressed()
	{
		if(HazeAkComp.EventInstanceIsPlaying(FullyProgressedEventInstance))
		{
			HazeAkComp.HazeStopEvent(FullyProgressedEventInstance.PlayingID, FadeOutTimeMs = FadeOutMs);
		}
		
		bHasPerformedFullyProgressed = false;
	}

	UFUNCTION()
	void TimelineFullyReversed()
	{
		if(!bHasPerformedFullyReversed)
		{
			FullyReversedEventInstance = HazeAkComp.HazePostEvent(FullyReversedEvent);
			bHasPerformedFullyReversed = true;
		}
	}

	UFUNCTION()
	void StopPerformFullyReversed()
	{
		if(HazeAkComp.EventInstanceIsPlaying(FullyReversedEventInstance))
		{
			HazeAkComp.HazeStopEvent(FullyReversedEventInstance.PlayingID, FadeOutTimeMs = FadeOutMs);
		}

		bHasPerformedFullyReversed = false;
	}
}