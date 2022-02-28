import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;

class AOldRadio : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent)	
	USceneComponent FrequencyPinComp;
	UPROPERTY(DefaultComponent, Attach = FrequencyPinComp)	
	UStaticMeshComponent FrequencyPin;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = false;

	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent StaticNoice;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ChannelOne;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ChannelTwo;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ChannelThree;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ChannelFour;
	FHazeAudioEventInstance SoundInstance;


	UPROPERTY()
	AValveTurnInteractionActor VolumeButton;
	float CurrentVolume = 75;
	UPROPERTY()
	AValveTurnInteractionActor FrequencyButton;
	
	FHazeAcceleratedFloat AcceleratedFloatRecentInput;
	FHazeAcceleratedFloat AcceleratedFloatFrequencyPinLocation;
	float CurrentFrequency = 30;
	int CurrentChannelPlaying = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FrequencyButton.SyncComponent.Value = CurrentFrequency;
		AcceleratedFloatRecentInput.Value = CurrentFrequency;
		AcceleratedFloatFrequencyPinLocation.Value = CurrentFrequency;
		VolumeButton.SyncComponent.Value = CurrentVolume;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintToScreen("FrequencyButton.SyncComponent.Value " + FrequencyButton.SyncComponent.Value);
		PrintToScreen("CurrentFrequency " + CurrentFrequency);
	//	PrintToScreen("bOldRadioActive " + bOldRadioActive);
	//	PrintToScreen("bRecentInput " + bRecentInput);
	//	PrintToScreen("AcceleratedFloatRecentInput.Value " + AcceleratedFloatRecentInput.Value);
	//	PrintToScreen("AutoDisableTimerTemp " + AutoDisableTimerTemp);
		PrintToScreen("CurrentVolume " + CurrentVolume);

		HazeAkComponent.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_OldRadio_Volume", CurrentVolume);

		AcceleratedFloatRecentInput.SpringTo(FrequencyButton.SyncComponent.Value + 0.1, 2, 1, DeltaSeconds);
		CurrentFrequency = FrequencyButton.SyncComponent.Value;
		AcceleratedFloatFrequencyPinLocation.SpringTo(CurrentFrequency, 400, 1, DeltaSeconds);
		FrequencyPin.SetRelativeLocation(FVector(AcceleratedFloatFrequencyPinLocation.Value * 4, 0, 0));


		CurrentVolume = VolumeButton.SyncComponent.Value;

		if(CurrentFrequency > 0 && CurrentFrequency <= 15)
		{
			ChangeChannelAudio(0);
		}
		if(CurrentFrequency > 15 && CurrentFrequency <= 30)
		{
			ChangeChannelAudio(1);
		}
		if(CurrentFrequency > 30 && CurrentFrequency <= 45)
		{
			ChangeChannelAudio(0);
		}
		if(CurrentFrequency > 45 && CurrentFrequency <= 60)
		{
			ChangeChannelAudio(2);
		}
		if(CurrentFrequency > 60 && CurrentFrequency <= 75)
		{
			ChangeChannelAudio(3);
		}
		if(CurrentFrequency > 75 && CurrentFrequency <= 85)
		{
			ChangeChannelAudio(0);
		}
		if(CurrentFrequency > 85 && CurrentFrequency <= 100)
		{
			ChangeChannelAudio(4);
		}
		if(CurrentFrequency > 100 && CurrentFrequency <= 103)
		{
			ChangeChannelAudio(0);
		}
	}

	UFUNCTION()
	void ChangeChannelAudio(int Channel)
	{
		if(Channel == 0)
		{
			if(CurrentChannelPlaying != Channel)
			{
				CurrentChannelPlaying = Channel;
				HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1000.f, bStopAllInstancesOfEvent = false);
				SoundInstance = HazeAkComponent.HazePostEvent(StaticNoice);
				//PrintToScreen("PlayingStatic", 1.5f);
			}
		}
		if(Channel == 1)
		{
			if(CurrentChannelPlaying != Channel)
			{
				CurrentChannelPlaying = Channel;
				HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1000.f, bStopAllInstancesOfEvent = false);
				SoundInstance = HazeAkComponent.HazePostEvent(ChannelOne);
				//PrintToScreen("PlayingChannelOne", 1.5f);
			}
		}
		if(Channel == 2)
		{
			if(CurrentChannelPlaying != Channel)
			{
				CurrentChannelPlaying = Channel;
				HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1000.f, bStopAllInstancesOfEvent = false);
				SoundInstance = HazeAkComponent.HazePostEvent(ChannelTwo);
				//PrintToScreen("PlayingChannelTwo", 1.5f);
			}
		}
		if(Channel == 3)
		{
			if(CurrentChannelPlaying != Channel)
			{
				CurrentChannelPlaying = Channel;
				HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1000.f, bStopAllInstancesOfEvent = false);
				SoundInstance = HazeAkComponent.HazePostEvent(ChannelThree);
				//PrintToScreen("PlayingChannelThree", 1.5f);
			}
		}
		if(Channel == 4)
		{
			if(CurrentChannelPlaying != Channel)
			{
				CurrentChannelPlaying = Channel;
				HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1000.f, bStopAllInstancesOfEvent = false);
				SoundInstance = HazeAkComponent.HazePostEvent(ChannelFour);
				//PrintToScreen("PlayingChannelFour", 1.5f);
			}
		}
	}

/*
	UFUNCTION(NetFunction)
	void AutoDisable()
	{
		//OldFrequcenyBeforeReset = CurrentFrequency - (100 * FullRotationsCompleted);
		//CurrentFrequency = 0;
		HazeAkComponent.HazeStopEvent(SoundInstance.PlayingID, 1.f, bStopAllInstancesOfEvent = false);
		bOldRadioActive = false;
	}
*/

	UFUNCTION()
	void ButtonPressed()
	{
	
	}
}

