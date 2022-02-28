#if TEST
import Vino.PlayerHealth.PlayerGameOverAudioCapability;
import Vino.PlayerHealth.PlayerDeathFadeToBlackAudioCapability;
import Vino.PlayerHealth.PlayerHealthAudioCapability;
import Vino.PlayerHealth.PlayerRespawnAudioCapability;

import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Audio.Footsteps.FootstepStatics;

import Peanuts.Audio.Reflection.ReflectionTraceComponent;
import Peanuts.Audio.AudioStatics;

import Cake.DebugMenus.Audio.AudioDebugMenu;
import Cake.DebugMenus.Audio.AudioDebugStatics;

UFUNCTION(NotBlueprintCallable)
UAudioDebugManager GetAudioDebugManager()
{	
	return Cast<UAudioDebugManager>(Game::GetSingleton(UAudioDebugManager::StaticClass()));	 
}

UFUNCTION(NotBlueprintCallable)
void RegisterDebugMenu(UAudioDebugMenu AudioDebugMenu)
{
	auto DebugManager = GetAudioDebugManager();
	DebugManager.Register(AudioDebugMenu);
}

UFUNCTION(NotBlueprintCallable)
void UnregisterDebugMenu(UAudioDebugMenu AudioDebugMenu)
{
	auto DebugManager = GetAudioDebugManager();
	DebugManager.Unregister(AudioDebugMenu);
}

UFUNCTION(NotBlueprintCallable)
void SetConstantOutput(EAudioDebugMode DebugMode, FString Key, FString Output, FLinearColor Color, bool bIsMay) 
{
	GetAudioDebugManager().SetConstantOutput(DebugMode, Key, Output, Color, bIsMay);
}

// This includes selected tab in audio debug menu
UFUNCTION(NotBlueprintCallable)
bool IsDebugEnabled(EAudioDebugMode DebugMode) 
{
	auto Instance = GetAudioDebugManager();
	return Instance != nullptr && Instance.IsDebugEnabled(DebugMode, true);
}

// Some data is hard to reach, but trying to keep all data gathering in this manager.
UFUNCTION(NotBlueprintCallable)
void SetFootstepDebugData(FFootstepTrace Trace, FAudioPhysMaterial PhysMaterial, bool bIsMay)
{
	GetAudioDebugManager().SetFootstepDebugData(Trace, PhysMaterial, bIsMay);
}

UFUNCTION(NotBlueprintCallable)
void SetDelayDebugData(
		FReflectionTraceData& TraceData, 
		FHitResult& TraceResult,
		UPhysicalMaterialAudio AudioPhysMat,
		AAmbientZone PlayerOwnerPrioZone, 
		int Index,
		bool bIsMay)
{
	GetAudioDebugManager().SetDelayDebugData(TraceData, TraceResult, AudioPhysMat, PlayerOwnerPrioZone, Index, bIsMay);
}

struct FAudioDebugOutput
{
	EAudioDebugMode DebugMode;
	FString Output;
	FLinearColor Color;
	bool bIsMay = false;
};

class UAudioDebugManager : UHazeSingleton
{
	private TArray<FAudioDebugOutput> QueuedOutput;
	private TMap<FString, FAudioDebugOutput> ConstantOutput;

	// We only write to one of the menu viewports
	TSet<UAudioDebugMenu> AudioDebugMenus;

	//Cached Data
	FCharacterDebugData MayCharacterDebug = FCharacterDebugData();
	FCharacterDebugData CodyCharacterDebug = FCharacterDebugData();
	TArray<FDelayDebugData> MayDelayDebug;
	TArray<FDelayDebugData> CodyDelayDebug;

	bool bProfiling = false;
	FAudioProfilingResourceMonitorData ProfilingData;
	// ShortId's are based on hashing of names, and the master bus should never change it name.
	uint MasterBusId = 3803692087;
	TSet<FString> ReportInLevels;

	bool bInIdleMode = true;

	void QueueOutput(EAudioDebugMode DebugMode, FString Output, FLinearColor Color, bool bIsMay) 
	{
		FAudioDebugOutput NewOutput;
		NewOutput.DebugMode = DebugMode;
		NewOutput.Output = Output;
		NewOutput.Color = Color;
		NewOutput.bIsMay = bIsMay;

		QueuedOutput.Add(NewOutput);
	}

