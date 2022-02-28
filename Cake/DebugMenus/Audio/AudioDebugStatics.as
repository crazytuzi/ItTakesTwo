enum EAudioDebugMode
{
	None = -1,
	General,
	Characters,
	Music,
	Cutscenes,
	Ambiences_Detailed,
	Ambiences_Simple,
	RandomSpots,
	Delay,
	ActiveSounds,
	Rtpcs,
	Profiler,
	NetworkCompare,
	LoadedBanks,
	NumOfModes,
};

 
namespace HazeAudio
{
	bool IsDebugEnabled(EAudioDebugMode DebugMode)
	{
		#if TEST

		switch (DebugMode)
		{
			case EAudioDebugMode::General:
			return CVar_AudioDebugModeGeneralEnabled.GetInt() != 0;
			case EAudioDebugMode::Characters:
			return CVar_AudioDebugModeCharactersEnabled.GetInt() != 0;
			case EAudioDebugMode::Music:
			return CVar_AudioDebugModeMusicEnabled.GetInt() != 0;
			case EAudioDebugMode::Cutscenes:
			return CVar_AudioDebugModeCutscenesEnabled.GetInt() != 0;
			case EAudioDebugMode::Ambiences_Detailed:
			return CVar_AudioDebugModeAmbiences_DetailedEnabled.GetInt() != 0;
			case EAudioDebugMode::Ambiences_Simple:
			return CVar_AudioDebugModeAmbiences_SimpleEnabled.GetInt() != 0;
			case EAudioDebugMode::RandomSpots:
			return CVar_AudioDebugModeRandomSpotsEnabled.GetInt() != 0;
			case EAudioDebugMode::Delay:
			return CVar_AudioDebugModeDelayEnabled.GetInt() != 0;
			case EAudioDebugMode::ActiveSounds:
			return CVar_AudioDebugModeActiveSoundsEnabled.GetInt() != 0;
			case EAudioDebugMode::Rtpcs:
			return CVar_AudioDebugModeRTPCsEnabled.GetInt() != 0;
			case EAudioDebugMode::Profiler:
			return CVar_AudioDebugModeProfilerEnabled.GetInt() != 0;
			case EAudioDebugMode::NetworkCompare:
			return CVar_AudioDebugModeNetworkCompareEnabled.GetInt() != 0;
			case EAudioDebugMode::LoadedBanks:
			return CVar_AudioDebugModeLoadedBanksEnabled.GetInt() != 0;
		}
		#endif

		return false;
	}

	FString ToString(EAudioDebugMode DebugMode)
	{
		switch (DebugMode)
		{
			case EAudioDebugMode::General:
			return "General";
			case EAudioDebugMode::Characters:
			return "Characters";
			case EAudioDebugMode::Music:
			return "Music";
			case EAudioDebugMode::Cutscenes:
			return "Cutscenes";
			case EAudioDebugMode::Ambiences_Detailed:
			return "Ambiences_Detailed";
			case EAudioDebugMode::Ambiences_Simple:
			return "Ambiences_Simple";
			case EAudioDebugMode::RandomSpots:
			return "RandomSpots";
			case EAudioDebugMode::Delay:
			return "Delay";
			case EAudioDebugMode::ActiveSounds:
			return "ActiveSounds";
			case EAudioDebugMode::Rtpcs:
			return "Rtpcs";
			case EAudioDebugMode::Profiler:
			return "Profiler";
			case EAudioDebugMode::NetworkCompare:
			return "NetworkCompare";
			case EAudioDebugMode::LoadedBanks:
			return "LoadedBanks";
		}

		return "" + DebugMode;
	}

