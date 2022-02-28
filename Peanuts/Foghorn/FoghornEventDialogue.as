import Peanuts.Foghorn.FoghornDebugStatics;
import Peanuts.Foghorn.FoghornEventBase;
import Peanuts.Foghorn.FoghornVoiceLineHelpers;
import Peanuts.Foghorn.FoghornEfforts;
import Peanuts.Foghorn.FoghornSubtitles;

AActor FoghornEventDialogueGetActorForVoiceLine(const FFoghornDialogueVoiceLine& VoiceLine, const FFoghornMultiActors& ExtraActors)
{
	switch(VoiceLine.Character)
	{
		case EFoghornActor::Cody:
			return Game::GetCody();
		case EFoghornActor::May:
			return Game::GetMay();
		case EFoghornActor::Manual:
			return ExtraActors.Actor1;
		case EFoghornActor::Manual2:
			return ExtraActors.Actor2;
		case EFoghornActor::Manual3:
			return ExtraActors.Actor3;
		case EFoghornActor::Manual4:
			return ExtraActors.Actor4;
	}
	return nullptr;
}

class UFoghornEventDialogue : UFoghornEventBase
{
	private UFoghornDialogueDataAsset DialogueAsset;
	private FFoghornMultiActors ExtraActors;

	private int EventID = 0;
	private int PlayingID = 0;
	private UHazeAkComponent HazeAkComponent = nullptr;
	private AActor Actor = nullptr;

	private float PreDelayTimer = 0.0f;
	private int VoiceLineIndex;

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

	private UFoghornSubtitles Subtitles = nullptr;

	private EFoghornEventState CurrentState;

	private FoghornEfforManager EffortManager;

	UFoghornEventDialogue(FoghornEfforManager InEffortManager, UFoghornDialogueDataAsset InDialogueAsset, const FFoghornMultiActors& InActors, int StartIndex, EFoghornLaneName Lane, float InStartTime = 0.0f, bool SkipPreDelay = false, float ForcedPreDelay = 0.0f)
	{
		EffortManager = InEffortManager;
		DialogueAsset = InDialogueAsset;
		ExtraActors = InActors;

		Subtitles = UFoghornSubtitles(Lane);
		VoiceLineIndex = FMath::Max(StartIndex, 0);
		StartTime = InStartTime;

		if ((DialogueAsset.PreDelay > 0.0f || ForcedPreDelay > 0.0f) && !SkipPreDelay)
		{
			CurrentState = EFoghornEventState::PreDelay;
			PreDelayTimer = FMath::Max(DialogueAsset.PreDelay, ForcedPreDelay);

			const FFoghornDialogueVoiceLine& VoiceLine = DialogueAsset.VoiceLines[VoiceLineIndex];
			Actor = FoghornEventDialogueGetActorForVoiceLine(VoiceLine, ExtraActors);
		}
	}

	void Initialize() override
	{
		if (PreDelayTimer <= 0.f)
			PlayVoiceLine(VoiceLineIndex);
	}

