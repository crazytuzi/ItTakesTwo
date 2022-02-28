import Peanuts.Foghorn.FoghornDebugStatics;
import Peanuts.Foghorn.FoghornEventBase;
import Peanuts.Foghorn.FoghornVoiceLineHelpers;
import Peanuts.Foghorn.FoghornEfforts;
import Peanuts.Foghorn.FoghornSubtitles;

class UFoghornEventBark : UFoghornEventBase
{
	private UFoghornBarkDataAsset BarkAsset;
	private AActor Actor;

	private int EventID = 0;
	private int PlayingID = 0;
	private UHazeAkComponent HazeAkComponent = nullptr;

	private UFoghornSubtitles Subtitles = nullptr;

	private float PreDelayTimer = 0.0f;
	private int VoiceLineIndex = 0;

	private float OriginalPlaytime = 0.0f;
	private float PlaytimeLimit = 0.0f;
	private float Playtime = 0.0f;

	private bool bNeedsUpdatedPlaytime = false;
	private const float DEFERRED_UPDATE_PLAYTIME_DELAY = 0.1f;
	private float UpdatePlaytimeTimer = 0.f;

	private bool bNeedsUpdatedPlayRate = false;
	private const float DEFERRED_UPDATE_PLAYRATE = 0.1f;
	private float UpdatePlayRateTimer = 0.f;

	private uint CachedPositionAndPlayRateFrame;
	private float PlayRate = 1.0f;
	private float StartTime = 0.0f;

	private EFoghornEventState CurrentState;

	FoghornEfforManager EffortManager;

	UFoghornEventBark(FoghornEfforManager InEffortManager, UFoghornBarkDataAsset InBarkAsset, AActor InActor, EFoghornLaneName Lane, int InVoiceLineIndex, float InStartTime = 0.0f, bool SkipPreDelay = false, float ForcedPreDelay = 0.0f)
	{
		EffortManager = InEffortManager;
		BarkAsset = InBarkAsset;
		Actor = InActor;
		VoiceLineIndex = InVoiceLineIndex;
		Subtitles = UFoghornSubtitles(Lane);
		StartTime = InStartTime;

		if (!IsActorValid(Actor))
		{
			PrintError("Invalid Actor for Bark " + BarkAsset.Name + ", aboring play");
			CurrentState = EFoghornEventState::Finished;
			return;
		}

		if ((BarkAsset.PreDelay > 0.0f || ForcedPreDelay > 0.0f) && !SkipPreDelay )
		{
			CurrentState = EFoghornEventState::PreDelay;
			PreDelayTimer = FMath::Max(BarkAsset.PreDelay, ForcedPreDelay);
		}
	}

	void Initialize() override
	{
		if (PreDelayTimer <= 0.f)
			InternalPlay();
	}

	FFoghornResumeInfo Stop() override
	{
		float StopTime = Playtime;

		if (CurrentState == EFoghornEventState::Playing && IsActorValid(Actor))
		{
			EffortManager.ClearBlockedActor(Actor);
			float Fadeout = BarkAsset.Fadeout;

			if(BarkAsset.bMayHasMarkers)
			{
				int32 OutStopTime = -1;
				UHazeAkComponent::GetSourcePlayPosition(PlayingID, OutStopTime);
				
				StopTime = OutStopTime / 1000.f;
			}	

			HazeAkComponent.HazeStopEvent(PlayingID, Fadeout);
			HazeAkComponent.SetRTPCValue("Rtpc_VO_Efforts_DialogueIsPlaying", 0);
			HazeAkComponent = nullptr;
			StopFaceAnimation();
		}

		Subtitles.ClearSubtitles();

		FFoghornResumeInfo ResumeInfo;
		if (BarkAsset.ResumeAfterPause && (CurrentState == EFoghornEventState::PreDelay || CurrentState == EFoghornEventState::Playing) && IsActorValid(Actor))
		{
			ResumeInfo.BarkAsset = BarkAsset;
			ResumeInfo.Actor = Actor;
			ResumeInfo.ActiveActor = GetActiveActor();
			ResumeInfo.VoiceLineIndex = VoiceLineIndex;
			ResumeInfo.SkipResumeTransitions = BarkAsset.SkipResumeTransitions;
			ResumeInfo.Playime = StopTime;
		}

		CurrentState = EFoghornEventState::Finished;

		return ResumeInfo;
	}

	void PauseAkEvent() override
	{
		if (CurrentState == EFoghornEventState::Playing)
		{
			AkGameplay::ExecuteActionOnPlayingID(AkActionOnEventType::Pause, PlayingID);
		}
	}