	FString ToCVARString(EAudioDebugMode DebugMode)
	{
		switch (DebugMode)
		{
			case EAudioDebugMode::General:
			return "HazeAudio.DebugGeneral";
			case EAudioDebugMode::Characters:
			return "HazeAudio.DebugCharacters";
			case EAudioDebugMode::Music:
			return "HazeAudio.DebugMusic";
			case EAudioDebugMode::Cutscenes:
			return "HazeAudio.DebugCutscenes";
			case EAudioDebugMode::Ambiences_Detailed:
			return "HazeAudio.DebugAmbiencesDetailed";
			case EAudioDebugMode::Ambiences_Simple:
			return "HazeAudio.DebugAmbiencesSimple";
			case EAudioDebugMode::RandomSpots:
			return "HazeAudio.DebugRandomSpots";
			case EAudioDebugMode::Delay:
			return "HazeAudio.DebugDelay";
			case EAudioDebugMode::ActiveSounds:
			return "HazeAudio.DebugActiveSounds";
			case EAudioDebugMode::Rtpcs:
			return "HazeAudio.DebugRtpcs";
			case EAudioDebugMode::Profiler:
			return "HazeAudio.ShowProfiler";
			case EAudioDebugMode::NetworkCompare:
			return "HazeAudio.DebugNetwork";
			case EAudioDebugMode::LoadedBanks:
			return "HazeAudio.DebugLoadedBanks";
		}

		return "" + DebugMode;
	}
}

#if TEST

import Peanuts.Audio.AmbientZone.AmbientZone;

import void SetConstantOutput(EAudioDebugMode, FString, FString, FLinearColor, bool) from "Cake.DebugMenus.Audio.AudioDebugManager";

const FConsoleVariable CVar_AudioDebugModeGeneralEnabled("HazeAudio.DebugGeneral", 0);
const FConsoleVariable CVar_AudioDebugModeCharactersEnabled("HazeAudio.DebugCharacters", 0);
const FConsoleVariable CVar_AudioDebugModeMusicEnabled("HazeAudio.DebugMusic", 0);
const FConsoleVariable CVar_AudioDebugModeCutscenesEnabled("HazeAudio.DebugCutscenes", 0);
const FConsoleVariable CVar_AudioDebugModeAmbiences_DetailedEnabled("HazeAudio.DebugAmbiencesDetailed", 0);
const FConsoleVariable CVar_AudioDebugModeAmbiences_SimpleEnabled("HazeAudio.DebugAmbiencesSimple", 0);
const FConsoleVariable CVar_AudioDebugModeRandomSpotsEnabled("HazeAudio.DebugRandomSpots", 0);
const FConsoleVariable CVar_AudioDebugModeDelayEnabled("HazeAudio.DebugDelay", 0);
const FConsoleVariable CVar_AudioDebugModeActiveSoundsEnabled("HazeAudio.DebugActiveSounds", 0);
const FConsoleVariable CVar_AudioDebugModeRTPCsEnabled("HazeAudio.DebugRtpcs", 0);
const FConsoleVariable CVar_AudioDebugModeProfilerEnabled("HazeAudio.ShowProfiler", 0);
const FConsoleVariable CVar_AudioDebugModeNetworkCompareEnabled("HazeAudio.DebugNetwork", 0);
const FConsoleVariable CVar_AudioDebugModeLoadedBanksEnabled("HazeAudio.DebugLoadedBanks", 0);

class FDelayDebugData
{
	bool bIsMay;
	//Trace
 
	bool bHit;
	bool bStatic;
	float TraceLength;
	FString TraceMaterial;

	//Settings	
	EEnvironmentType EnviromentType;
	float DelayTime;
	float Feedback;
	float HighFrequency;
	float PeakFilterFrequency;
	float PeakFilterGain;
	float LowFrequency;
	float AuxBusLevel;
	float ReverbSendLevel;
};

const FString NewLine = "\n";
const FString Tab = "\t\t";
const FString QuadTab = "\t\t\t\t";
const FString May = "May";
const FString Cody = "Cody";

