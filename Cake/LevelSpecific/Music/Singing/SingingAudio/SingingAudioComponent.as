import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Peanuts.Foghorn.FoghornStatics;

class USingingAudioComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Powerful Song")
	UAkAudioEvent PowerfulSongBackstage;

	UPROPERTY(EditDefaultsOnly, Category = "Powerful Song")
	UAkAudioEvent PowerfulSongNightclub;

	UPROPERTY(EditDefaultsOnly, Category = "Powerful Song")
	UAkAudioEvent PowerfulSongClassic;

	UPROPERTY(EditDefaultsOnly, Category = "Powerful Song")
	UAkAudioEvent PowerfulSongConcertHall;
	
	UHazeAudioManager AudioManager;

	private bool bCanStop = true;
	private float ReleaseTime = 0;
	private float StopTime = 0.f;
	private float WantedReleaseTime = 0.f;

	private bool bPendingStop = false;
	private FHazeAudioEventInstance SongOfLifeReleaseEventInstance;
	bool bActivateOnFlying = false;
	bool bIsSinging = false;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AudioManager = GetAudioManager();
		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwner());
	}

	UFUNCTION()
	void StartSongOfLife()
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_VocalIsActive", 1.f, 100);
		bIsSinging = true;

		if(PlayerOwner.IsMay())
			PauseFoghornActor(PlayerOwner);
	}

	UFUNCTION()
	void StopSongOfLife()
	{
		if(bCanStop)
			StopSongOfLifeInternal();		
		else
		{
			bPendingStop = true;
			SetComponentTickEnabled(true);
		}
	}

	void StopSongOfLifeInternal(bool bAllowFadeOut = true)
	{
		const float StopTimeDiff = GetTimeSinceStopMarker();
		WantedReleaseTime = bAllowFadeOut ? FMath::Clamp(ReleaseTime - StopTimeDiff, 250, ReleaseTime) : 100.f;
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_ActiveDuration", 0.f, InterpolationTimeMS = WantedReleaseTime);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_VocalIsActive", 0.f, InterpolationTimeMS = WantedReleaseTime);
		bIsSinging = false;

		//Print("WantedReleaseTime: " + WantedReleaseTime, 1.f);

		if(PlayerOwner.IsMay())
			System::SetTimer(this, n"ResumeFoghornDelayed", WantedReleaseTime / 1000.f, false);
	}	

	UFUNCTION()
	void OnStopEnabled(float InStopTime, float InReleaseTime)
	{
		bCanStop = true;
		StopTime = (InStopTime / AudioManager.PlatformSampleRate) * 1000;
		ReleaseTime = InReleaseTime * 1000;
	}

	UFUNCTION()
	void OnStopDisabled()
	{
		bCanStop = false;
	}

	UFUNCTION()
	void ResumeFoghornDelayed()
	{
		if(!bIsSinging)
			ResumeFoghornActor(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Print("Current Release Time: " + WantedReleaseTime, 0.f);
		if(!bPendingStop)
			return;

		if(bCanStop)
		{
			StopSongOfLifeInternal();
			bPendingStop = false;
			SetComponentTickEnabled(false);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(bPendingStop)
		{
			StopSongOfLifeInternal(false);
			bPendingStop = false;
		}
			
	}

	float GetTimeSinceStopMarker()
	{
		int32 OutCurrPos = 0;
		if(UHazeAkComponent::GetSourcePlayPosition(AudioManager.CurrentMusicEventInstance.PlayingID, OutCurrPos))
		{
			if(OutCurrPos < StopTime)
				return 0.f;
				
			return OutCurrPos - StopTime;
		}

		return OutCurrPos;
	}
}