	void ResumeAkEvent() override
	{
		if (CurrentState == EFoghornEventState::Playing)
		{
			AkGameplay::ExecuteActionOnPlayingID(AkActionOnEventType::Resume, PlayingID);
		}
	}

	bool Tick(float DeltaTime) override
	{
		if (CurrentState == EFoghornEventState::Finished)
		{
			Subtitles.ClearSubtitles();
			return true;
		}
		else if (CurrentState == EFoghornEventState::PreDelay)
		{
			PreDelayTimer -= DeltaTime;
			if (PreDelayTimer <= 0)
			{
				InternalPlay();
			}
			return false;
		}
		else if(CurrentState == EFoghornEventState::Playing)
		{
			if (!IsActorValid(Actor))
			{
				#if !RELEASE
					FoghornDebugLog("Foghorn Bark actor destroyed, stopping bark");
				#endif
				Subtitles.ClearSubtitles();
				CurrentState = EFoghornEventState::Finished;
				return true;
			}

			Playtime += DeltaTime;

			if(bNeedsUpdatedPlaytime)
				DeferredUpdatePlayTime(DeltaTime);

			bool TimesUp = false;
			if (PlaytimeLimit > 0.0f)
			{
				if(bNeedsUpdatedPlayRate)
					DeferredUpdatePlayRate(DeltaTime);
				TimesUp = Playtime > PlaytimeLimit;
			}

			Subtitles.Tick(Playtime);

			#if !RELEASE
				if (TimesUp)
					FoghornDebugLog("Foghorn Bark stopped early from PlaytimeLimit");
			#endif

			if (!HazeAkComponent.HazeIsEventActive(EventID) || TimesUp)
			{
				StopFaceAnimation();
				HazeAkComponent.SetRTPCValue("Rtpc_VO_Efforts_DialogueIsPlaying", 0);
				EffortManager.ClearBlockedActor(Actor);
				CurrentState = EFoghornEventState::Finished;
				HazeAkComponent = nullptr;

				Subtitles.ClearSubtitles();

				return true;
			}
			return false;
		}

		return false;
	}

	int GetPriority() override
	{
		return BarkAsset.Priority;
	}

	AActor GetActiveActor() override
	{
		return Actor;
	}

	#if !RELEASE
	FFoghornEventDebugInfo GetDebugInfo() override
	{
		FFoghornEventDebugInfo Info;
		Info.Asset = BarkAsset.Name;
		Info.Type = "Bark";
		Info.Actor = HazeAkComponent != nullptr ? HazeAkComponent.GetOwner() : nullptr;
		Info.Priority = BarkAsset.Priority;
		Info.PreDelayTimer = PreDelayTimer;

		return Info;
	}
	#endif

	private void StopFaceAnimation()
	{
		if (!BarkAsset.VoiceLines.IsValidIndex(VoiceLineIndex))
			return;

		const FFoghornVoiceLine& VoiceLine = BarkAsset.VoiceLines[VoiceLineIndex];
		if (VoiceLine.AnimationSequence != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(Actor);
			HazeActor.StopFaceAnimation(VoiceLine.AnimationSequence);
		}
	}

	void CacheGetSourcePlayPositionAndPlayRate(bool bUpdatePlayTime)
	{
		uint CurrentFrame = Time::GetFrameNumber();
		if (CachedPositionAndPlayRateFrame == CurrentFrame)
			return;
		CachedPositionAndPlayRateFrame = CurrentFrame;

		int32 NewStartTime = -1;
		float NewPlayRate = 0;
		if (UHazeAkComponent::GetSourcePlayPositionAndPlayRate(PlayingID, NewStartTime, NewPlayRate))
		{
			// Don't update play time always with playrate, seems to cause an to early out.
			if (bUpdatePlayTime)
			{
				Playtime = NewStartTime / 1000.f;
			}

			if (!FMath::IsNearlyEqual(PlayRate, NewPlayRate, 0.001f) && NewPlayRate > 0.01f)
			{
				PlayRate = NewPlayRate;
				#if !RELEASE
					FoghornDebugLog("New PlayRate in bark " + PlayRate);
				#endif

				if (PlaytimeLimit > 0)
				{
					float NewPlaytimeLimit = OriginalPlaytime / PlayRate;
					PlaytimeLimit = NewPlaytimeLimit - (BarkAsset.OverlapOffset / PlayRate);
					#if !RELEASE
						FoghornDebugLog("New PlaytimeLimit in bark " + PlaytimeLimit);
					#endif
				}

				if (BarkAsset.VoiceLines.IsValidIndex(VoiceLineIndex))
				{
					const FFoghornVoiceLine& VoiceLine = BarkAsset.VoiceLines[VoiceLineIndex];
					if (VoiceLine.AnimationSequence != nullptr)
					{
						auto HazeActor = Cast<AHazeActor>(Actor);
						HazeActor.SetFaceAnimationPlayRate(VoiceLine.AnimationSequence, PlayRate);
					}
				}
			}
		}
	}
	
