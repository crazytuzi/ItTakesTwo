import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Microphone;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.CablePulse.CablePulseActor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.CablePulse.SpeakerLauchVolume;

struct FPowerfulSongMicSpeakerEventPair
{
	UPROPERTY(EditInstanceOnly)
	UAkAudioEvent MicrophoneInPowerfulSongEvent;

	UPROPERTY(EditInstanceOnly)
	UAkAudioEvent SpeakerOutPowerfulSongEvent;
}

UCLASS(Abstract)
class UPowerfulSongMicSpeakerAudioReactionComponent : UActorComponent
{	
	UPROPERTY(EditInstanceOnly)
	TArray<FPowerfulSongMicSpeakerEventPair> PowerfulSongEventPairs;

	AMicrophone Microphone;

	UPROPERTY(EditInstanceOnly, Category = "Microphone")
	UAkAudioEvent OnMicrophoneSongImpactEvent;

	UPROPERTY(EditInstanceOnly, Category = "Speaker")
	ASpeakerLaunchVolume SpeakerVolume;

	UPROPERTY(EditAnywhere, Category = "Speaker")
	UAkAudioEvent OnSpeakerSongOutputEvent;

	UPROPERTY(EditInstanceOnly, Category = "Cable")
	ACablePulseActor CablePulse;

	private UHazeAkComponent CablePulseHazeAkComp;

	UPROPERTY(EditDefaultsOnly, Category = "Cable")
	UAkAudioEvent CablePulseStartEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Cable")
	UAkAudioEvent CablePulseStopEvent;

	UPROPERTY(VisibleAnywhere, Category = "Cable")
	FString CablePulseProgressRtpc = "Rtpc_Gameplay_Gadgets_Microphone_Cable_Pulse_Progress";

	APowerfulSongProjectile SongProjectile;
	UAkAudioEvent CurrentSpeakerOutEvent;
	private bool bWaitingForSpeakerActivation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Microphone = Cast<AMicrophone>(Owner);

		if(Microphone != nullptr)
			Microphone.OnHitByPowerfulSong.AddUFunction(this, n"HandleOnMicrophoneImpact");

		if(CablePulse != nullptr)
		{
			CablePulseHazeAkComp = UHazeAkComponent::GetOrCreate(CablePulse);
			CablePulse.OnReachedEnd.AddUFunction(this, n"OnCablePulseReachedEnd");
		}
	}

	UFUNCTION()
	void HandleOnMicrophoneImpact(FPowerfulSongInfo Info)
	{
		UHazeAkComponent::HazePostEventFireForget(OnMicrophoneSongImpactEvent, Microphone.GetActorTransform());			
		SongProjectile = Cast<APowerfulSongProjectile>(Info.Projectile);

		if(SongProjectile != nullptr)
		{
			UAkAudioEvent InSpeakerEvent = SongProjectile.AttachedPowerfulSongEvent;
			GetOutSpeakerEvent(InSpeakerEvent, CurrentSpeakerOutEvent);						
		}
	}

	UFUNCTION()
	void OnCablePulseReachedEnd()
	{			
		if(SpeakerVolume != nullptr)
		{
			UHazeAkComponent::HazePostEventFireForget(CurrentSpeakerOutEvent, SpeakerVolume.GetActorTransform());
			UHazeAkComponent::HazePostEventFireForget(OnSpeakerSongOutputEvent, SpeakerVolume.GetActorTransform());
		}
	}

	bool GetOutSpeakerEvent(const UAkAudioEvent& InSpeakerEvent, UAkAudioEvent& OutSpeakerEvent)
	{
		if(InSpeakerEvent == nullptr)
			return false;

		for(FPowerfulSongMicSpeakerEventPair& EventPair : PowerfulSongEventPairs)
		{
			if(EventPair.MicrophoneInPowerfulSongEvent == InSpeakerEvent)
			{
				OutSpeakerEvent = EventPair.SpeakerOutPowerfulSongEvent;
				return true;
			}
		}

		return false;
	}
}