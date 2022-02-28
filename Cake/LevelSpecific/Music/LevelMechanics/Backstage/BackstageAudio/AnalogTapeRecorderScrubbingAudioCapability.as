import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechKnobs;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstageAudio.MusicTechKnobsAudioComponent;
import Peanuts.Audio.AudioStatics;

class UAnalogTapeRecorderScrubbingAudioCapability : UHazeCapability
{	
	AMusicTechKnobs TechKnobs;

	UPROPERTY()
	UAkAudioEvent LeftRotatorForwardLoopEvent;
	
	UPROPERTY()
	UAkAudioEvent LeftRotatorForwardStartEvent;

	UPROPERTY()
	UAkAudioEvent LeftRotatorStopEvent;
	
	UPROPERTY()
	UAkAudioEvent LeftRotatorReverseLoopEvent;

	UPROPERTY()
	UAkAudioEvent LeftRotatorReverseStartEvent;
	
	UPROPERTY()
	UAkAudioEvent RightRotatorForwardLoopEvent;

	UPROPERTY()
	UAkAudioEvent RightRotatorForwardStartEvent;

	UPROPERTY()
	UAkAudioEvent RightRotatorStopEvent;
	
	UPROPERTY()
	UAkAudioEvent RightRotatorReverseLoopEvent;
		
	UPROPERTY()
	UAkAudioEvent RightRotatorReverseStartEvent;

	int32 BackstageMusicStateId;
	bool bPendingStartMusic = false;
	bool bShouldDeactivate = false;
	bool bHasFoundMusicState = false;
	bool bMusicScrubbingBlocked = false;
	bool bAllScrubbingBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TechKnobs = Cast<AMusicTechKnobs>(Owner);
		TechKnobs.RotationRateUpdate.AddUFunction(this, n"OnScrubbingUpdated");

		TechKnobs.TechKnobsAudioComp.LeftScrubData.DirectionRtpc = "Rtpc_AnalogTapeRecorder_Reel_Direction_L";
		TechKnobs.TechKnobsAudioComp.LeftScrubData.RotationRtpc = "Rtpc_AnalogTapeRecorder_Reel_Scrubbing_Speed_L";
		TechKnobs.TechKnobsAudioComp.LeftScrubData.MusicEvent = TechKnobs.TechKnobsAudioComp.LeftTracks;
		TechKnobs.TechKnobsAudioComp.LeftScrubData.DialRotateForwardLoopEvent = LeftRotatorForwardLoopEvent;
		TechKnobs.TechKnobsAudioComp.LeftScrubData.DialRotateReverseLoopEvent = LeftRotatorReverseLoopEvent;
		TechKnobs.TechKnobsAudioComp.LeftScrubData.DialRotateForwardStartEvent = LeftRotatorForwardStartEvent;
		TechKnobs.TechKnobsAudioComp.LeftScrubData.DialRotateReverseStartEvent = LeftRotatorReverseStartEvent;
		TechKnobs.TechKnobsAudioComp.LeftScrubData.DialRotatorStopEvent = LeftRotatorStopEvent;

		TechKnobs.TechKnobsAudioComp.RightScrubData.DirectionRtpc = "Rtpc_AnalogTapeRecorder_Reel_Direction_R";
		TechKnobs.TechKnobsAudioComp.RightScrubData.RotationRtpc = "Rtpc_AnalogTapeRecorder_Reel_Scrubbing_Speed_R";
		TechKnobs.TechKnobsAudioComp.RightScrubData.MusicEvent = TechKnobs.TechKnobsAudioComp.RightTracks;
		TechKnobs.TechKnobsAudioComp.RightScrubData.DialRotateForwardLoopEvent = RightRotatorForwardLoopEvent;
		TechKnobs.TechKnobsAudioComp.RightScrubData.DialRotateReverseLoopEvent = RightRotatorReverseLoopEvent;
		TechKnobs.TechKnobsAudioComp.RightScrubData.DialRotateForwardStartEvent = RightRotatorForwardStartEvent;
		TechKnobs.TechKnobsAudioComp.RightScrubData.DialRotateReverseStartEvent = RightRotatorReverseStartEvent;
		TechKnobs.TechKnobsAudioComp.RightScrubData.DialRotatorStopEvent = RightRotatorStopEvent;