	UFUNCTION()
	void DeferredUpdatePlayTime(float DeltaTime)
	{
		if(!bNeedsUpdatedPlaytime)
			return;

		if(UpdatePlaytimeTimer < DEFERRED_UPDATE_PLAYTIME_DELAY)
		{
			UpdatePlaytimeTimer += DeltaTime;
			return;
		}
		
		bNeedsUpdatedPlaytime = false;
		UpdatePlaytimeTimer = 0.f;

		CacheGetSourcePlayPositionAndPlayRate(true);
	}

	void DeferredUpdatePlayRate(float DeltaTime)
	{
		if(!bNeedsUpdatedPlayRate)
			return;

		if(UpdatePlayRateTimer < DEFERRED_UPDATE_PLAYRATE)
		{
			UpdatePlayRateTimer += DeltaTime;
			return;
		}
		
		UpdatePlayRateTimer = 0.f;
		CacheGetSourcePlayPositionAndPlayRate(false);
	}

	private void InternalPlay()
	{
		if (!IsActorValid(Actor))
		{
			PrintError("Invalid Actor for Bark " + BarkAsset.Name + ", aboring play");
			CurrentState = EFoghornEventState::Finished;
			return;
		}

		FFoghornVoiceLine VoiceLine = BarkAsset.VoiceLines[VoiceLineIndex];

		EffortManager.BlockActor(Actor);
		HazeAkComponent = UHazeAkComponent::GetOrCreate(Actor);
		FHazeAudioEventInstance EventInstance = HazeAkComponent.HazePostEvent(VoiceLine.AudioEvent, "", EHazeAudioPostEventType::Foghorn);
		#if !RELEASE
		if (EventInstance.PlayingID == 0)
			FoghornDebugLog("Failed to post bark event on HazeAkComponent " + VoiceLine.AudioEvent.Name);
		#endif
		EventID = EventInstance.EventID;
		PlayingID = EventInstance.PlayingID;

		Playtime = 0.0f;
		PlaytimeLimit = BarkAsset.OverlapOffset > 0 ? VoiceLine.AudioEvent.HazeMaximumDuration - BarkAsset.OverlapOffset : VoiceLine.AudioEvent.HazeMaximumDuration;
		OriginalPlaytime = VoiceLine.AudioEvent.HazeMaximumDuration;
		bNeedsUpdatedPlayRate = PlaytimeLimit > 0;

		if (BarkAsset.bMayHasMarkers && StartTime > 0.0f && EventInstance.PlayingID != 0)
		{
			auto Player = Cast<AHazePlayerCharacter>(Actor);
			if(Player != nullptr && Player.IsMay())
			{
				int Res = HazeAkComponent.SeekOnPlayingEvent(VoiceLine.AudioEvent, PlayingID, StartTime * 1000, false, false, false, true);
				#if !RELEASE
					FoghornDebugLog("SeekOnPlayingEvent " + VoiceLine.AudioEvent.Name + " " + StartTime + " " + Res);
				#endif
				Playtime = StartTime;

				bNeedsUpdatedPlaytime = true;
			}
			StartTime = 0.0f;
		}

		HazeAkComponent.SetRTPCValue("Rtpc_VO_Efforts_DialogueIsPlaying", 1);

		#if !RELEASE
		if (PlaytimeLimit > 0.0f)
			FoghornDebugLog("PlaytimeLimit set for Bark to " + PlaytimeLimit);
		#endif

		if (VoiceLine.AnimationSequence != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(Actor);
			HazeActor.PlayFaceAnimation(FHazeAnimationDelegate(), VoiceLine.AnimationSequence, EHazeExtractCurveMethod::ExtractCurve_Additive, Priority = VoiceLine.AnimPriority);
		}

		if (VoiceLine.SubtitleAsset != nullptr)
		{
			Subtitles.DisplayAssetSubtitle(VoiceLine.SubtitleAsset, Actor);
		}
		else if (!VoiceLine.SubtitleSourceText.IsEmptyOrWhitespace())
		{
			Subtitles.DisplayTextSubtitle(VoiceLine.SubtitleSourceText, Actor);
		}

		CurrentState = EFoghornEventState::Playing;
	}

	void OnReplacedInLane()
	{
		Subtitles.ClearSubtitles();
	}
}