void AudioDebugDelay(FDelayDebugData Left, FDelayDebugData Right, bool bForceUpdate)
{	
	if (CVar_AudioDebugModeDelayEnabled.GetInt() == 0 && !bForceUpdate)
		return;
	
	const FString Title = "Trace Delay Debug";

	FString Output;
	AddDelayOutput(Output, Left, "Trace Delay Debug - Left");
	AddDelayOutput(Output, Right, "Trace Delay Debug - Right");

	SetConstantOutput(EAudioDebugMode::Delay, Title + (Left.bIsMay ? May : Cody), Output, FLinearColor::Gray, Left.bIsMay);
}

void AddDelayOutput(FString& Output, FDelayDebugData DebugData, FString Title) 
{
	FString TraceColor = DebugData.bHit ? "<Green>" : "<Red>";
	FString StaticTraceColor = DebugData.bStatic ? "<Green>" : "<Red>";
	Output += "<Yellow> "+ Title + " </> "+ NewLine;
	Output += Tab + "Enviroment Type:		" + DebugData.EnviromentType + NewLine;
	Output += Tab + "Enviroment Static:		" + StaticTraceColor + DebugData.bStatic + "</>" + NewLine;
	Output += Tab + "Trace Has Hit:			" + TraceColor + DebugData.bHit + "</>" + NewLine;
	Output += Tab + "Trace Length:			" + DebugData.TraceLength + NewLine;
	Output += Tab + "Trace Hit Material:	" + DebugData.TraceMaterial + NewLine;
	Output += Tab + "Delay Time:			" + DebugData.DelayTime + NewLine;
	Output += Tab + "Feedback Amount:		" + DebugData.Feedback + NewLine;
	Output += Tab + "Peak Filter Freq:		" + DebugData.PeakFilterFrequency + NewLine;
	Output += Tab + "Peak Filter Gain:		" + DebugData.PeakFilterGain + NewLine;
	Output += Tab + "HF Filter Freq:		" + DebugData.HighFrequency + NewLine;
	Output += Tab + "LF Filter Freq:		" + DebugData.LowFrequency + NewLine;
	Output += Tab + "AuxBus Level:			" + DebugData.AuxBusLevel + NewLine;
	Output += Tab + "Reverb Send Level:		" + DebugData.ReverbSendLevel +NewLine;
}

class FGeneralDebugData
{
	FString SpeakerSettings;
	FString SpeakerType;
	FString DynamicRange;

	FString StateGameplay;
	FString StateCheckpoints;
	FString StateLevels;
	FString StateSublevels;
	FString StateMenu;
	FString StateCutscene;
	FString StateDesignCutscene;
}

void DebugGeneral(FGeneralDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeGeneralEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString Output;
	const FString Title = "General";
	Output += "<Red> "+ Title + " </> "+ NewLine;
	Output += Tab + "Speaker Settings:		" + DebugData.SpeakerSettings + NewLine;
	Output += Tab + "SpeakerType:			" + DebugData.SpeakerType + NewLine;
	Output += Tab + "DynamicRange:			" + DebugData.DynamicRange + NewLine + NewLine;

	Output += Tab + "StateGroup_Gameplay:	" + DebugData.StateGameplay + NewLine;
	Output += Tab + "StateGroup_Checkpoints:" + DebugData.StateCheckpoints + NewLine;
	Output += Tab + "StateGroup_Levels:		" + DebugData.StateLevels + NewLine;
	Output += Tab + "StateGroup_Sublevels:	" + DebugData.StateSublevels + NewLine;
	Output += Tab + "StateGroup_Menu:		" + DebugData.StateMenu + NewLine;
	Output += Tab + "StateGroup_Cutscene:	" + DebugData.StateCutscene + NewLine;
	Output += Tab + "StateGroup_DesignerCutscene:	" + DebugData.StateDesignCutscene + NewLine;

	SetConstantOutput(EAudioDebugMode::General, Title, Output, FLinearColor::Gray, true);
}

class FCharacterDebugData
{
	FString TraversalType;

