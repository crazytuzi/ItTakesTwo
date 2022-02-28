struct FScrubbingSideData
{
	float LastRotationValue = 0.f;
	float LastDirectionValue = 0.f;
	bool bIsPlaying = false;
	FString DirectionRtpc = "";
	FString RotationRtpc = "";
	FHazeAudioEventInstance TracksInstance;
	FHazeAudioEventInstance ReferenceInstance;
	UAkAudioEvent MusicEvent;

	UAkAudioEvent DialRotateForwardLoopEvent;
	UAkAudioEvent DialRotateForwardStartEvent;
	UAkAudioEvent DialRotateReverseLoopEvent;
	UAkAudioEvent DialRotateReverseStartEvent;
	UAkAudioEvent DialRotatorStopEvent;

	FHazeAudioEventInstance CurrentDialRotatingEventInstance;
}

class UMusicTechKnobsAudioComponent : UActorComponent
{
	UHazeAkComponent MusicHazeAkComp;
	FScrubbingSideData LeftScrubData;
	FScrubbingSideData RightScrubData;

	UPROPERTY(Category = "Tech Wall Music Event")
	UAkAudioEvent RightForwardReferenceTrack;

	UPROPERTY(Category = "Tech Wall Music Event")
	UAkAudioEvent LeftForwardReferenceTrack;

	UPROPERTY(Category = "Tech Wall Music Event")
	UAkAudioEvent RightTracks;

	UPROPERTY(Category = "Tech Wall Music Event")
	UAkAudioEvent LeftTracks;
	
	UPROPERTY(BlueprintReadWrite, Category = "Audio")
	bool bStartAudioScrubbing = false;

	private bool bIsPlayingMusic = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIsPlayingMusic = false;
		MusicHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintCallable)
	void StartTechWallMusic()
    {
		if(bIsPlayingMusic)
			return;

        RightScrubData.ReferenceInstance = MusicHazeAkComp.HazePostEvent(RightForwardReferenceTrack);
        LeftScrubData.ReferenceInstance = MusicHazeAkComp.HazePostEvent(LeftForwardReferenceTrack);
        RightScrubData.TracksInstance = MusicHazeAkComp.HazePostEvent(RightTracks);
        LeftScrubData.TracksInstance = MusicHazeAkComp.HazePostEvent(LeftTracks);

		bIsPlayingMusic = true;
    }
}