import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioEventStruct;

class AHazeAmbientSound : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;	
	default HazeAkComp.bIsStatic = bIsStatic;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeDisableComponent DisableComponent;	
	default DisableComponent.bActorIsVisualOnly = true;	
	default DisableComponent.bAutoDisable = false;		

	UPROPERTY()
	TArray<FHazeAudioEventStruct> Events;

	UPROPERTY()
	bool bIsStatic = true;

	UPROPERTY()
	bool TrackPlayerElevationAngle;

	UPROPERTY()
	bool TrackPlayerAbsoluteElevation;

	UPROPERTY(meta = (EditCondition = "TrackPlayerAbsoluteElevation"))
	float ElevationTrackMaxRange = 1000.f;

	UPROPERTY()
	bool TrackDistanceToClosestPlayer;
	
	UPROPERTY(meta = (EditCondition = "TrackDistanceToClosestPlayer"))
	float DistanceToPlayerMaxTrackRange = 1000.f;

	UPROPERTY()
	float VisualizeRange = 0.f;	

	float MaxRangeEnabled = 0.f;

	UPROPERTY(NotVisible)
	int32 HighestLinkedZonePriority = 0;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeAkComp.SetTrackElevationAngle(TrackPlayerElevationAngle);
		HazeAkComp.SetTrackElevation(TrackPlayerAbsoluteElevation);
		HazeAkComp.SetMaxElevationTrackRange(ElevationTrackMaxRange);
		HazeAkComp.SetWorldLocation(GetActorLocation());		

		for	(FHazeAudioEventStruct& EventsEntry : Events)
		{			
			if (EventsEntry.bPlayOnStart)
			{
				int id = HazeAkComp.HazePostEvent(EventsEntry.Event, EventTag = EventsEntry.Tag, 
					PostEventType = EventsEntry.PostEventType).PlayingID;	
				EventsEntry.PlayingIDs.Add(id);										
			}

			if(EventsEntry.Event != nullptr && EventsEntry.Event.HazeMaxAttenuationRadius > MaxRangeEnabled)
			{
				MaxRangeEnabled = EventsEntry.Event.HazeMaxAttenuationRadius + 1000.f;
			}
		}

		if(TrackDistanceToClosestPlayer)
		{
			HazeAkComp.SetTrackDistanceToPlayer(true, MaxRadius = DistanceToPlayerMaxTrackRange);
		}
		
		DisableComponent.AutoDisableRange = MaxRangeEnabled;		
		const bool bShouldUseDisable = DisableComponent.AutoDisableRange > 0.f;
		DisableComponent.SetUseAutoDisable(bShouldUseDisable);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for	(FHazeAudioEventStruct& EventsEntry : Events)
		{
			if (EventsEntry.bStopOnDestroy)
			{
				for	(int PlayingID: EventsEntry.PlayingIDs)
				{
					HazeAkComp.HazeStopEvent(PlayingID, EventsEntry.FadeOutMs, EventsEntry.FadeOutCurve);
				}
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartAmbientSoundEvent(FName Tag)
	{
		for(FHazeAudioEventStruct& EventStruct : Events)
		{
			if(EventStruct.Tag == Tag)
			{
				int id = HazeAkComp.HazePostEvent(EventStruct.Event, EventTag = EventStruct.Tag,
					PostEventType = EventStruct.PostEventType).PlayingID;				
				EventStruct.PlayingIDs.Add(id);	

				if(EventStruct.Event.HazeMaxAttenuationRadius > MaxRangeEnabled)
				{
					MaxRangeEnabled = EventStruct.Event.HazeMaxAttenuationRadius + 1000.f;
				}	
			}
		}

		DisableComponent.AutoDisableRange = MaxRangeEnabled;
		const bool bShouldUseDisable = DisableComponent.AutoDisableRange > 0.f;
		DisableComponent.SetUseAutoDisable(bShouldUseDisable);
	}

	UFUNCTION(BlueprintCallable)
	void StopAmbientSoundEvent(FName Tag, bool bStopAllInstances = false)
	{
		for(int i = Events.Num() - 1; i >= 0; i--)
		{
			if(Events[i].Tag == Tag)
			{	
				if (Events[i].PlayingIDs.Num() > 0)
				{					
					int LastIndex = Events[i].PlayingIDs.Num() - 1;
					int PlayingID = Events[i].PlayingIDs[LastIndex];

					FHazeAudioEventInstance EventInstance = HazeAkComp.GetEventInstanceByPlayingId(PlayingID);
					HazeAkComp.HazeStopEventInstance(EventInstance, Events[i].FadeOutMs, Events[i].FadeOutCurve, bStopAllInstances);
					Events[i].PlayingIDs.RemoveAt(LastIndex);													
				}
			}
		}
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(VisualizeRange > 0.f && HazeAkComp.bDebugAudio)
			System::DrawDebugSphere(GetActorTransform().GetLocation(), VisualizeRange, 16, FLinearColor::DPink, Thickness = 12.f);
	}
	#endif
}