	FFoghornResumeInfo Stop() override
	{
		float StopTime = Playtime;
		
		if (CurrentState == EFoghornEventState::Playing && IsActorValid(Actor))
		{
			EffortManager.ClearBlockedActor(Actor);
			float Fadeout = DialogueAsset.Fadeout;

			if(DialogueAsset.bMayHasMarkers)
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
		if (DialogueAsset.ResumeAfterPause && (CurrentState == EFoghornEventState::PreDelay || CurrentState == EFoghornEventState::Playing) && IsActorValid(Actor))
		{
			ResumeInfo.DialogueAsset = DialogueAsset;
			ResumeInfo.Actors = ExtraActors;
			ResumeInfo.ActiveActor = GetActiveActor();
			ResumeInfo.VoiceLineIndex = VoiceLineIndex;
			ResumeInfo.SkipResumeTransitions = DialogueAsset.SkipResumeTransitions;
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
			return true;
		}
		else if (CurrentState == EFoghornEventState::PreDelay)
		{
			PreDelayTimer -= DeltaTime;
			if (PreDelayTimer <= 0)
			{
				PlayVoiceLine(VoiceLineIndex);
			}
			return false;
		}
		else if(CurrentState == EFoghornEventState::Playing)
		{
			if (!IsActorValid(Actor))
			{
				#if !RELEASE
					FoghornDebugLog("Foghorn Dialogue actor destroyed, stopping dialogue");
				#endif
				CurrentState = EFoghornEventState::Finished;
				Subtitles.ClearSubtitles();
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
					FoghornDebugLog("Foghorn Dialogue stopped early from PlaytimeLimit");
			#endif

			if (!HazeAkComponent.HazeIsEventActive(EventID) || TimesUp)
			{
				HazeAkComponent.SetRTPCValue("Rtpc_VO_Efforts_DialogueIsPlaying", 0);
				StopFaceAnimation();

				EffortManager.ClearBlockedActor(Actor);
				VoiceLineIndex++;
				if (VoiceLineIndex < DialogueAsset.VoiceLines.Num())
				{
					PlayVoiceLine(VoiceLineIndex);
				}
				else
				{
					Subtitles.ClearSubtitles();
					CurrentState = EFoghornEventState::Finished;
					HazeAkComponent = nullptr;
					return true;
				}
			}
			return false;
		}

		return false;
	}

	int GetPriority() override
	{
		return DialogueAsset.Priority;
	}

	AActor GetActiveActor() override
	{
		return Actor;
	}

	#if !RELEASE
	FFoghornEventDebugInfo GetDebugInfo() override
	{
		FFoghornEventDebugInfo Info;
		Info.Asset = DialogueAsset.GetName() + " " + (VoiceLineIndex) + "/" + DialogueAsset.VoiceLines.Num(); ;
		Info.Type = "Dialogue";
		Info.Actor = Actor;
		Info.Priority = DialogueAsset.Priority;
		Info.PreDelayTimer = PreDelayTimer;
		return Info;
	}
	#endif

	private void PlayVoiceLine(int NextVoiceLineIndex)
	{
		const FFoghornDialogueVoiceLine& VoiceLine = DialogueAsset.VoiceLines[NextVoiceLineIndex];
		Actor = FoghornEventDialogueGetActorForVoiceLine(VoiceLine, ExtraActors);

		if (!IsActorValid(Actor))
		{
			PrintError("Could not find valid actor for Dialogue " + DialogueAsset.Name + ", aboring play");
			CurrentState = EFoghornEventState::Finished;
			return;
		}

		EffortManager.BlockActor(Actor);
		HazeAkComponent = UHazeAkComponent::GetOrCreate(Actor);
		FHazeAudioEventInstance EventInstance = HazeAkComponent.HazePostEvent(VoiceLine.AudioEvent,"", EHazeAudioPostEventType::Foghorn);
		#if !RELEASE
		if (EventInstance.PlayingID == 0)
			FoghornDebugLog("Failed to post dialogue event on HazeAkComponent " + VoiceLine.AudioEvent.Name);
		#endif
		EventID = EventInstance.EventID;
		PlayingID = EventInstance.PlayingID;

		Playtime = 0.0f;
		PlaytimeLimit = DialogueAsset.OverlapOffset > 0.0f ? VoiceLine.AudioEvent.HazeMaximumDuration - DialogueAsset.OverlapOffset : 0.0f;
		OriginalPlaytime = VoiceLine.AudioEvent.HazeMaximumDuration;
		bNeedsUpdatedPlayRate = PlaytimeLimit > 0;

		if (DialogueAsset.bMayHasMarkers && StartTime > 0.0f && EventInstance.PlayingID != 0)
		{
			auto Player = Cast<AHazePlayerCharacter>(Actor);
			if(Player != nullptr && Player.IsMay())
			{
				int Res = HazeAkComponent.SeekOnPlayingEvent(VoiceLine.AudioEvent, PlayingID, StartTime * 1000, false, false, false, true);
				#if !RELEASE
					FoghornDebugLog("SeekOnPlayingEvent " + VoiceLine.AudioEvent.Name + " " + StartTime + " " + Res);
				#endif

				bNeedsUpdatedPlaytime = true;
			}
			StartTime = 0.0f;
		}

		HazeAkComponent.SetRTPCValue("Rtpc_VO_Efforts_DialogueIsPlaying", 1);

		#if !RELEASE
		if (PlaytimeLimit > 0.0f)
			FoghornDebugLog("PlaytimeLimit set for Dialogue to " + PlaytimeLimit);
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
		else if(NextVoiceLineIndex > 0)
		{
			Subtitles.ClearSubtitles();
		}

		CurrentState = EFoghornEventState::Playing;
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
					FoghornDebugLog("New PlayRate in dialogue " + PlayRate);
				#endif

				if (PlaytimeLimit > 0)
				{
					float NewPlaytimeLimit =  OriginalPlaytime / PlayRate;
					PlaytimeLimit = NewPlaytimeLimit - (DialogueAsset.OverlapOffset / PlayRate);
					#if !RELEASE
						FoghornDebugLog("New PlaytimeLimit in dialogue " + PlaytimeLimit);
					#endif
				}

				if (DialogueAsset.VoiceLines.IsValidIndex(VoiceLineIndex))
				{
					const FFoghornDialogueVoiceLine& VoiceLine = DialogueAsset.VoiceLines[VoiceLineIndex];
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

	private void StopFaceAnimation()
	{
		if (!DialogueAsset.VoiceLines.IsValidIndex(VoiceLineIndex))
			return;

		const FFoghornDialogueVoiceLine& VoiceLine = DialogueAsset.VoiceLines[VoiceLineIndex];
		if (VoiceLine.AnimationSequence != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(Actor);
			HazeActor.StopFaceAnimation(VoiceLine.AnimationSequence);
		}
	}

	void OnReplacedInLane()
	{
		Subtitles.ClearSubtitles();
	}
}