	void SetConstantOutput(EAudioDebugMode DebugMode, FString Key, FString Output, FLinearColor Color, bool bIsMay) 
	{
		FAudioDebugOutput NewOutput;
		NewOutput.DebugMode = DebugMode;
		NewOutput.Output = Output;
		NewOutput.Color = Color;
		NewOutput.bIsMay = bIsMay;

		ConstantOutput.FindOrAdd(Key) = NewOutput;
	}

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown() 
	{
		if (bProfiling)
		{
			Audio::UnregisterResourceMonitoring();
			Audio::UnregisterBusMetering(MasterBusId);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// We first wait for the user to activate any debug info
		if(bInIdleMode)
			bInIdleMode = !IsAnyMenuActive();

		if(!bInIdleMode)
		{
			UpdateDelay();
			UpdateGeneral();
			UpdateActiveSounds();
			UpdateCharacters();
			UpdateMusic();
			UpdateCutscenes();
			UpdateAmbiences();
			UpdateRtpcs();
			UpdateProfiler();
			UpdateLoadedBanks();

			PrintConstantOutput();
		}
	}

	bool IsAnyMenuActive() const
	{
		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			if (AudioDebugMenu.IsAnyDebugActive())
				return true;
		}

		return false;
	}

	void PrintConstantOutput()
	{
		if (AudioDebugMenus.Num() == 0 || ConstantOutput.Num() == 0)
			return;

		bool ShouldPrintToViewport = false;
		bool HasSelectedOutput = false;
		FString MayText = "<Red> MAY DEBUG </> \n";
		FString CodyText= "<Red> CODY DEBUG </> \n";

		FString SelectedMayOutput =  "<Red> MAY DEBUG </> \n";
		FString SelectedCodyText= "<Red> CODY DEBUG </> \n";

		for(auto KeyValuePair : ConstantOutput)
		{
			const auto Value = KeyValuePair.Value;

			if (IsModeSelected(Value.DebugMode))
			{
				HasSelectedOutput = true;
				if (Value.bIsMay)
					SelectedMayOutput += Value.Output;
				else	
					SelectedCodyText += Value.Output;
			}
			
			UAudioDebugMenuButton Button;
			if (!HazeAudio::IsDebugEnabled(Value.DebugMode) &&
				!GetActiveButton(Value.DebugMode, Button))
			{
				continue;
			}

			ShouldPrintToViewport = true;
			if (Value.bIsMay)
				MayText += Value.Output;
			else
				CodyText += Value.Output;
		}

		ActivateViewports(ShouldPrintToViewport);

		if (ShouldPrintToViewport)
		{
			SetViewportTexts(MayText, CodyText);
		}else {
			SetViewportTexts("", "");
			if (!HasSelectedOutput)
				ConstantOutput.Reset();
		}

		SetSelectedOutput(SelectedMayOutput, SelectedCodyText);
	}

	bool GetActiveButton(EAudioDebugMode DebugMode, UAudioDebugMenuButton& Button) 
	{
		for(UAudioDebugMenu Menu: AudioDebugMenus)
		{
			if (Menu.DebugButtons.Find(DebugMode, Button) && Button.IsDebugEnabled())
				return true;
		}

		return false;
	}

	bool IsModeSelected(EAudioDebugMode DebugMode)
	{
		for(UAudioDebugMenu Menu: AudioDebugMenus)
		{
			if (Menu.SelectedDebugMode == DebugMode)
				return true;
		}

		return false;
	}

	void ActivateViewports(bool ShouldPrintToViewport) 
	{
		for(UAudioDebugMenu Menu: AudioDebugMenus)
		{
			Menu.ActivateViewports(
					ShouldPrintToViewport ||
					IsDebugEnabled(EAudioDebugMode::Profiler, true) ||
					IsDebugEnabled(EAudioDebugMode::Rtpcs, true)
					);

			break;
		}
	}

	void SetViewportTexts(const FString Mays, const FString Codys) 
	{
		for(UAudioDebugMenu Menu: AudioDebugMenus)
		{
			Menu.MaysViewport.Header.SetText(FText::FromString(Mays));
			Menu.CodysViewport.Header.SetText(FText::FromString(Codys));
			break;
		}
	}

	void SetSelectedOutput(const FString Mays, const FString Codys)
	{
		for(UAudioDebugMenu Menu: AudioDebugMenus)
		{
			Menu.DebugText.SetText(
				FText::FromString(Mays + "\n" + Codys)
				);
		}
	}

