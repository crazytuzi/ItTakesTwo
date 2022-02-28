import Vino.Audio.Music.MusicManagerActor;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Vino.Audio.Music.MusicCallbackSubscriberComponent;
import Cake.LevelSpecific.Music.Singing.SingingAudio.SingingAudioComponent;

class UMusicSingingNoteTrackingCapability : UHazeCapability
{
	UMusicCallbackSubscriberComponent CallbackSubComp;
	USingingAudioComponent SingingAudioComp;

	private float LastDelayDuration;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CallbackSubComp = UMusicCallbackSubscriberComponent::GetOrCreate(Owner);
		SingingAudioComp = USingingAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CallbackSubComp.OnMarkerEvent.AddUFunction(this, n"OnMarkerEvent");
		CallbackSubComp.OnMusicSyncBar.AddUFunction(this, n"OnMusicSyncBar");
	}

	UFUNCTION()
	void OnMarkerEvent(UAkMarkerCallbackInfo MarkerInfo)
	{
		FString Head;
		FString Tail;
		if(MarkerInfo.Label.Split("_", Head, Tail))
		{
			if(Head.Contains("Stop"))
			{				
				const float ReleaseTime = Audio::StringToFloat(Tail);
				const float StopTime = MarkerInfo.Position;

				if(ReleaseTime > 0)
					SingingAudioComp.OnStopEnabled(StopTime, ReleaseTime);
				else
					SingingAudioComp.OnStopDisabled();
			}	
		}	
	}	

	UFUNCTION()
	void OnMusicSyncBar(FAkSegmentInfo SegmentInfo)
	{
		if(SegmentInfo.BeatDuration != LastDelayDuration)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_Delay_Duration", SegmentInfo.BeatDuration);
			LastDelayDuration = SegmentInfo.BeatDuration;			
		}
	}
}