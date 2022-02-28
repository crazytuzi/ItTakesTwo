import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Vino.Audio.Music.MusicIntensityLevelComponent;

class AMusicManagerActor : AHazeMusicManagerActor
{
	UPROPERTY(NotEditable)
	UHazeAkComponent MusicAkComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMusicIntensityLevelComponent MusicIntensityComp;

	UPROPERTY()
	UAkAudioEvent MusicEvent;

	UPROPERTY()
	bool bPlayOnStart;

	UPROPERTY()
	bool bStopActiveEventOnStart = false;

	UPROPERTY()
	bool bActivateMusicCallbacks = false;

	UPROPERTY()
	int32 FadeOutTimeMs = 4000.f;

	UPROPERTY()
	EAkCurveInterpolation FadeOutCurve = EAkCurveInterpolation::Exp1;	

	UPROPERTY()
	FName Tag;

	int GetCallbackMaskForMusicCallbacks()
	{
		return 
			1 << EAkCallbackType::MusicSyncBar | // AkCallbackTypeTest::AK_MusicSyncBar |
			1 << EAkCallbackType::MusicSyncBeat |
			1 << EAkCallbackType::MusicSyncEntry |
			1 << EAkCallbackType::MusicSyncExit |
			1 << EAkCallbackType::MusicSyncGrid |
			1 << EAkCallbackType::MusicSyncPoint |
			1 << EAkCallbackType::MusicSyncUserCue |
			1 << EAkCallbackType::MIDIEvent |
			1 << EAkCallbackType::MusicPlayStarted |
			1 << EAkCallbackType::Marker;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		AudioManager.GetMusicHazeAkComponent(MusicAkComponent);

		if(bPlayOnStart)
		{
			FHazeAudioEventInstance CurrentMusicEventInstance;
			int32 CurrentFadeOut = 0;
			EAkCurveInterpolation CurrentFadeoutCurve = EAkCurveInterpolation::Exp1;
			AudioManager.GetActiveMusicEventInstance(CurrentMusicEventInstance, CurrentFadeOut, CurrentFadeoutCurve);

			// Check that we aren't already playing this music event i.e we've reloaded into the same level
			if(MusicEvent != nullptr && CurrentMusicEventInstance.EventName != MusicEvent.GetName())
			{
				int CallbackMask = bActivateMusicCallbacks ? GetCallbackMaskForMusicCallbacks() : 0;
				// New music event! Start the new one, cache the instance-data in the AudioManager and stop the old one
				FHazeAudioEventInstance NewMusicEventInstance = HazePostMusicEvent(MusicEvent, MusicAkComponent, this, CallbackMask, EventTag = Tag);

				HazeStopMusicEvent(MusicAkComponent, CurrentMusicEventInstance.PlayingID, CurrentFadeOut, CurrentFadeoutCurve);
				AudioManager.SetActiveMusicEventInstance(NewMusicEventInstance, FadeOutTimeMs, FadeOutCurve);
			}
		}
		// Special case for when we want to stop the previous levelset music no matter what.
		else if (bStopActiveEventOnStart && !bPlayOnStart)
		{
			FHazeAudioEventInstance CurrentMusicEventInstance;
			int32 CurrentFadeOut = 0;
			EAkCurveInterpolation CurrentFadeoutCurve = EAkCurveInterpolation::Exp1;
			AudioManager.GetActiveMusicEventInstance(CurrentMusicEventInstance, CurrentFadeOut, CurrentFadeoutCurve);
			HazeStopMusicEvent(MusicAkComponent, CurrentMusicEventInstance.PlayingID, CurrentFadeOut, CurrentFadeoutCurve);
		}
		
		MusicIntensityComp.Enable(this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MusicIntensityComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void HandleMusicCallbacks(const TArray<UHazeMusicManagerComponent>& CallbackSubs, EAkCallbackType CallbackType, UAkMusicSyncCallbackInfo CallbackInfo)
	{			
		switch (CallbackType)
		{	
			case EAkCallbackType::MusicPlayStarted:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicPlayStarted.Broadcast(CallbackInfo.SegmentInfo);
				}				
				break;
			case EAkCallbackType::MusicSyncBeat:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{					
					SubComp.OnMusicSyncBeat.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;
			case EAkCallbackType::MusicSyncBar:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncBar.Broadcast(CallbackInfo.SegmentInfo);
				}				
				break;
			case EAkCallbackType::MusicSyncEntry:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncEntry.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;
			case EAkCallbackType::MusicSyncExit:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncExit.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;
			case EAkCallbackType::MusicSyncGrid:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncGrid.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;
			case EAkCallbackType::MusicSyncUserCue:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncCustomCue.Broadcast(FName(CallbackInfo.UserCueName));
				}
				break;
			case EAkCallbackType::MusicSyncPoint:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMusicSyncPoint.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;
			case EAkCallbackType::MIDIEvent:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMIDIEvent.Broadcast(CallbackInfo.SegmentInfo);
				}
				break;

			case EAkCallbackType::Marker:
				for(UHazeMusicManagerComponent SubComp : CallbackSubs)
				{
					SubComp.OnMarkerEvent.Broadcast(Cast<UAkMarkerCallbackInfo>(CallbackInfo));
				}
				break;
			case EAkCallbackType::EndOfEvent:
			{
				RemoveMusicEventInstance(MusicAkComponent, CallbackInfo.PlayingID);
			}
			default:
				break;
		}
		
	}

	UFUNCTION(BlueprintCallable)
	void HazePostMusicStinger(const FString Trigger)
	{	
		MusicAkComponent.PostTrigger(Trigger);
	}

};