	void Register(UAudioDebugMenu DebugMenu)
	{
		AudioDebugMenus.Add(DebugMenu);
	}

	void Unregister(UAudioDebugMenu DebugMenu)
	{
		AudioDebugMenus.Remove(DebugMenu);
	}

	void SetFootstepDebugData(FFootstepTrace Trace, FAudioPhysMaterial PhysMaterial, bool bIsMay)
	{
		FCharacterDebugData DebugData = bIsMay ? MayCharacterDebug : CodyCharacterDebug;
		DebugData.Hit = "" + (Trace.PhysMaterial != nullptr);
		DebugData.MaterialName = Trace.PhysMaterial != nullptr ? Trace.PhysMaterial.Name.ToString() : "Unknown";
		DebugData.MaterialType = "" + PhysMaterial.MaterialType;
		DebugData.SlideType = ""+ PhysMaterial.SlideType;
	}

	FDelayDebugData& GetDelayDataRef(int Index, bool bIsMay)
	{
		if (bIsMay)
		{
			if (MayDelayDebug.Num() != 2) 
			{
				MayDelayDebug.Add(FDelayDebugData());
				MayDelayDebug.Add(FDelayDebugData());
			}
			return MayDelayDebug[Index];
		}else 
		{
			if (CodyDelayDebug.Num() != 2) 
			{
				CodyDelayDebug.Add(FDelayDebugData());
				CodyDelayDebug.Add(FDelayDebugData());
			}
			return CodyDelayDebug[Index];
		}
	}