	FString MaterialName;
	FString MaterialType;
	FString Hit;
	FString SlideType;
	FString AirbourneRTPC;
	TArray<FString> HealthCapabilities;
}

void DebugCharacter(FCharacterDebugData MayData, FCharacterDebugData CodyData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeCharactersEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString MaysOutput;
	const FString MaysTitle = "Character - May";
	MaysOutput += "<Red> "+ MaysTitle + " </> "+ NewLine;
	MaysOutput += Tab + "TraversalType:	" + MayData.TraversalType + NewLine;

	MaysOutput += Tab + "MaterialName:	" + MayData.MaterialName + NewLine;
	MaysOutput += Tab + "MaterialType:	" + MayData.MaterialType + NewLine;
	MaysOutput += Tab + "Hit:			" + MayData.Hit + NewLine;
	MaysOutput += Tab + "SlideType:		" + MayData.SlideType + NewLine;
	MaysOutput += Tab + "Airbourne RTPC:" + MayData.AirbourneRTPC + NewLine;
	for (FString Capability : MayData.HealthCapabilities)
		MaysOutput += Tab + "Capability: " + Capability + NewLine;

	SetConstantOutput(EAudioDebugMode::Characters, MaysTitle, MaysOutput, FLinearColor::Gray, true);
	
	FString CodysOutput;
	const FString CodysTitle = "Character - Cody";
	CodysOutput += "<Red> "+ CodysTitle + " </> "+ NewLine;
	CodysOutput += Tab + "TraversalType:" + CodyData.TraversalType + NewLine;

	CodysOutput += Tab + "MaterialName:	" + CodyData.MaterialName + NewLine;
	CodysOutput += Tab + "MaterialType:	" + CodyData.MaterialType + NewLine;
	CodysOutput += Tab + "Hit:			" + CodyData.Hit + NewLine;
	CodysOutput += Tab + "SlideType:	" + CodyData.SlideType + NewLine;
	CodysOutput += Tab + "Airbourne RTPC:"+ CodyData.AirbourneRTPC + NewLine;
	for (FString Capability : CodyData.HealthCapabilities)
		CodysOutput += Tab + "Capability: " + Capability + NewLine;

	SetConstantOutput(EAudioDebugMode::Characters, CodysTitle, CodysOutput, FLinearColor::Gray, false);
}

class FMusicDebugData
{
	FString Event;
	FString StateGroup;
	FString State;
}

void DebugMusic(FMusicDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeMusicEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString Output;
	const FString Title = "Music";
	Output += "<Red> "+ Title + " </> "+ NewLine;
	Output += Tab + "Event:			" + DebugData.Event + NewLine;
	Output += Tab + "State Group:	" + DebugData.StateGroup + NewLine;
	Output += Tab + "State:			" + DebugData.State + NewLine;

	SetConstantOutput(EAudioDebugMode::Music, Title, Output, FLinearColor::Gray, true);
}

class FCutscenesDebugData
{
	FString CutsceneSequenceName;
	FString MixState;
	FString MusicState;
	FString MusicStateGroup;

	TArray<FString> ActiveEvents;
}

void DebugCutscenes(FCutscenesDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeCutscenesEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString Output;
	const FString Title = "Cutscenes";
	Output += "<Red> "+ Title + " </> "+ NewLine;
	Output += Tab + "CS Seq Name:			" + DebugData.CutsceneSequenceName + NewLine;
	Output += Tab + "StateGroup_Cutscenes:	" + DebugData.MixState + NewLine;
	Output += Tab + DebugData.MusicStateGroup +": " + DebugData.MusicState + NewLine;
	Output += "Active Sound Events:"  + NewLine;
	for	(const auto Event : DebugData.ActiveEvents)
	{
		Output += Tab + WrapWithColor(Event, "<Green>"); 
	}

	SetConstantOutput(EAudioDebugMode::Cutscenes, Title, Output, FLinearColor::Gray, true);
}