		Audio::GetAkIdFromString("MStt_Music_Backstage_TechWall_Amb", BackstageMusicStateId);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TechKnobs.TechKnobsAudioComp.bStartAudioScrubbing || bShouldDeactivate)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bShouldDeactivate = false;
		bMusicScrubbingBlocked = false;
		bAllScrubbingBlocked = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TechKnobs.TechKnobsAudioComp.bStartAudioScrubbing || !bShouldDeactivate)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We're constantly checking the current state of the music system as we are now playing music outside of it. If the state has changed, we deactivate
		int32 MusicStateValue = 0;
		if(Audio::GetStateGroupsCurrentState("MStg_Music_Backstage", MusicStateValue) && bHasFoundMusicState)
		{
			if(MusicStateValue != BackstageMusicStateId)
			{
				bShouldDeactivate = true;
			}
		}

		// When we reach the EQ Room we no longer want to scrub the music
		if(ConsumeAction(n"AudioBlockMusicScrubbing") == EActionStateStatus::Active)
		{
			OnScrubbingUpdated(0.f, 0.f);
			bMusicScrubbingBlocked = true;			
		}

		if(ConsumeAction(n"AudioBlockScrubbing") == EActionStateStatus::Active)
		{
			InternalBlockAllScrubbing();
		}

		if(!bHasFoundMusicState)
		{
			Audio::GetStateGroupsCurrentState("MStg_Music_Backstage", MusicStateValue);
			bHasFoundMusicState = MusicStateValue == BackstageMusicStateId;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazeStopEvent(FadeOutTimeMs = 3000.f, CurveType = EAkCurveInterpolation::Exp3);
		TechKnobs.RotationRateUpdate.UnbindObject(this);
	}

	UFUNCTION()
	void OnScrubbingUpdated(float LeftRotation, float RightRotation)
	{
		if(LeftRotation != TechKnobs.TechKnobsAudioComp.LeftScrubData.LastRotationValue)
			UpdateScrubbingInternal(LeftRotation, TechKnobs.TechKnobsAudioComp.LeftScrubData);
		
		if(RightRotation != TechKnobs.TechKnobsAudioComp.RightScrubData.LastRotationValue)
			UpdateScrubbingInternal(RightRotation, TechKnobs.TechKnobsAudioComp.RightScrubData);
	}

	void UpdateScrubbingInternal(const float& NewRotation, FScrubbingSideData& ScrubData)
	{
		const float ReelDirection = FMath::Sign(NewRotation);
		if(!bMusicScrubbingBlocked)
		{
			const float NormalizedReelRotation = HazeAudio::NormalizeRTPC01(FMath::Abs(NewRotation), 0.f, 0.25f);
			TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.SetRTPCValue(ScrubData.DirectionRtpc, ReelDirection);
			TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.SetRTPCValue(ScrubData.RotationRtpc, NormalizedReelRotation);
		}

		if(bAllScrubbingBlocked)
			return;

		if(NewRotation == 0 && ScrubData.bIsPlaying)
		{
			OnStopScrubbing(ScrubData);
		}
		else if(ScrubData.LastRotationValue == 0 || ReelDirection != ScrubData.LastDirectionValue)
		{
			// We've started scrubbing this dial
			// First, get direction

			UAkAudioEvent DirectionLoopEvent;
			UAkAudioEvent DirectionStartEvent;

			if(ReelDirection > 0)
			{
				DirectionLoopEvent = ScrubData.DialRotateForwardLoopEvent;
				DirectionStartEvent = ScrubData.DialRotateForwardStartEvent;
			}
			else
			{
				DirectionLoopEvent = ScrubData.DialRotateReverseLoopEvent;
				DirectionStartEvent = ScrubData.DialRotateReverseStartEvent;
			}

			// Stop old direction-loop if its still playing
			if(TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.EventInstanceIsPlaying(ScrubData.CurrentDialRotatingEventInstance))
				TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazeStopEvent(ScrubData.CurrentDialRotatingEventInstance.PlayingID);

			if(!bMusicScrubbingBlocked)
				ScrubData.CurrentDialRotatingEventInstance = TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazePostEvent(DirectionLoopEvent);

			TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazePostEvent(DirectionStartEvent);
			ScrubData.bIsPlaying = true;			
		}

		ScrubData.LastRotationValue = NewRotation;
		ScrubData.LastDirectionValue = ReelDirection;
	}

	void OnStopScrubbing(FScrubbingSideData& ScrubData)
	{
		int32 PlayPos = 0;
		if(UHazeAkComponent::GetSourcePlayPosition(ScrubData.ReferenceInstance.PlayingID, PlayPos))
		{
			TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.SeekOnPlayingEvent(ScrubData.MusicEvent, ScrubData.TracksInstance.PlayingID, PlayPos, false);		}	
		
		if(!bMusicScrubbingBlocked)
			TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazePostEvent(ScrubData.DialRotatorStopEvent);

		TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.SetRTPCValue(ScrubData.DirectionRtpc, 0);
		TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.SetRTPCValue(ScrubData.RotationRtpc, 0);

		ScrubData.bIsPlaying = false;
	}		

	void InternalBlockAllScrubbing()
	{
		bAllScrubbingBlocked = true;
		TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazeStopEventInstance(TechKnobs.TechKnobsAudioComp.LeftScrubData.CurrentDialRotatingEventInstance);
		TechKnobs.TechKnobsAudioComp.MusicHazeAkComp.HazeStopEventInstance(TechKnobs.TechKnobsAudioComp.RightScrubData.CurrentDialRotatingEventInstance);
	}
}