	void SetDelayDebugData(
		FReflectionTraceData& TraceData, 
		FHitResult& TraceResult,
		UPhysicalMaterialAudio AudioPhysMat,
		AAmbientZone PlayerOwnerPrioZone,
		int Index,
		bool bIsMay)
	{
		FDelayDebugData& DebugData = GetDelayDataRef(Index, bIsMay);

		DebugData.bIsMay = bIsMay;
		DebugData.bStatic = TraceData.CurrentTraceValues.bIsStatic;
		DebugData.bHit = TraceResult.bBlockingHit;
		DebugData.TraceLength = TraceResult.Distance;
		DebugData.TraceMaterial = 
			AudioPhysMat == nullptr 
			? "PhysMat: " + (TraceResult.PhysMaterial != nullptr ? TraceResult.PhysMaterial.Name.ToString() : "None")
		 	: AudioPhysMat.GetName().ToString();

		DebugData.EnviromentType = PlayerOwnerPrioZone.EnvironmentType;
		DebugData.DelayTime = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::DelayTime)].Value;
		DebugData.Feedback = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::FeedbackAmount)].Value;
		
		DebugData.PeakFilterFrequency = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::PeakFilterFrequency)].Value;
		DebugData.PeakFilterGain = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::PeakFilterGain)].Value;
		DebugData.HighFrequency = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::HfShelfFilterFrequency)].Value;
		DebugData.LowFrequency = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::LfShelfFilterFrequency)].Value;
		DebugData.AuxBusLevel = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::AuxBusVolume)].Value;
		DebugData.ReverbSendLevel = TraceData.TraceRtpcDatas[int(EReflectionRtpcType::ReverbSendLevel)].Value;
	}

	void UpdateDelay()
	{
		if (!IsDebugEnabled(EAudioDebugMode::Delay))
			return;

		if (MayDelayDebug.Num() > 0)
			AudioDebugDelay(MayDelayDebug[0], MayDelayDebug[1], true);

		if (CodyDelayDebug.Num() > 0)
			AudioDebugDelay(CodyDelayDebug[0], CodyDelayDebug[1], true);
	}

	void UpdateGeneral()
	{
		if (!IsDebugEnabled(EAudioDebugMode::General))
			return;

		FGeneralDebugData GeneralData = FGeneralDebugData();
		auto AudioManager = GetAudioManager();
		GeneralData.SpeakerSettings = "" + EHazeAudioChannelSetup(AudioManager.CurrentChannelConfig);
		GeneralData.SpeakerType = "" + EHazeAudioSpeakerType(AudioManager.CurrentSpeakerType);
		GeneralData.DynamicRange = "" + EHazeAudioDynamicRange(AudioManager.CurrentDynamicRange);

		GetStateName(HazeAudio::STATES::GameplayStateGroup.ToString(), GeneralData.StateGameplay);
		GetStateName(HazeAudio::STATES::CheckpointStateGroup.ToString(), GeneralData.StateCheckpoints);
		GetStateName(HazeAudio::STATES::LevelStateGroup.ToString(), GeneralData.StateLevels);
		GetStateName(HazeAudio::STATES::SubLevelStateGroup.ToString(), GeneralData.StateSublevels);
		GetStateName(HazeAudio::STATES::MenuStateGroup.ToString(), GeneralData.StateMenu);
		GetStateName(HazeAudio::STATES::CutsceneStateGroup.ToString(), GeneralData.StateCutscene);
		GetStateName(HazeAudio::STATES::DesignerCutsceneStateGroup.ToString(), GeneralData.StateDesignCutscene);

		DebugGeneral(GeneralData, true);
		
		// If needed to debug saved checkpoint.
		// FHazeProgressPointRef OutContinueChapter;
		// FHazeProgressPointRef OutContinuePoint;
		// if (Save::GetContinueProgress(OutContinueChapter, OutContinuePoint))
		// {
		// 	FString Output;
		// 	Output += WrapWithColor("Save Output", "<Red>");
		// 	Output += WrapWithColor("OutContinueChapter: " + OutContinueChapter.InLevel + " / " + OutContinueChapter.Name, "<Green>");
		// 	Output += WrapWithColor("OutContinuePoint: " + OutContinuePoint.InLevel + " / " + OutContinuePoint.Name, "<Green>");
		// 	SetConstantOutput(EAudioDebugMode::General, "Debugging_G", Output, FLinearColor::Gray, true);
		// }
	}

	void UpdateActiveSounds()
	{
		if (!IsDebugEnabled(EAudioDebugMode::ActiveSounds))
			return;

		TArray<UHazeAkComponent> Comps;
		UHazeAkComponent::GetAllHazeAkComponents(Comps);
	
		DebugActiveSounds(Comps, GetAnyMenusActiveSoundFilter() , true);
	}

	FString GetAnyMenusActiveSoundFilter() const
	{
		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			if (!AudioDebugMenu.ActiveSoundsFilter.Text.IsEmpty())
				return AudioDebugMenu.ActiveSoundsFilter.Text.ToString();
		}

		return "";
	}

	EBankLoadState GetAnyBankLoadStateFilter() const
	{
		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			return AudioDebugMenu.BankLoadStateToShow;
		}

		return EBankLoadState::BankLoaded_UnloadRequested;
	}

	void UpdateCharacters()
	{
		if (!IsDebugEnabled(EAudioDebugMode::Characters))
			return;

		FCharacterDebugData MayDebug = MayCharacterDebug;
		FCharacterDebugData CodyDebug = CodyCharacterDebug;

		auto May = Game::GetMay();
		auto Cody = Game::GetCody();

		if (May == nullptr || Cody == nullptr)
			return;
		
		int SwitchTraversal = 0;
		Audio::GetSwitchGroupsCurrentSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, SwitchTraversal, May.PlayerHazeAkComp);
		GetAudioManager().AkObjectMappings.SwitchIdToName.Find(SwitchTraversal, MayDebug.TraversalType);

		Audio::GetSwitchGroupsCurrentSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, SwitchTraversal, Cody.PlayerHazeAkComp);
		GetAudioManager().AkObjectMappings.SwitchIdToName.Find(SwitchTraversal, CodyDebug.TraversalType);

		float AirbourneRTPC = 0;
		ERTPCValueType ValueTypeOut;
		AkGameplay::GetRTPCValue(-1, ERTPCValueType::GameObject, AirbourneRTPC, ValueTypeOut, May, n"Rtpc_Player_Is_Airborne");
		MayDebug.AirbourneRTPC = ""+ AirbourneRTPC;

		AkGameplay::GetRTPCValue(-1, ERTPCValueType::GameObject, AirbourneRTPC, ValueTypeOut, Cody, n"Rtpc_Player_Is_Airborne");
		CodyDebug.AirbourneRTPC = ""+ AirbourneRTPC;

		MayDebug.HealthCapabilities.Reset();
		if (May.IsAnyCapabilityActive(UPlayerGameOverAudioCapability::StaticClass()))
			MayDebug.HealthCapabilities.Add("PlayerGameOverAudioCapability");
		if (May.IsAnyCapabilityActive(UPlayerDeathFadeToBlackAudioCapability::StaticClass()))
			MayDebug.HealthCapabilities.Add("PlayerDeathFadeToBlackAudioCapability");
		if (May.IsAnyCapabilityActive(UPlayerHealthAudioCapability::StaticClass()))
			MayDebug.HealthCapabilities.Add("PlayerHealthAudioCapability");
		if (May.IsAnyCapabilityActive(UPlayerRespawnAudioCapability::StaticClass()))
			MayDebug.HealthCapabilities.Add("PlayerRespawnAudioCapability");
		
		CodyDebug.HealthCapabilities.Reset();
		if (Cody.IsAnyCapabilityActive(UPlayerGameOverAudioCapability::StaticClass()))
			CodyDebug.HealthCapabilities.Add("PlayerGameOverAudioCapability");
		if (Cody.IsAnyCapabilityActive(UPlayerDeathFadeToBlackAudioCapability::StaticClass()))
			CodyDebug.HealthCapabilities.Add("PlayerDeathFadeToBlackAudioCapability");
		if (Cody.IsAnyCapabilityActive(UPlayerHealthAudioCapability::StaticClass()))
			CodyDebug.HealthCapabilities.Add("PlayerHealthAudioCapability");
		if (Cody.IsAnyCapabilityActive(UPlayerRespawnAudioCapability::StaticClass()))
			CodyDebug.HealthCapabilities.Add("PlayerRespawnAudioCapability");

		DebugCharacter(MayDebug, CodyDebug, true);
	}

	void UpdateMusic()
	{
		if (!IsDebugEnabled(EAudioDebugMode::Music))
			return;

		FMusicDebugData DebugData = FMusicDebugData();

		FHazeAudioEventInstance ActiveEvent;
		int32 CurrentFadeOut = 0;
		EAkCurveInterpolation CurrentFadeoutCurve = EAkCurveInterpolation::Exp1;
		GetAudioManager().GetActiveMusicEventInstance(ActiveEvent, CurrentFadeOut, CurrentFadeoutCurve);
		DebugData.Event = ActiveEvent.EventName;
		
		GetMusicStates(DebugData.StateGroup, DebugData.State);

		DebugMusic(DebugData, true);
	}

	void UpdateCutscenes()
	{
		if (!IsDebugEnabled(EAudioDebugMode::Cutscenes))
			return;

		FCutscenesDebugData DebugData = FCutscenesDebugData();

		TArray<UHazeAkComponent> Comps;
		UHazeAkComponent::GetAllHazeAkComponents(Comps);
		for (UHazeAkComponent Comp : Comps)
		{
			if (!Comp.bIsPlaying)
				continue;

			auto ActiveEvents = Comp.ActiveEventInstances;
			for (auto ActiveEvent : ActiveEvents)
			{
				if (!ActiveEvent.bSequencerEvent)
					continue;

				FName CompName = Comp.GetOwner() != nullptr ? Comp.GetOwner().Name : Comp.Name;
				DebugData.ActiveEvents.Add(CompName + " / " + ActiveEvent.EventName);
			}
		}

		auto May = Game::GetMay();
		if (May != nullptr && May.bIsParticipatingInCutscene)
		{
			AHazeLevelSequenceActor SequenceActor = May.GetActiveLevelSequenceActor();
			ULevelSequence Sequence = SequenceActor.GetSequence();
			DebugData.CutsceneSequenceName = Sequence.Name;
		}

		GetStateName(HazeAudio::STATES::CutsceneStateGroup.ToString(), DebugData.MixState);
		GetMusicStates(DebugData.MusicStateGroup, DebugData.MusicState);
		
		DebugCutscenes(DebugData, true);
	}

	void UpdateAmbiences() 
	{
		// Require the same components
		if (!IsDebugEnabled(EAudioDebugMode::Ambiences_Detailed) &&
			!IsDebugEnabled(EAudioDebugMode::Ambiences_Simple) &&
			!IsDebugEnabled(EAudioDebugMode::RandomSpots))
			return;

		auto May = Game::GetMay();
		auto Cody = Game::GetCody();

		if (May == nullptr || Cody == nullptr)
			return;

		FAmbienceDebugData DebugData = FAmbienceDebugData();

		auto MaysZone = Cast<AAmbientZone>(May.PlayerHazeAkComp.GetPrioReverbZone());
		auto CodysZone = Cast<AAmbientZone>(Cody.PlayerHazeAkComp.GetPrioReverbZone());	

		if (MaysZone == nullptr || CodysZone == nullptr)
			return;

		TArray<AActor> Zones;
		Gameplay::GetAllActorsOfClass(AAmbientZone::StaticClass(), Zones);
		DebugData.AmbientZones = Zones;
		
		DebugData.MayEnviromentType = ""+ MaysZone.EnvironmentType;
		DebugData.CodyEnviromentType = ""+ CodysZone.EnvironmentType;

		TArray<UHazeListenerComponent> Listeners;
		Listeners.Add(May.PlayerHazeAkComp.GetPlayerListener());
		Listeners.Add(Cody.PlayerHazeAkComp.GetPlayerListener());
		DebugData.Listeners = Listeners;

		DebugAmbiencesDetailed(DebugData, IsDebugEnabled(EAudioDebugMode::Ambiences_Detailed));
		DebugAmbiencesSimple(DebugData, IsDebugEnabled(EAudioDebugMode::Ambiences_Simple));

		UpdateRandomSpots(Zones);
	}

	void UpdateRandomSpots(TArray<AActor> Zones)
	{
		if (!IsDebugEnabled(EAudioDebugMode::RandomSpots))
			return;

		FRandomSpotsDebugData DebugData = FRandomSpotsDebugData();
		DebugData.AmbientZones = Zones;

		DebugRandomSpots(DebugData, true);
	}

	void UpdateRtpcs()
	{
		if (!IsDebugEnabled(EAudioDebugMode::Rtpcs))
			return;

		#if EDITOR
		auto SelectedActors = EditorUtility::GetSelectionSet();
		FString RightOutput = WrapWithColor("SELECTED ACTORS RTPCS", "<Black>");
		for (auto& Actor : SelectedActors)
		{
			auto HazeAkComp = UHazeAkComponent::Get(Actor);
			if (HazeAkComp != nullptr)
			{
				RightOutput += WrapWithColor(Actor.Name.ToString(), "<Yellow>");
				TMap<int, float> Rtpcs;
				HazeAkComp.GetRtpcsSetByID(Rtpcs);
				for (auto& Pair: Rtpcs)
				{
					FString RtpcName;
					if (!Audio::FindStringFromID(Pair.Key, RtpcName))
					{
						RtpcName = "" + Pair.Key;
					}
					RightOutput += WrapWithColor("\t" + Actor.Name + " / " + RtpcName + ": "+ Pair.Value, "<Green>");
				}
			}
		}
		SetConstantOutput(EAudioDebugMode::Rtpcs, "SelectedActors_RTPCs", RightOutput, FLinearColor::Green, false);

		#endif

		if (AudioDebugMenus.Num() == 0)
			return;

		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			if ((AudioDebugMenu.RtpcWidget.GetVisibility() == ESlateVisibility::Visible)
				== IsDebugEnabled(EAudioDebugMode::Rtpcs, true))
				continue;

			AudioDebugMenu.ActivateRTPCWidget(IsDebugEnabled(EAudioDebugMode::Rtpcs, true));
			break;
		}
	}

	void UpdateProfiler()
	{
		bool UsingWwise = Audio::IsWaapiConnected();
		if (!UsingWwise && bProfiling)
		{
			bProfiling = false;
			Audio::UnregisterResourceMonitoring();
			Audio::UnregisterBusMetering(MasterBusId);
		}
		else if (!bProfiling && UsingWwise)
		{
			bProfiling = true;
			Audio::RegisterResourceMonitoring();
			Audio::RegisterBusMetering(MasterBusId);
		}

		if (AudioDebugMenus.Num() == 0 || !bProfiling)
			return; 

		ProfilingData = Audio::GetProfilingData();
		// NOTE: The value we get for wwise is just a squared power value, and not equal to LUFS.
		// But can be used for that calculation, which isn't worth the time currently.
		float LUFSdb = FMath::Clamp(10.f * FMath::LogX(10.f, ProfilingData.LUFS), -120, 0);
		
		auto MemoryData = Audio::GetProfilingMemoryData();
		uint64 MediaMemoryInMB = (uint64(MemoryData.uUsed) / (1024*1024));
		if (!Game::IsInLoadingScreen())
		{
			FString LevelName = Progress::PIELevelName;
			// if (LUFSdb > -18)
			// {
			// 	//REPORT
			// 	Audio::OutputErrorToWwiseAuthoring("EXCEEDED LUFS LIMIT! LUFS: " + LUFSdb + ", Level: " + LevelName, nullptr);
			// }

			if (ProfilingData.PhysicalVoices > 100)
			{
				//REPORT
				Audio::OutputErrorToWwiseAuthoring("EXCEEDED PhysicalVoices LIMIT! Count: " + ProfilingData.PhysicalVoices+ " Level: "+ LevelName, nullptr);
			}

			if (MediaMemoryInMB > 500
				&& !ReportInLevels.Contains(LevelName))
			{
				ReportInLevels.Add(LevelName);
				//REPORT
				Audio::OutputErrorToWwiseAuthoring("EXCEEDED MEMORY LIMIT! " + MediaMemoryInMB + "MB" + " Level: " + LevelName, nullptr);
			}
		}
		
		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			auto GraphWidget = AudioDebugMenu.ProfilerWidget.GraphWidget;

			GraphWidget.AddElement("TotalCPU", ProfilingData.TotalCPU);
			GraphWidget.AddElement("PhysicalVoices", ProfilingData.PhysicalVoices);
			GraphWidget.AddElement("TotalVoices", ProfilingData.TotalVoices);
			GraphWidget.AddElement("Media Memory", MediaMemoryInMB);

			if ((AudioDebugMenu.ProfilerWidget.GetVisibility() == ESlateVisibility::Visible)
				== IsDebugEnabled(EAudioDebugMode::Profiler, true))
				return;
			
			AudioDebugMenu.ActivateProfilerWidget(IsDebugEnabled(EAudioDebugMode::Profiler, true));
			break;
		}
	}

	void UpdateLoadedBanks()
	{
		if (!IsDebugEnabled(EAudioDebugMode::LoadedBanks, false))
			return;

		auto AudioManager = GetAudioManager();

		FString Filter = GetAnyMenusActiveSoundFilter();
		EBankLoadState BankFilter = GetAnyBankLoadStateFilter();

		TArray<int> LoadedBanks = Audio::GetAllBanksWithState(BankFilter);
		TArray<FString> Converted;

		for (uint BankID: LoadedBanks)
		{	
			FString BankName = "Unknown";
			if(!AudioManager.AkObjectMappings.BankIdToName.Find(BankID, BankName))
			{
				Audio::FindStringFromID(BankID, BankName);
			}

			BankName = "" + BankID + " / " + BankName;
			if(Filter.IsEmpty() || BankName.Contains(Filter))
				Converted.Add(BankName);
		}

		DebugLoadedBanks(Converted, true);
	}
	
	// HELPER FUNCTIONS

	bool IsDebugEnabled(EAudioDebugMode DebugMode, bool includeSelection = false)
	{
		for(UAudioDebugMenu AudioDebugMenu: AudioDebugMenus)
		{
			if (includeSelection && AudioDebugMenu.SelectedDebugMode == DebugMode)
				return true;

			return AudioDebugMenu.IsDebugEnabled(DebugMode);
		}

		return HazeAudio::IsDebugEnabled(DebugMode);
	}

	void GetMusicStates(FString& StateGroup, FString& State)
	{
		StateGroup = "MStg_" + GetAudioManager().CurrentLevelGroup;
		GetStateName(StateGroup, State);	
	}

	void GetStateName(const FString StateGroup, FString& StateName)
	{
		int CurrentState = 0;
		if (!Audio::GetStateGroupsCurrentState(StateGroup, CurrentState)) 
		{
			StateName = "Unknown";
			return;
		}

		GetAudioManager().AkObjectMappings.StateIdToName.Find(CurrentState, StateName);

		if (StateName == "")
		{
			StateName = "None or Unknown";
		}
	}

	void GetSwitchName(
		const FString SwitchGroup, 
		const UHazeAkComponent AkComp, 
		FString& SwitchName)
	{
		int CurrentSwitch = 0;
		Audio::GetSwitchGroupsCurrentSwitch(SwitchGroup, CurrentSwitch, AkComp);
		GetAudioManager().AkObjectMappings.SwitchIdToName.Find(CurrentSwitch, SwitchName);
		if (SwitchName == "")
		{
			SwitchName = "None or Unknown";
		}
	}
}

#endif