void DebugActiveSounds(TArray<UHazeAkComponent> AllHazeComponents, FString Filter, bool bForceUpdate)
{
	if (CVar_AudioDebugModeActiveSoundsEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString LeftOutput;
	const FString LeftTitle = "Active Sounds";
	LeftOutput += "<Red> "+ LeftTitle + " </> "+ NewLine;
	LeftOutput += " Component \t / \t Event \t / \t Distance \t / Listener" + NewLine;

	FString RightOutput;
	const FString RightTitle = "Inactive Sounds";
	RightOutput += "<Red> "+ RightTitle + " </> "+ NewLine;
	RightOutput += " Component Or Actor" + NewLine;

	FString ActiveInRangeOutput = "<Black> Active/Playing/InRange </> "+ NewLine;
	FString ActiveOutOfRangeOutput = "<Black> Active/Playing/OutOfRange </> "+ NewLine;
	FString ActiveNotPlayingOutput = "<Black> Active/NotPlaying</> "+ NewLine;
	FString DisabledOutput = "<Black> Disabled </> "+ NewLine;
	FString WarningOutput = "";

	int DisableCounter = 0;
	int NotPlayingCounter = 0;

	for (UHazeAkComponent Comp : AllHazeComponents)
	{
		if (!Comp.IsGameObjectRegisteredWithWwise())
			continue;

		FName Name = Comp.GetOwner() != nullptr ? Comp.GetOwner().Name : Comp.Name;

		if (!Comp.bIsEnabled && !Comp.IsPooledObject())
		{
			DisableCounter++;
			DisabledOutput += "<Grey>" + Name + "</> |";
			if (DisableCounter == 3)
			{
				DisableCounter = 0;
				DisabledOutput += NewLine;
			}			
		}
		else if (!Comp.bIsPlaying && !Comp.IsPooledObject())
		{
			NotPlayingCounter++;
			ActiveNotPlayingOutput += "<Red>" + Name + "</> |";
			if (NotPlayingCounter == 3)
			{
				NotPlayingCounter = 0;
				ActiveNotPlayingOutput += NewLine;
			}
		}
		// We also show active fire forget, i.e pooled objects events.
		else {
			auto ActiveEvents = Comp.ActiveEventInstances;
			
			auto ClosestListener = UHazeAkComponent::GetClosestListener(Comp.GetWorld(), Comp.GetWorldLocation());
			float Distance = ClosestListener != nullptr ? 
				ClosestListener.GetWorldLocation().Distance(Comp.GetWorldLocation())
				: 0.f;

			bool InRadius = 
				Comp.MaxAttenuationRadius == 0 ||
				Distance <= Comp.ScaledMaxAttenuationRadius;

			FString Color = InRadius ? "<Green>" : "<Blue>";
			FName ListerName = ClosestListener != nullptr ? 
				(ClosestListener.Owner != nullptr ? ClosestListener.Owner.Name : Name) : 
				n"Unknown";

			TMap<int, int> EventsByID;
			for (auto ActiveEvent : ActiveEvents)
			{
				if (!Filter.IsEmpty() && !ActiveEvent.EventName.Contains(Filter))
					continue;
				
				++EventsByID.FindOrAdd(ActiveEvent.EventID);
				
				if (ActiveEvent.bSequencerEvent)
				{
					Color = "<Orange>";
				}
				else if (Comp.IsPooledObject())
					Color = "<Yellow>";

				FString Text =
						Tab + Color + Name  + " / " 
						+ ActiveEvent.EventName  + " / " 
						+ int(Distance) + " / "
						+ ListerName
						+ "</>" + NewLine;

				if (InRadius)
					ActiveInRangeOutput += Text;
				else
					ActiveOutOfRangeOutput += Text;

			}

			for (auto ActiveEvent : ActiveEvents)
			{
				int Count = 0;
				if (!EventsByID.Find(ActiveEvent.EventID, Count) || Count == 1)
					continue;

				if (WarningOutput.IsEmpty())
				{
					WarningOutput += "<Red> WARNING - MULTIPLE EVENTS OF THE SAME TYPE, On the same object </> "+ NewLine;
				}

				WarningOutput += 
					Tab + "<Yellow>" + 
					Name + " / " + ActiveEvent.EventName +
					"(Count: " + (Count) + ")" +
					"</>" + NewLine;

				EventsByID.Remove(ActiveEvent.EventID);
			}
		}	
	}

	if (!WarningOutput.IsEmpty())
		LeftOutput += WarningOutput + NewLine;
	LeftOutput += ActiveInRangeOutput + NewLine;
	LeftOutput += ActiveOutOfRangeOutput + NewLine;

	RightOutput += ActiveNotPlayingOutput + NewLine;
	RightOutput += DisabledOutput;

	SetConstantOutput(EAudioDebugMode::ActiveSounds, LeftTitle,
		LeftOutput, FLinearColor::Green, true);
	SetConstantOutput(EAudioDebugMode::ActiveSounds, RightTitle, 
		RightOutput, FLinearColor::Gray, false);
}

class FAmbienceDebugData
{
	TArray<AActor> AmbientZones;
	FString MayEnviromentType;
	FString CodyEnviromentType;

	TArray<UHazeListenerComponent> Listeners;
}

void DebugAmbiencesDetailed(FAmbienceDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeAmbiences_DetailedEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString LeftOutput;
	const FString LeftTitle = "Ambiences Detailed - May";
	LeftOutput += "<Red> "+ LeftTitle + " </> "+ NewLine;
	LeftOutput += WrapWithColor("Enviroment Type: " + DebugData.MayEnviromentType, "<Red>");
	LeftOutput += " Name \t / \t Enviroment Type"  + NewLine;

	FString RightOutput;
	const FString RightTitle = "Ambiences Detailed - Cody";
	RightOutput += "<Red> "+ RightTitle + " </> "+ NewLine;
	RightOutput += WrapWithColor(" Enviroment Type: " + DebugData.CodyEnviromentType, "<Red>");
	RightOutput += " Name \t / \t Enviroment Type"  + NewLine;
	
	for	(AActor Actor : DebugData.AmbientZones)
	{
		auto Zone = Cast<AAmbientZone>(Actor);

		if (Zone.AmbEventComp == nullptr) 
		{
			PrintToScreen(Zone.GetName() + " is missings it's HazeAkComponent!");
			continue;
		}

		auto ClosestListener = Zone.AmbEventComp.GetClosestPlayer();
		FString& Output = ClosestListener.IsMay() ? LeftOutput : RightOutput;
		const FString Color = Zone == ClosestListener.PlayerHazeAkComp.GetPrioReverbZone() ?
			"<Green>" : "<Red>";

		auto ZoneAssetName = Zone.ZoneAsset != nullptr ? Zone.ZoneAsset.Name.ToString() : "";
		auto ReverbName = Zone.ReverbBus != nullptr ? Zone.ReverbBus.Name.ToString() : "";

		Output += WrapWithColor(Zone.Name + " / " + Zone.EnvironmentType, Color);
		Output += WrapWithColor(Tab + "ZoneAsset: 		" + ZoneAssetName, Color);
		Output += WrapWithColor(Tab + "ReverbBus: 		" + ReverbName, Color);
		Output += WrapWithColor(Tab + "RTPC: 			" + Zone.CurrentRtpcValue, Color);
		Output += WrapWithColor(Tab + "Priority: 		" + Zone.Priority , Color);
		Output += WrapWithColor(Tab + "Relevance: 		" + Zone.Relevance 	, Color);
		Output += WrapWithColor(Tab + "Steal Reverb: 	" + Zone.IsStealingReverb(), Color);
		
		auto ReverbComp = ClosestListener.PlayerHazeAkComp.ReverbComponent;
		if (ReverbComp != nullptr)
		{
			auto SendValues = ReverbComp.GetAuxSendValues();
			if (SendValues.Num() > 0 && Zone.ReverbBus != nullptr)
			{
				float Value = 0;
				SendValues.Find(Zone.ReverbBus.ShortID, Value);
				Output += WrapWithColor(Tab + "Send Level: 	" + Value, Color);
			}
		}
	}

	SetConstantOutput(EAudioDebugMode::Ambiences_Detailed, LeftTitle, LeftOutput, FLinearColor::Gray, true);
	SetConstantOutput(EAudioDebugMode::Ambiences_Detailed, RightTitle, RightOutput, FLinearColor::Gray, false);
}

void DebugAmbiencesSimple(FAmbienceDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeAmbiences_SimpleEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString LeftOutput;
	const FString LeftTitle = "Ambiences Simple - May";
	LeftOutput += "<Red> "+ LeftTitle + " </> "+ NewLine;

	FString RightOutput;
	const FString RightTitle = "Ambiences Simple - Cody";
	RightOutput += "<Red> "+ RightTitle + " </> "+ NewLine;
	
	LeftOutput += WrapWithColor("Enviroment Type: " + DebugData.MayEnviromentType, "<Red>");
	LeftOutput += WrapWithColor("Active Reverbs:", "<Red>");
	RightOutput += WrapWithColor(" Enviroment Type: " + DebugData.CodyEnviromentType, "<Red>");
	RightOutput += WrapWithColor("Active Reverbs:", "<Red>");

	FString LeftZones; 
	LeftZones += " Name \t / \t Enviroment Type"  + NewLine;

	FString RightZones;
	RightZones += " Name \t / \t Enviroment Type"  + NewLine;

	for	(AActor Actor : DebugData.AmbientZones)
	{
		auto Zone = Cast<AAmbientZone>(Actor);

		if (Zone.AmbEventComp == nullptr)
		{
			Print(Zone.GetName() + " is missings it's HazeAkComponent!");
			continue;
		}

		auto ClosestListener = Zone.AmbEventComp.GetClosestPlayer();
		const FString Color = Zone == ClosestListener.PlayerHazeAkComp.GetPrioReverbZone() ?
			"<Green>" : "<Red>";

		auto ReverbComp = ClosestListener.PlayerHazeAkComp.ReverbComponent;
		if (ReverbComp != nullptr)
		{
			auto SendValues = ReverbComp.GetAuxSendValues();
			//Shouldn't be null but there are cases...
			if (Zone.ReverbBus != nullptr) 
			{
				if (SendValues.Num() > 0) 
				{
					float Value = 0;
					if (SendValues.Find(int(Zone.ReverbBus.ShortID), Value))
					{
						FString ReverbOutput = WrapWithColor(Tab + Zone.Name + " / " + Zone.ReverbBus.Name + " / Send Level: 	" + Value, Color);
						if (ClosestListener.IsMay() && Zone.IsActualListener(DebugData.Listeners[0]))
							LeftOutput += ReverbOutput;
						if (ClosestListener.IsCody() && Zone.IsActualListener(DebugData.Listeners[1]))
							RightOutput += ReverbOutput;
					}
				}
			}
		}

		if (Zone.CurrentRtpcValue == 0)
			continue;

		FString& Output = ClosestListener.IsMay() ? LeftZones : RightZones;

		Output += WrapWithColor(Zone.Name + " / " + Zone.EnvironmentType, Color);
		Output += WrapWithColor(Tab + "ZoneAsset: 	" + Zone.ZoneAsset.Name, Color);
		Output += WrapWithColor(Tab + "RTPC: 		" + Zone.CurrentRtpcValue, Color);
	}

	LeftOutput += NewLine + LeftZones;
	RightOutput += NewLine + RightZones;

	SetConstantOutput(EAudioDebugMode::Ambiences_Simple, LeftTitle, LeftOutput, FLinearColor::Gray, true);
	SetConstantOutput(EAudioDebugMode::Ambiences_Simple, RightTitle, RightOutput, FLinearColor::Gray, false);
}

class FRandomSpotsDebugData
{
	TArray<AActor> AmbientZones;
}

void DebugRandomSpots(FRandomSpotsDebugData DebugData, bool bForceUpdate)
{
	if (CVar_AudioDebugModeRandomSpotsEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString LeftOutput;
	const FString LeftTitle = "Random Spots - May";
	LeftOutput += "<Red> "+ LeftTitle + " </> "+ NewLine;

	FString RightOutput;
	const FString RightTitle = "Random Spots - Cody";
	RightOutput += "<Red> "+ RightTitle + " </> "+ NewLine;

	FString LeftRandomSpots = "";
	FString RightRandomSpots = "";

	TArray<AAmbientZone> MayAssets;
	TArray<AAmbientZone> CodyAssets;

	for	(AActor Actor : DebugData.AmbientZones)
	{
		auto Zone = Cast<AAmbientZone>(Actor);

		for	(UHazeAkComponent Spot : Zone.RandomSpotsAkComps)
		{
			auto ClosestListener = Spot.GetClosestPlayer();
			float Distance = ClosestListener.
				ListenerComponent.GetWorldLocation().Distance(Spot.GetWorldLocation());

			const FString Color = Spot.ActiveEventInstances.Num() > 0 ?
				"<Green>" : "<Red>";

			if (Spot.bIsPlaying)
			{
				if (ClosestListener.IsMay())
					MayAssets.AddUnique(Zone);
				else
					CodyAssets.AddUnique(Zone);
			}

			FString& Output = ClosestListener.IsMay() ? LeftRandomSpots : RightRandomSpots;
			const FString Name = Spot.Name;
			Output += WrapWithColor(Name + " / Distance: " + int(Distance), Color);

			for (auto ActiveEvent : Spot.ActiveEventInstances)
			{
				Output += WrapWithColor(Tab + ActiveEvent.EventName, Color);
			}
		}
		
	}

	for	(AAmbientZone Zone : MayAssets)
	{
		LeftOutput += WrapWithColor(
			"Asset: " + Zone.RandomSpotSounds.Name +
			" / " + Zone.Name, 
			"<Green>");
	}

	for	(AAmbientZone Zone : CodyAssets)
	{
		RightOutput += WrapWithColor(
			"Asset: " + Zone.RandomSpotSounds.Name +
			" / " + Zone.Name, 
			"<Green>");
	}


	LeftOutput += NewLine + LeftRandomSpots;
	RightOutput += NewLine + RightRandomSpots;

	SetConstantOutput(EAudioDebugMode::RandomSpots, LeftTitle, LeftOutput, FLinearColor::Gray, true);
	SetConstantOutput(EAudioDebugMode::RandomSpots, RightTitle, RightOutput, FLinearColor::Gray, false);
}

void DebugLoadedBanks(TArray<FString> LoadedBanks, bool bForceUpdate)
{
	if (CVar_AudioDebugModeLoadedBanksEnabled.GetInt() == 0 && !bForceUpdate)
		return;

	FString LeftOutput;
	const FString LeftTitle = "Loaded Banks";
	LeftOutput += "<Red> "+ LeftTitle + " </> "+ NewLine;

	for (auto Bank: LoadedBanks)
	{
		LeftOutput += Tab + WrapWithColor(Bank, "<Green>");
	}

	SetConstantOutput(EAudioDebugMode::LoadedBanks, LeftTitle, LeftOutput, FLinearColor::Gray, true);
}

// HELPERS

FString WrapWithColor(FString InOutput, FString Color)
{
	return Color + InOutput + "</>" + NewLine;
}

#endif