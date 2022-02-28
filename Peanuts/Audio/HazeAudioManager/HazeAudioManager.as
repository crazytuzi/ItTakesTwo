import Peanuts.Audio.AudioStatics;
import Rice.Audio.UserInterfaceAudioDataAsset;
import Peanuts.Audio.LevelAudioStatesDataAsset;
import Peanuts.Audio.Music.LevelLoadingMusicTransitionDataAsset;

class UHazeAudioManager : UHazeAudioManagerSingleton
{
	UHazeAkComponent MusicHazeAkComponent;
	FHazeAudioEventInstance CurrentMusicEventInstance;
	private int32 CurrentMusicEventFadeOutTimeMs = 0;
	private EAkCurveInterpolation CurrentMusicEventFadeOutCurve;
	private bool bQueueMusicManagerLoadTransition = false;

	FName CurrentLevelState = n"";
	FName CurrentSubLevelState = n"";
	FName CurrentProgressionState = n"";

	FName CurrentMenuState = n"";
	FName CurrentGameplayState = n""; 

	FString LatestProgressPointLevel;
	FString CurrentInLevel;
	FString CurrentCheckpointName;

	FString CurrentLevelGroup;
	FString CurrentSubLevel;
	FString CurrentCheckpoint;

	int CurrentSpeakerType = -1;
	int CurrentChannelConfig = -1;
	int CurrentDynamicRange = -1;

	float CurrentMasterVolume = -1;
	float CurrentVoiceVolume = -1;
	float CurrentMusicVolume = -1;

	float PanningMultiplier = 1.f;
	int MenuWidgetMouseHoverSoundCount = 0;

	TArray<AHazeActor> TimeDilationRequestedActors;

	const int32 PlatformSampleRate;
	private bool bWasLoading = false;
	private bool bHasLoadedAmbientZones = true;
	private TSet<ULevel> LevelsWithAmbiences;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent EnterSlowMotionEvent;
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ExitSlowMotionEvent;
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent StopSlowMotionInstantEvent;
	UPROPERTY(Category = "AuxBuses")
	UAkAuxBus SlowMoReverbBus;
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent PauseMenuEnabledEvent;
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent PauseMenuDisabledEvent;

	UPROPERTY(Category = "DataAssets")
	UUserInterfaceAudioDataAsset UIDataAsset;
	UPROPERTY(Category = "DataAssets")
	ULevelLoadingMusicTransitionDataAsset LoadingMusicTransitionAsset;

	UPROPERTY(Category = "Debug")
	UHazeAudioAkObjectMappingDataAsset AkObjectMappings;

	UFUNCTION(BlueprintEvent)
	void BP_PlayEnterSlowMo() {}	

	UFUNCTION(BlueprintEvent)
	void BP_PlayExitSlowMo() {}	

	UFUNCTION(BlueprintEvent)
	void BP_StopSlowMo() {}

	UFUNCTION()
	bool RequestEnterSlowMo(const AHazeActor& Actor, const float& TimeDilationAmount)
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_Amount_Gameplay", TimeDilationAmount);

		if(TimeDilationRequestedActors.Num() == 0)
		{
			BP_PlayEnterSlowMo();		
			const float IsSlowmo = TimeDilationAmount < 1 ? 1 : 0;
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", IsSlowmo);	
		}

		TimeDilationRequestedActors.AddUnique(Actor);
		return TimeDilationRequestedActors.Num() == 1;
	}

	UFUNCTION()
	bool RequestExitSlowMo(const AHazeActor& Actor)
	{
		if(!TimeDilationRequestedActors.Contains(Actor))
			return false;

		TimeDilationRequestedActors.Remove(Actor);		
		if(TimeDilationRequestedActors.Num() == 0)
		{
			BP_PlayExitSlowMo();				
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_Amount_Gameplay", 1);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Globals_TimeDilation_IsSlowmo_Gameplay", 0);	
		}

		return TimeDilationRequestedActors.Num() == 0;
	}

	// STATES
	
	UFUNCTION(BlueprintCallable)
	bool HazeSetStates(ULevelAudioStatesDataAsset LevelStateAsset, FName ProgressionState)
	{
		// We set all these states through code instead.
		return true;
	}

	void ResetAllStates()
	{
		if(CurrentLevelState != HazeAudio::STATES::LevelStateGroupDefault)
		{
			AkGameplay::SetState(HazeAudio::STATES::LevelStateGroup, HazeAudio::STATES::LevelStateGroupDefault);
			CurrentLevelState = HazeAudio::STATES::LevelStateGroupDefault;
		}

		if(CurrentSubLevelState != HazeAudio::STATES::SubLevelStateGroupDefault)
		{
			AkGameplay::SetState(HazeAudio::STATES::SubLevelStateGroup, HazeAudio::STATES::SubLevelStateGroupDefault);
			CurrentSubLevelState = HazeAudio::STATES::SubLevelStateGroupDefault;
		}

		if(CurrentProgressionState != HazeAudio::STATES::ProgresstionStateGroupDefault)
		{
			AkGameplay::SetState(HazeAudio::STATES::ProgressionStateGroup, HazeAudio::STATES::ProgresstionStateGroupDefault);
			CurrentProgressionState = HazeAudio::STATES::ProgresstionStateGroupDefault;
		}

		if(CurrentGameplayState != HazeAudio::STATES::GameplayStateDefault)
		{
			AkGameplay::SetState(HazeAudio::STATES::GameplayStateGroup, HazeAudio::STATES::GameplayStateDefault);
			CurrentGameplayState = HazeAudio::STATES::GameplayStateDefault;
		}

		// We also need to reset all cached values related to states.
		CurrentLevelGroup = "";
		CurrentSubLevel = "";
		CurrentCheckpoint = "";
	}

	// !STATES

	// AUDIO SETTINGS

	// HELPER FUNCTIONS

	void InitSpeakerSettingMatrices() 
	{
		// Speakers
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::High);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::Medium);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::Medium);

		// TV
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::Medium);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::Medium);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::Low);

		// Headphones
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::High);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::High);
		SpeakerSettingsToDynamicRangeMatrix.Add(EHazeAudioDynamicRange::High);
		
		// NOTE: Fix below if ever needed.
		// TArray<EHazeAudioChannelSetup> SpeakerSettingsToChannelSetupMatrix = 
		// {
		// 	// Speakers
		// 	EHazeAudioChannelSetup::Stereo, EHazeAudioChannelSetup::Surround,
		// 	// TV
		// 	EHazeAudioChannelSetup::Stereo, EHazeAudioChannelSetup::Surround,
		// 	// Headphones
		// 	EHazeAudioChannelSetup::Stereo, EHazeAudioChannelSetup::Surround
		// };

		// TArray<EHazeAudioPanningRule> SpeakerSettingsToPanningRuleMatrix = 
		// {
		// 	// Speakers
		// 	EHazeAudioPanningRule::Speakers, EHazeAudioPanningRule::Speakers,
		// 	// TV
		// 	EHazeAudioPanningRule::Speakers, EHazeAudioPanningRule::Speakers,
		// 	// Headphones
		// 	EHazeAudioPanningRule::Headphones, EHazeAudioPanningRule::Headphones
		// };
	}

	TArray<EHazeAudioDynamicRange> SpeakerSettingsToDynamicRangeMatrix;

	EHazeAudioDynamicRange GetValidDynamicRangeBasedOnSpeakerType(EHazeAudioSpeakerType SpeakerType, EHazeAudioDynamicRange Current) 
	{
		int Index = int(SpeakerType * EHazeAudioSpeakerType::EHazeAudioSpeakerType_MAX) + int(Current);
		if (SpeakerSettingsToDynamicRangeMatrix.Num() == 0)
			InitSpeakerSettingMatrices();

		if (SpeakerSettingsToDynamicRangeMatrix.IsValidIndex(Index))
			return SpeakerSettingsToDynamicRangeMatrix[Index];

		return EHazeAudioDynamicRange::High;
	}

	// !HELPER FUNCTIONS

	UFUNCTION(BlueprintCallable)
	void SetAudioOutputSettings(EHazeAudioSpeakerType SpeakerType, EHazeAudioChannelSetup ChannelSetup, EHazeAudioDynamicRange DynamicRange)
	{		
		SetAudioSpeakerTypeSetting(SpeakerType);
		SetAudioChannelSetupSetting(ChannelSetup);
		SetAudioDynamicRangeSetting(DynamicRange);
	}

	UFUNCTION(BlueprintCallable)
	bool SetAudioSpeakerTypeSetting(EHazeAudioSpeakerType SpeakerType)
	{
		auto NewSpeakerType = HazeAudio::GetSpeakerTypeFromEnum(SpeakerType);
		if(NewSpeakerType != CurrentSpeakerType)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_SpeakerType", SpeakerType);
			EHazeAudioPanningRule Panning = 
				SpeakerType == EHazeAudioSpeakerType::Headphones ? 
				EHazeAudioPanningRule::Headphones : 
				EHazeAudioPanningRule::Speakers;

			Audio::SetPanningRule(Panning);
			CurrentSpeakerType = SpeakerType;

			PanningMultiplier = SpeakerType == EHazeAudioSpeakerType::Headphones ? 0.5f : 1.f;
			UHazeAkComponent::HazeSetGlobalRTPCValue(HazeAudio::RTPC::CodyBarksPanningRTPC, 1.f * PanningMultiplier);
			UHazeAkComponent::HazeSetGlobalRTPCValue(HazeAudio::RTPC::MayBarksPanningRTPC, -1.f * PanningMultiplier);

			TArray<UHazeAkComponent> AllHazeAkComps;
			UHazeAkComponent::GetAllHazeAkComponents(AllHazeAkComps);

			for(UHazeAkComponent& HazeAkComp : AllHazeAkComps)
			{
				float OutCurrPanningValue = 0.f;
				ERTPCValueType OutValueType;

				HazeAkComp.GetRTPCValue(ERTPCValueType::GameObject, OutCurrPanningValue, OutValueType, HazeAudio::RTPC::CharacterSpeakerPanningLR.Name);
				if(OutCurrPanningValue != 0.f)
				{
					AHazePlayerCharacter AssociatedPlayer = OutCurrPanningValue > 0 ? Game::GetCody() : Game::GetMay();
					HazeAudio::SetPlayerPanning(HazeAkComp, AssociatedPlayer);
				}
			}

			if (CurrentDynamicRange != -1) // Uninitialized
			{
				EHazeAudioDynamicRange ValidRange = GetValidDynamicRangeBasedOnSpeakerType(
					EHazeAudioSpeakerType(CurrentSpeakerType), EHazeAudioDynamicRange(CurrentDynamicRange));
				SetAudioDynamicRangeSetting(ValidRange);
			}
		}

		return NewSpeakerType == CurrentSpeakerType;
	}

	UFUNCTION(BlueprintCallable)
	bool SetAudioChannelSetupSetting(EHazeAudioChannelSetup ChannelSetup)
	{
		auto NewChannelConfig = HazeAudio::GetChannelConfigurationFromEnum(ChannelSetup);
		if(NewChannelConfig != CurrentChannelConfig)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_ChannelAmount", ChannelSetup);
			CurrentChannelConfig = ChannelSetup;
		}

		return NewChannelConfig == CurrentChannelConfig;
	}

	UFUNCTION(BlueprintCallable)
	bool SetAudioDynamicRangeSetting(EHazeAudioDynamicRange DynamicRange)
	{
		auto NewDynamicRange = HazeAudio::GetDynamicRangeFromEnum(DynamicRange);
		if(NewDynamicRange != CurrentDynamicRange)
		{
			EHazeAudioDynamicRange ValidValue = GetValidDynamicRangeBasedOnSpeakerType(EHazeAudioSpeakerType(CurrentSpeakerType), DynamicRange);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_DynamicRange", ValidValue);
			CurrentDynamicRange = ValidValue;
		}

		return NewDynamicRange == CurrentDynamicRange;
	}
	
	UFUNCTION(BlueprintCallable)
	void SetAudioMasterVolume(float Value)
	{
		if(Value != CurrentMasterVolume)
		{
			Audio::SetMasterVolume(Value);
			CurrentMasterVolume = Value;
		}
	}


	UFUNCTION(BlueprintCallable)
	void SetAudioVoiceVolume(float Value)
	{
		if(Value != CurrentVoiceVolume)
		{
			Audio::SetVoiceVolume(Value);
			CurrentVoiceVolume = Value;
		}
	}


	UFUNCTION(BlueprintCallable)
	void SetAudioMusicVolume(float Value)
	{
		if(Value != CurrentMusicVolume)
		{
			Audio::SetMusicVolume(Value);
			CurrentMusicVolume = Value;
		}
	}

	UFUNCTION(BlueprintCallable)
	float GetPanningMultiplierValue() property
	{
		return PanningMultiplier;
	}

	UFUNCTION(BlueprintCallable)
	void SetBootConfigurationSettings()
	{
		FAkChannelMask ChannelMask;
		int32 NumChannels = 0;
		Audio::GetSpeakerConfiguration(ChannelMask, NumChannels);
		if (NumChannels > 3)
		{
			SetAudioDynamicRangeSetting(EHazeAudioDynamicRange::High);
			SetAudioChannelSetupSetting(EHazeAudioChannelSetup::Surround);
			SetAudioSpeakerTypeSetting(EHazeAudioSpeakerType::Speakers);

			GameSettings::SetGameSettingsValue(n"AudioDynamicRange", "High");
			GameSettings::SetGameSettingsValue(n"AudioChannelSetup", "Surround");
			GameSettings::SetGameSettingsValue(n"AudioSpeakerType", "Speakers");
		}
		else{
			SetAudioDynamicRangeSetting(EHazeAudioDynamicRange::High);
			SetAudioChannelSetupSetting(EHazeAudioChannelSetup::Stereo);
			SetAudioSpeakerTypeSetting(EHazeAudioSpeakerType::Speakers);

			GameSettings::SetGameSettingsValue(n"AudioDynamicRange", "High");
			GameSettings::SetGameSettingsValue(n"AudioChannelSetup", "Stereo");
			GameSettings::SetGameSettingsValue(n"AudioSpeakerType", "Speakers");
		}
		
	}

	// !AUDIO SETTINGS

	// MUSIC
	UFUNCTION(BlueprintCallable)
	void GetMusicHazeAkComponent(UHazeAkComponent& InAkComp)
	{	
		if(MusicHazeAkComponent == nullptr)
		{
			MusicHazeAkComponent = UHazeAkComponent::Create(Game::WorldSettings, n"MusicHazeAkComponent");
			MusicHazeAkComponent.SetStopWhenOwnerDestroyed(false);
		}

		InAkComp = MusicHazeAkComponent;
	}

	UFUNCTION(BlueprintCallable)
	void GetActiveMusicEventInstance(FHazeAudioEventInstance& InEventInstance, int32& FadeOutMs, EAkCurveInterpolation& FadeOutCurve)
	{
		InEventInstance = CurrentMusicEventInstance;
		FadeOutMs = CurrentMusicEventFadeOutTimeMs;
		FadeOutCurve = CurrentMusicEventFadeOutCurve;
	}

	UFUNCTION(BlueprintCallable)
	void SetActiveMusicEventInstance(FHazeAudioEventInstance& ActiveMusicEventInstance, int32 FadeOutMs, EAkCurveInterpolation FadeOutCurve)
	{
		CurrentMusicEventInstance = ActiveMusicEventInstance;
		CurrentMusicEventFadeOutTimeMs = FadeOutMs;
		CurrentMusicEventFadeOutCurve = FadeOutCurve;
	}

	UFUNCTION(BlueprintOverride)
	void OnPauseMenuStateChange(bool bIsPaused, bool bInCutscene)
	{
		// We can't rely on the cutscene flag since some designer sequences
		// can contain active level audio, which might be stopped or removed
		// if ignored by the pause.
		//// if (!bInCutscene)
		{
			EHazeAudioPostEventType TypesToIgnore = 
				EHazeAudioPostEventType(
					EHazeAudioPostEventType::Ambience |
					EHazeAudioPostEventType::Foghorn |
					EHazeAudioPostEventType::UIEvent);
			if (bInCutscene)
				TypesToIgnore = EHazeAudioPostEventType(TypesToIgnore | EHazeAudioPostEventType::Sequence);

			// To pause or not to pause, that is the question!
			AkActionOnEventType TypeOfAction = bIsPaused ? AkActionOnEventType::Pause : AkActionOnEventType::Resume;
			// int EventsPaused = 0;

			for	(UHazeAkComponent Comp : RegisteredComponents)
			{
				if (Comp == nullptr )
					continue;
				
				for	(const FHazeAudioEventInstance& Instance: Comp.ActiveEventInstances)
				{
					if ((Instance.PostEventType & TypesToIgnore) != 0)
					{
						// Print("Type: " + Instance.PostEventType  + ", Ignored: " + Instance.EventName);
						continue;
					}

					// Print("Type: " + Instance.PostEventType  + ", Paused: " + Instance.EventName);
					AkGameplay::ExecuteActionOnPlayingID(TypeOfAction, Instance.PlayingID);
					// EventsPaused++;
				}
			}

			// Print("TypeOfAction: " + TypeOfAction);
			// Print("EventsPaused: " + EventsPaused);
		}

		// Pause music

		auto PauseEvent = bIsPaused ? PauseMenuEnabledEvent : PauseMenuDisabledEvent;
		if (PauseEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(PauseEvent, FTransform(), EHazeAudioPostEventType::Ambience, false, nullptr);
	}

	void TranslateToWwwiseFriendlyNames(FString& LevelName, FString& ProgressionName)
	{
		LevelName = CurrentInLevel.RightChop("/Game/Maps/".Len());
		int Index = LevelName.Find("/", SearchDir =  ESearchDir::FromEnd);
		LevelName = LevelName.LeftChop(LevelName.Len() - Index).Replace("/", "_");
		ProgressionName = CurrentCheckpointName.Replace(" ", "_").Replace("(", "_").Replace(")", "_").Replace("-", "_")
		.Replace("__", "_").Replace(".", "_").Replace("/", "_");

		if(ProgressionName.EndsWith("_"))
			ProgressionName.RemoveFromEnd("_");
	}

	void UpdateLevelProgressionState()
	{
		FString LevelName, ProgressionName;
		TranslateToWwwiseFriendlyNames(LevelName, ProgressionName);

		if (LevelName != CurrentSubLevel)
		{
			CurrentLevelGroup = LevelName.LeftChop(LevelName.Len() - LevelName.Find("_"));
			CurrentSubLevel = LevelName;
			const FString LevelState = "Stt_Level_" + CurrentLevelGroup;
			const FString SubLevelState = "Stt_SubLevel_" + LevelName;

			CurrentLevelState = FName(LevelState);
			CurrentSubLevelState = FName(SubLevelState);

			AkGameplay::SetState(HazeAudio::STATES::LevelStateGroup, CurrentLevelState);
			AkGameplay::SetState(HazeAudio::STATES::SubLevelStateGroup, CurrentSubLevelState);
		}

		if (CurrentCheckpoint != ProgressionName)
		{
			CurrentCheckpoint = ProgressionName;
			const FString Checkpoint = 
				"Stt_CheckPoints_" + LevelName + "_" + ProgressionName;

			CurrentProgressionState = FName(Checkpoint);
			AkGameplay::SetState(HazeAudio::STATES::CheckpointStateGroup, CurrentProgressionState);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		#if EDITOR
		{
			InitSpeakerSettingMatrices();
			
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_SpeakerType", 0);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_ChannelAmount", 1);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_SpeakerSettings_DynamicRange", 0);

			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Health_ReSpawnProg_Death_Filtering_Combined_Cody", 1);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Health_ReSpawnProg_Death_Filtering_Combined_May", 1);
		}
		#endif

		RegisterLevelLoadCallback();
		Audio::GetPlatformSampleRate(PlatformSampleRate);
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		Audio::SetMaxSimultaneousBanksLoading(0);
		UnregisterLevelLoadCallback();
	}

	UFUNCTION(BlueprintOverride)
	void LevelWasLoaded(ULevel Level, bool bLoadedWithAmbientZones)
	{
		if (bLoadedWithAmbientZones)
		{
			bHasLoadedAmbientZones = true;
			LevelsWithAmbiences.Add(Level);
		}
	}

	UFUNCTION(BlueprintOverride)
	void LevelWasUnloaded(ULevel Level)
	{
		if (Level == nullptr) 
			return;

		LevelsWithAmbiences.Remove(Level);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivatedProgressPoint(FString InLevel, FString CheckpointName)
	{
		LatestProgressPointLevel = InLevel;
		bQueueMusicManagerLoadTransition = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnProgressionPointUpdate(FString InLevel, FString CheckpointName, bool bFromSave)
	{
		CurrentInLevel = InLevel;
		CurrentCheckpointName = CheckpointName;
		UpdateLevelProgressionState();
	}

	bool CheckIfLevelsWithAmbientZonesAreActive()
	{
		#if Editor
		if (!Progress::HasActivatedAnyProgressPoint())
			return true;
		#endif

		for	(ULevel Level : LevelsWithAmbiences)
		{
			if (Level != nullptr && !Level.IsLevelActive())
			{
				return false;
			}
		}

		return true;
	}

	void QueueLoadingMusic()
	{
		// Only queue it up if a music actor doesn't exist.
		if (LoadingMusicTransitionAsset == nullptr)
			return;

		if (UHazeAkComponent::GetMusicManagerActor() != nullptr)
			return;

		FString LevelGroup = LatestProgressPointLevel.RightChop("/Game/Maps/".Len());
		// NOTE: We keep the whole name, LevelGroup/Level for specific transitions
		int Index = LevelGroup.Find("/", SearchDir =  ESearchDir::FromEnd);
		LevelGroup = LevelGroup.LeftChop(LevelGroup.Len() - Index).ToLower();

		FLevelMusicTransition MusicTransition;
		LoadingMusicTransitionAsset.GetMusicTransitionByLevelGroup(LevelGroup, MusicTransition);
		if (MusicTransition.MusicEvent == nullptr)
			return;

		UHazeAkComponent MusicAkComponent;
		GetMusicHazeAkComponent(MusicAkComponent);

		if (MusicAkComponent != nullptr)
		{
			FHazeAudioEventInstance Instance = MusicAkComponent.HazePostEvent(MusicTransition.MusicEvent, PostEventType = EHazeAudioPostEventType::Ambience);
			SetActiveMusicEventInstance(Instance, MusicTransition.FadeOutTimeMs, MusicTransition.FadeOutCurve);
		}
	}

	// Kill off all fireforgets which caller is now destroyed.
	// Will notify wwise authering as well.
	void AnalyzFireForgetOnLevelChange()
	{
		for	(UHazeAkComponent Comp : RegisteredComponents)
		{
			if (Comp != nullptr)
			{
				Comp.StopFireForgetIfContextObjectIsDestroyed();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const bool bIsLoading = Game::IsInLoadingScreen();
		if (bWasLoading != bIsLoading)
		{
			// Zero is infinite i.e no queue.
			int32 MaxBanksLoadingInGameplay = bIsLoading ? 0 : 16;
			Audio::SetMaxSimultaneousBanksLoading(MaxBanksLoadingInGameplay);
		}
		bWasLoading = bIsLoading;

		if (bHasLoadedAmbientZones && CheckIfLevelsWithAmbientZonesAreActive())
		{
			UpdateHazeComponentOverlaps();
			bHasLoadedAmbientZones = false;

			AnalyzFireForgetOnLevelChange();
		}

		if (bQueueMusicManagerLoadTransition)
		{
			// If still in loading, queue up the music event.
			if (Game::IsInLoadingScreen() &&
				CurrentMusicEventInstance.PlayingID != 0)
			{
				// We only use this to know if the music has ended playing...
				int OutPosition = -1;
				if (!UHazeAkComponent::GetSourcePlayPosition(CurrentMusicEventInstance.PlayingID, OutPosition, false))
				{
					QueueLoadingMusic();
					bQueueMusicManagerLoadTransition = false;
				}
			}
			else 
			{
				bQueueMusicManagerLoadTransition = false;
			}
		}
	}

	bool IsAmbientZonesLevelActive(AHazeAmbientZone AmbientZone)
	{
		if (!bHasLoadedAmbientZones)
			return true; // We're not in the middle of loading a level with ambientzones

		#if Editor
		if (!Progress::HasActivatedAnyProgressPoint())
			return true; // When starting from editor, nothing has been streamed yet and set as active.
		#endif

		return AmbientZone.Level.IsLevelActive();
	}

	bool IsHazeAkComponentsLevelActive(UHazeAkComponent HazeAkComp)
	{
		if (HazeAkComp.Owner == nullptr)
			return true; // We don't know, assume it to be.

		if (!bHasLoadedAmbientZones)
			return true; // We're not in the middle of loading a level with ambientzones

		#if Editor
		if (!Progress::HasActivatedAnyProgressPoint())
			return true; // When starting from editor, nothing has been streamed yet and set as active.
		#endif
		
		return HazeAkComp.Owner.Level.IsLevelActive();
	}

	// Force update ambient zones for all spawned HazeAkComps, will only update those flagged as in need of update.
	void UpdateHazeComponentOverlaps()
	{
		for	(UHazeAkComponent Comp : RegisteredComponents)
		{
			if (Comp != nullptr && Comp.bIsEnabled)
			{
				if (!IsHazeAkComponentsLevelActive(Comp))
					continue;

				// A AMBIENTZONE HAS BEEN ADDED
				// FORCE QUERY NO MATTER WHAT
				// This also let's the ambientzone manager know it should recalculate reverb.
				Comp.SetAudioFlags(EAudioHazeAkComponentFlag::QueuedForReverbProcessing);
				Comp.QueryAmbientZoneOverlap();
			}
		}
	}

	
	void OnReset(EComponentResetType ResetType)
	{
		#if EDITOR
		if (ResetType == EComponentResetType::PreRestart || ResetType == EComponentResetType::LevelChange)
		{
			// This is just for if the level sequence previewer has started/ended without resetting state.
			if (Game::GetMay() != nullptr && !Game::GetMay().bIsParticipatingInCutscene)
			{
				AkGameplay::SetState(HazeAudio::STATES::CutsceneStateGroup, HazeAudio::STATES::CutsceneStateGroupDefault);
				AkGameplay::SetState(HazeAudio::STATES::DesignerCutsceneStateGroup, HazeAudio::STATES::DesignerCutsceneStateGroupDefault);
			}
		}
		#endif
		
		if(ResetType == EComponentResetType::LevelChange)
		{
			ResetAllStates();
			UpdateLevelProgressionState();
		}
	}		

	/* Music Callbacks */

	UFUNCTION(BlueprintOverride)
	void HandleMusicCallbacks(EAkCallbackType CallbackType, UAkMusicSyncCallbackInfo CallbackInfo)
	{
		if(GetWorld() == nullptr || GetWorld().IsTearingDown())
			return;

		AHazeMusicManagerActor MusicManagerActor = CurrentMusicManager != nullptr ? CurrentMusicManager : UHazeAkComponent::GetMusicManagerActor();
		if(MusicManagerActor == nullptr)
			return;

		MusicManagerActor.HandleMusicCallbacks(ActiveMusicSubComps, CallbackType, CallbackInfo);
	}

	// MAIN MENU UI

	UFUNCTION(BlueprintCallable)
	void UI_OnSelectionChanged()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnChangedSelectionEvent, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnSelectionChanged_Mouse()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnChangedSelectionMouseOverEvent, FTransform(), EHazeAudioPostEventType::UIEvent);	
	}
	
	UFUNCTION(BlueprintCallable)
	void UI_OnSelectionChanged_Hover_Background_Mouse()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnChangedSelectionBackgroundMouseOverEvent, FTransform(), EHazeAudioPostEventType::UIEvent);	
	}


	UFUNCTION(BlueprintCallable)
	void UI_OnButtonDown()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSelectEvent, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnSelectionCancel()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnCancelEvent, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnSelectionConfirmed()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnConfirmEvent, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_SplashBackgroundFadeIn()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSplashScreenBackgroundFadeIn, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_SplashTextFadeIn()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSplashScreenTextFadeIn, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_SplashBackgroundFadeOut()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSplashScreenBackgroundFadeOut, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_SplashTextFadeOut()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSplashScreenTextFadeOut, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_SplashScreenConfirm()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnSplashScreenConfirm, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ReturnToSplash()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnReturnToSplashScreen, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ReturnToMenuRoot()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnReturnToMainMenuRoot, FTransform(), EHazeAudioPostEventType::UIEvent);
	}
	
	UFUNCTION(BlueprintCallable)
	void UI_PopupMessageOpen()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnPopupMessageOpen, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuOpen()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuOpen, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuTabSelect()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuTabSelect, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuRowSelect()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuRowSelect, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuSliderUpdate()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuSliderUpdate, FTransform(), EHazeAudioPostEventType::UIEvent);
	}
	
	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuRadioButtonUpdate()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuRadioButtonUpdate, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OptionsMenuClose()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnOptionsMenuClose, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_StartModeUpdated()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnStartModeSelection, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ChapterSelectUpdateLevel()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnChapterSelectUpdateLevel, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ChapterSelectUpdateProgressPoint()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnChapterSelectUpdateProgressPoint, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnPlayerJoin()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnPlayerJoin, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnPlayerLeave()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnPlayerLeave, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ProceedToCharacterSelect()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnProceedToCharacterSelect, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_ReturnToChapterSelect()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnReturnToChapterSelect, FTransform(), EHazeAudioPostEventType::UIEvent);
	}


	UFUNCTION(BlueprintCallable)
	void UI_PlayerOnMoveSelectionMay()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnMoveSelectionMay, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_PlayerOnRemoveSelectionMay()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnRemoveSelectionMay, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_PlayerOnMoveSelectionCody()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnMoveSelectionCody, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_PlayerOnRemoveSelectionCody()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnRemoveSelectionCody, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_PlayerCharacterSelectionConfirmMay()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnConfirmSelectionMay, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	
	UFUNCTION(BlueprintCallable)
	void UI_PlayerCharacterSelectionConfirmCody()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnConfirmSelectionCody, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_PlayerCharacterSelectionCancel()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnPlayerSelectedCharacterCancel, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION(BlueprintCallable)
	void UI_OnGameConfirmStarted()
	{
		UHazeAkComponent::HazePostEventFireForget(UIDataAsset.OnConfirmGameStarted, FTransform(), EHazeAudioPostEventType::UIEvent);
	}

	// ~MAIN MENU UI
}