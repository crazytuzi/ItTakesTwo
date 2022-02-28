import Cake.DebugMenus.Audio.AudioDebugStatics;
import Cake.DebugMenus.Audio.AudioDebugNetworkCapability;

#if TEST
import bool IsDebugEnabled(EAudioDebugMode DebugMode) from "Cake.DebugMenus.Audio.AudioDebugManager";
import void SetConstantOutput(EAudioDebugMode DebugMode, FString Key, FString Output, FLinearColor Color, bool bIsMay) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

class FNetworkAudioActor
{
	UHazeAkComponent Comp;
	AActor Owner;
}

class FNetworkRTPC
{
	FString RtpcName;
	float Value;
	float Timestamp;

	bool Exists; 
};

class FNetworkActorTracker
{
	UHazeAkComponent Local;
	UHazeAkComponent Remote;
	AActor LocalOwner;
	AActor RemoteOwner;
	TMap<FString, FNetworkEventTracker> TrackedEvents;
	TArray<FString> EventsToRemove;

	TMap<int, FNetworkRTPC> RTPCsNeverSetOnRemote;
};

struct FNetworkEventInstance 
{
	FHazeAudioEventInstance Instance;
	float Timestamp;
	int Count;
	bool Exists; 
};

class FNetworkEventTracker
{
	FNetworkEventInstance Local;
	FNetworkEventInstance Remote;

	float TimerUntilRemoval;
	bool bAnyExists;
};

struct FNetworkMissingEvent
{
	EHazeAudioPostEventType TypeOfPostEvent;
	float Timestamp;
	FString UniqueId; 
};

class UAudioDebugNetworkSimulationManager : UHazeAudioNetworkDebugManager
{
	TMap<FString, FNetworkActorTracker> TrackedActors;
	TMap<FString, FNetworkActorTracker> TrackedFireForget;
	float LastRealTime;

	TArray<FNetworkMissingEvent> NeverPlayedOnRemote;
	TArray<FNetworkMissingEvent> NeverPlayedOnLocal;

	const float EventTrackerMaxDuration = 2.5;
	const float RemoveNeverPlayedDuration = 15;

	UHazeAudioNetworkDebugManager Other;
	bool bNotAdded = true;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
 	}

	UFUNCTION(BlueprintOverride)
	bool IsNetworkDebugActive()
	{
		#if TEST
		return IsDebugEnabled(EAudioDebugMode::NetworkCompare);
		#else
		return false;
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void NetworkAudioOutputChanged()
	{
		// Listeners from both worlds (i.e both simulations)
		TArray<UHazeListenerComponent> Listeners;
		UHazeAkComponent::GetAllHazeListeners(Listeners);

		for (UHazeListenerComponent Listener : Listeners)
		{
			if (Listener.World != World)
				continue;

			if (!UHazeAudioNetworkDebugManager::IsNetworkedSideActive(Listener))
			{
				if (Listener.Owner.HasActorBegunPlay())
					Listener.RemoveAsDefaultListener();
			}
			else {
				if (Listener.Owner.HasActorBegunPlay())
					Listener.AddAsDefaultListener();
			}
		}
	}

	bool FilterOutEvent(FHazeAudioEventInstance Event)
	{
		return (Event.PostEventType != EHazeAudioPostEventType::Gameplay &&
				(Event.PostEventType & (EHazeAudioPostEventType::Foghorn | EHazeAudioPostEventType::UIEvent)) == 0);
	}

	UHazeAudioNetworkDebugManager GetOtherInstance()
	{
		if (Other == nullptr)
		{
			TArray<UHazeListenerComponent> Listeners;
			UHazeAkComponent::GetAllHazeListeners(Listeners);
			for (UHazeListenerComponent Listener : Listeners)
			{
				if (Listener.World != World)
					Other = UHazeAudioNetworkDebugManager::GetStaticInstance(Listener);

				if (Other != nullptr)
					break;
			}
		}

		return Other;
	}

	UFUNCTION(BlueprintOverride)
	void AddFireForgetPostEvent(UObject Object, FHazeAudioEventInstance Instance)
	{
		if (FilterOutEvent(Instance))
			return;

		bool bControl = World == Object.World;

		FString EventName = Instance.EventName;
		FNetworkActorTracker FireForgetTracker;
		if (!TrackedFireForget.Find(EventName, FireForgetTracker))
		{
			FireForgetTracker = FNetworkActorTracker();
			TrackedFireForget.Add(EventName, FireForgetTracker);
		}

		TMap<FString, FNetworkEventTracker>& TrackedEvents = FireForgetTracker.TrackedEvents;
		FNetworkEventTracker EventTracker;
		if (!TrackedEvents.Find(EventName, EventTracker))
		{
			EventTracker = FNetworkEventTracker();
			TrackedEvents.Add(EventName, EventTracker);
		}

		float CurrentTime = Time::GetRealTimeSeconds();
		EventTracker.TimerUntilRemoval = CurrentTime + EventTrackerMaxDuration;

		FNetworkEventInstance& NetworkInstance = bControl ? EventTracker.Local : EventTracker.Remote;
		NetworkInstance.Timestamp = FMath::Max(0.1f, CurrentTime);
		NetworkInstance.Instance = Instance;
		NetworkInstance.Exists = true;
		++NetworkInstance.Count;
		
		if (World == Object.World && GetOtherInstance() != nullptr)
		{
			Other.AddFireForgetPostEvent(Object, Instance);
		}
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFireForgetPostEvent(UObject Object, FHazeAudioEventInstance Instance)
	{
		// if (FilterOutEvent(Instance))
		// 	return;

		// bool bControl = World == Object.World;
		// if (World == Object.World && GetOtherInstance() != nullptr)
		// {
		// 	Other.RemoveFireForgetPostEvent(Object, Instance);
		// }

		// FString EventName = Instance.EventName;
		// FNetworkActorTracker FireForgetTracker;
		// if (!TrackedFireForget.Find(EventName, FireForgetTracker))
		// {
		// 	FireForgetTracker = FNetworkActorTracker();
		// 	TrackedFireForget.Add(EventName, FireForgetTracker);
		// }

		// TMap<FString, FNetworkEventTracker>& TrackedEvents = FireForgetTracker.TrackedEvents;
		// FNetworkEventTracker EventTracker;
		// if (!TrackedEvents.Find(EventName, EventTracker))
		// {
		// 	EventTracker = FNetworkEventTracker();
		// 	TrackedEvents.Add(EventName, EventTracker);
		// }

		// if (bControl)
		// 	--EventTracker.LocalCount;
		// else
		// 	--EventTracker.RemoteCount;

	}

	UFUNCTION(BlueprintOverride)
	void AddPostEvent(UObject Object, FHazeAudioEventInstance Instance)
	{
		if (FilterOutEvent(Instance))
			return;

		bool bControl = World == Object.World;
		UHazeAkComponent Comp = Cast<UHazeAkComponent>(Object);
		auto Owner = Comp.Owner;
		FString OwnerName = Owner.Name + "_" + Comp.Name;

		FNetworkActorTracker ActorTracker;
		if (!TrackedActors.Find(OwnerName, ActorTracker))
		{
			ActorTracker = FNetworkActorTracker();
			TrackedActors.Add(OwnerName, ActorTracker);
		}

		if (bControl) 
		{
			ActorTracker.Local = Comp;
			ActorTracker.LocalOwner = Owner;
		}
		else
		{
			ActorTracker.Remote = Comp;
			ActorTracker.RemoteOwner = Owner;
		}

		TMap<FString, FNetworkEventTracker>& TrackedEvents = ActorTracker.TrackedEvents;

		FNetworkEventTracker EventTracker;
		if (!TrackedEvents.Find(Instance.EventName, EventTracker))
		{
			EventTracker = FNetworkEventTracker();
			TrackedEvents.Add(Instance.EventName, EventTracker);
		}

		float CurrentTime = Time::GetRealTimeSeconds();
		EventTracker.TimerUntilRemoval = CurrentTime + EventTrackerMaxDuration;

		FNetworkEventInstance& NetworkInstance = bControl ? EventTracker.Local : EventTracker.Remote;
		NetworkInstance.Timestamp = FMath::Max(0.1f, CurrentTime);
		NetworkInstance.Instance = Instance;
		NetworkInstance.Exists = true;
		++NetworkInstance.Count;

		if (World == Object.World && GetOtherInstance() != nullptr)
		{
			Other.AddPostEvent(Object, Instance);
		}
	}

	UFUNCTION(BlueprintOverride)
	void RemovePostEvent(UObject Object, FHazeAudioEventInstance Instance)
	{
		// if (FilterOutEvent(Instance))	
		// 	return;

		// UHazeAkComponent Comp = Cast<UHazeAkComponent>(Object);
		// if (Comp == nullptr || Comp.Owner == nullptr)
		// 	return;

		// bool bControl = World == Object.World;
		// if (World == Object.World && GetOtherInstance() != nullptr)
		// {
		// 	Other.RemovePostEvent(Object, Instance);
		// }

		// auto Owner = Comp.Owner;
		// FString OwnerName = Owner.Name + "_" + Comp.Name;

		// FNetworkActorTracker ActorTracker;
		// if (!TrackedActors.Find(OwnerName, ActorTracker))
		// {
		// 	ActorTracker = FNetworkActorTracker();
		// 	TrackedActors.Add(OwnerName, ActorTracker);
		// }

		// TMap<FString, FNetworkEventTracker>& TrackedEvents = ActorTracker.TrackedEvents;
		// FNetworkEventTracker EventTracker;	
		// if (!TrackedEvents.Find(Instance.EventName, EventTracker))
		// {
		// 	EventTracker = FNetworkEventTracker();
		// 	TrackedEvents.Add(Instance.EventName, EventTracker);
		// }

		// if (bControl)
		// 	--EventTracker.LocalCount;
		// else
		// 	--EventTracker.RemoteCount;
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{

	}


	void AddMissingEvent(FNetworkEventTracker& TrackedEvent, FString EventName)
	{
		float CurrentTime = Time::GetRealTimeSeconds();

		if (TrackedEvent.Remote.Count == 0)
		{
			FNetworkMissingEvent MissingEvent;
			MissingEvent.UniqueId = EventName;
			MissingEvent.Timestamp = CurrentTime + RemoveNeverPlayedDuration;
			MissingEvent.TypeOfPostEvent = EHazeAudioPostEventType(TrackedEvent.Remote.Instance.PostEventType);
			NeverPlayedOnRemote.Add(MissingEvent);
		}

		if (TrackedEvent.Local.Count == 0)
		{
			FNetworkMissingEvent MissingEvent;
			MissingEvent.UniqueId = EventName;
			MissingEvent.Timestamp = CurrentTime + RemoveNeverPlayedDuration;
			MissingEvent.TypeOfPostEvent = EHazeAudioPostEventType(TrackedEvent.Local.Instance.PostEventType);
			NeverPlayedOnLocal.Add(MissingEvent);
		}
	}
	
	void AddOutput(FNetworkEventTracker& TrackedEvent, FString EventName, FString& LeftOutput, FString& RightOutput)
	{
		FString EventOutput;
		if (TrackedEvent.Local.Count != 0 && TrackedEvent.Remote.Count != 0)
		{
			RightOutput += WrapWithColor(EventName, "<Red>");
			EventOutput += "TimeDiff: " + (TrackedEvent.Local.Timestamp - TrackedEvent.Remote.Timestamp);
			RightOutput += "\t" + WrapWithColor(EventOutput, "<Green>");
		}else {
			LeftOutput += WrapWithColor(EventName, "<Red>");
			bool bOnlyLocal = TrackedEvent.Local.Timestamp != 0 && TrackedEvent.Remote.Timestamp == 0;
			EventOutput += "Local Count: " + TrackedEvent.Local.Count;
			EventOutput += " & Remote Count: " + TrackedEvent.Remote.Count;
			EventOutput += " / StartTime: " + (bOnlyLocal ? TrackedEvent.Local.Timestamp : TrackedEvent.Remote.Timestamp);

			FString Color = bOnlyLocal ? "<Red>" : "<Yellow>"; 
			LeftOutput += "\t " +WrapWithColor(EventOutput, Color);
		}
	}

	void CompareRTPCsSet(FNetworkActorTracker& Tracker, const FString& NameKey, FString& LeftOutput, FString& RightOutput)
	{
		TMap<int, float> ControlRtpcs;
		TMap<int, float> RemoteRtpcs;

		auto Control = Tracker.Local;
		auto Remote = Tracker.Remote;

		if (Control != nullptr)
			Control.GetRtpcsSetByID(ControlRtpcs);
		if (Remote != nullptr)
			Remote.GetRtpcsSetByID(RemoteRtpcs);
		
		FString Diffs = "";
		FString Same = "";

		for (auto& Pair : Tracker.RTPCsNeverSetOnRemote)
		{
			Pair.Value.Exists = false;
		}

		for (auto& Pair: ControlRtpcs)
		{
			FString RtpcName;
			if (!Audio::FindStringFromID(Pair.Key, RtpcName))
			{
				RtpcName = "" + Pair.Key;
			}
			
			// TODO - Add filtering from debug menu

			// This just makes the debug bloated, if the position is so off, it should be visable.
			if (RtpcName == "Rtpc_Globals_Distance" || RtpcName == "Rtpc_Globals_Combined_Azimuth")
				continue;

			float RemoteValue = 0;
			if (RemoteRtpcs.Find(Pair.Key, RemoteValue))
			{
				Tracker.RTPCsNeverSetOnRemote.Remove(Pair.Key);

				if (!FMath::IsNearlyEqual(Pair.Value, RemoteValue, 0.001f))
					Diffs += WrapWithColor("\t" + NameKey +" / " + RtpcName + ", Control: " + Pair.Value + ", Remote: " + RemoteValue, "<Yellow>");
				else
					Same += WrapWithColor("\t" + NameKey +" / "+ RtpcName + ", Control: " + Pair.Value + ", Remote: " + RemoteValue, "<Green>");
			}
			else
			{
				Diffs += WrapWithColor("\t" + NameKey + " / " + RtpcName + ", Control: "+ Pair.Value, "<Red>");

				FNetworkRTPC RTPC;
				if (!Tracker.RTPCsNeverSetOnRemote.Find(Pair.Key, RTPC))
				{
					RTPC = FNetworkRTPC();
					RTPC.RtpcName = RtpcName;
					Tracker.RTPCsNeverSetOnRemote.Add(Pair.Key, RTPC);
				}
				RTPC.Value = Pair.Value;
				RTPC.Timestamp = Time::GetRealTimeSeconds() + 1.f;
				RTPC.Exists = true;
			}
		}

		float CurrentTime = Time::GetRealTimeSeconds();
		for (auto& Pair : Tracker.RTPCsNeverSetOnRemote)
		{
			if (!Pair.Value.Exists && Pair.Value.Timestamp < CurrentTime)
			{
				Log("[RTPC] Never set on remote: " + Pair.Value.RtpcName + ", Value: " + Pair.Value.Value);
			}
		}

		if (!Diffs.IsEmpty())
		{
			// LeftOutput += WrapWithColor(NameKey, "<Orange>");
			LeftOutput += Diffs;
		}
		if (!Same.IsEmpty())
		{
			// RightOutput += WrapWithColor(NameKey, "<Red>");
			RightOutput += Same;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurrentTime = Time::GetRealTimeSeconds();
		FString LeftOutput = "<Blue> "+ "NETWORK COMPARE - DIFF" + " </> \n";
		FString RightOutput = "<Blue> "+ "NETWORK COMPARE - SAME" + " </> \n";
		TArray<FString> TrackedToRemove;

		FString LeftRTPCOutput = WrapWithColor("-- RTPCS COMPARE / DIFF --", "<Red>");
		FString RightRTPCOutput = WrapWithColor("-- RTPCS COMPARE / SAME --", "<Blue>");

		for (auto KeyValueActorPair: TrackedActors)
		{
			auto& TrackedEvents = KeyValueActorPair.Value.TrackedEvents;
			auto& EventsToRemove = KeyValueActorPair.Value.EventsToRemove;
			FNetworkActorTracker& Tracker = KeyValueActorPair.Value;

			if (Tracker.Local == nullptr && Tracker.Remote == nullptr)
			{
				TrackedToRemove.Add(KeyValueActorPair.Key);
				continue;
			}

			if (Tracker.Local != nullptr)
			{
				for(FHazeAudioEventInstance Instance: Tracker.Local.ActiveEventInstances)
				{
					FNetworkEventTracker EventTracker;
					if (TrackedEvents.Find(Instance.EventName, EventTracker))
					{
						EventTracker.bAnyExists = true;
					}
				}
			}

			if (Tracker.Remote != nullptr)
			{
				for(FHazeAudioEventInstance Instance: Tracker.Remote.ActiveEventInstances)
				{
					FNetworkEventTracker EventTracker;
					if (TrackedEvents.Find(Instance.EventName, EventTracker))
					{
						EventTracker.bAnyExists = true;
					}
				}
			}

			for (auto KeyValuePair: TrackedEvents)
			{
				FNetworkEventTracker& TrackedEvent = KeyValuePair.Value;

				if (!TrackedEvent.bAnyExists)
				{
					if ((TrackedEvent.Remote.Count != 0 && 
						TrackedEvent.Local.Count != 0))
					{
						EventsToRemove.Add(KeyValuePair.Key);
						continue;
					}

					// Give it time to sync. 
					if (TrackedEvent.TimerUntilRemoval <= CurrentTime)
					{
						AddMissingEvent(TrackedEvent, KeyValuePair.Key);
						EventsToRemove.Add(KeyValuePair.Key);
					}
				}

				TrackedEvent.bAnyExists = false;
				AddOutput(TrackedEvent, KeyValuePair.Key, LeftOutput, RightOutput);
			}

			CompareRTPCsSet(Tracker, KeyValueActorPair.Key, LeftRTPCOutput, RightRTPCOutput);
		}

		LeftOutput += LeftRTPCOutput;
		RightOutput += RightRTPCOutput;

		LeftOutput += "<Blue> "+ "NETWORK COMPARE FIRE&FORGET - DIFF" + " </> \n";
		RightOutput += "<Blue> "+ "NETWORK COMPARE FIRE&FORGET - SAME" + " </> \n";

		TArray<FString> TrackedFireForgetToRemove;
		for (auto KeyValueActorPair: TrackedFireForget)
		{
			auto& TrackedEvents = KeyValueActorPair.Value.TrackedEvents;
			auto& EventsToRemove = KeyValueActorPair.Value.EventsToRemove;
			FNetworkActorTracker& Tracker = KeyValueActorPair.Value;

			if (Tracker.Local == nullptr && Tracker.Remote == nullptr)
			{
				TrackedFireForgetToRemove.Add(KeyValueActorPair.Key);
				continue;
			}

			if (Tracker.Local != nullptr)
			{
				for(FHazeAudioEventInstance Instance: Tracker.Local.ActiveEventInstances)
				{
					FNetworkEventTracker EventTracker;
					if (TrackedEvents.Find(Instance.EventName, EventTracker))
					{
						EventTracker.bAnyExists = true;
					}
				}
			}

			if (Tracker.Remote != nullptr)
			{
				for(FHazeAudioEventInstance Instance: Tracker.Remote.ActiveEventInstances)
				{
					FNetworkEventTracker EventTracker;
					if (TrackedEvents.Find(Instance.EventName, EventTracker))
					{
						EventTracker.bAnyExists = true;
					}
				}
			}

			for (auto KeyValuePair: TrackedEvents)
			{
				FNetworkEventTracker& TrackedEvent = KeyValuePair.Value;
				if (!TrackedEvent.bAnyExists)
				{
					if ((TrackedEvent.Local.Count != 0 && 
						 TrackedEvent.Remote.Count != 0))
					{
						EventsToRemove.Add(KeyValuePair.Key);
						continue;
					}

					// Give it time to sync. 
					if (TrackedEvent.TimerUntilRemoval < CurrentTime)
					{
						AddMissingEvent(TrackedEvent, KeyValuePair.Key);
						EventsToRemove.Add(KeyValuePair.Key);
					}
				}
				TrackedEvent.bAnyExists = false;

				AddOutput(TrackedEvent, KeyValuePair.Key, LeftOutput, RightOutput);
			}
		}

		if (NeverPlayedOnRemote.Num() > 0) 
		{
			LeftOutput += "<Blue> "+ "NETWORK COMPARE - NEVER PLAYED REMOTE" + " </> \n";
			for (int i = NeverPlayedOnRemote.Num()-1; i >= 0; --i)
			{
				if (CurrentTime >= NeverPlayedOnRemote[i].Timestamp)
				{
					Log("NeverRemote: " + NeverPlayedOnRemote[i].UniqueId + ", Type: " + NeverPlayedOnRemote[i].TypeOfPostEvent);
					NeverPlayedOnRemote.RemoveAtSwap(i);
					continue;
				}

				LeftOutput += WrapWithColor(NeverPlayedOnRemote[i].UniqueId + ", Type: " + NeverPlayedOnRemote[i].TypeOfPostEvent, "<Red>");
			}
		}

		if (NeverPlayedOnRemote.Num() > 0) 
		{
			LeftOutput += "<Blue> "+ "NETWORK COMPARE - NEVER PLAYED LOCAL" + " </> \n";
			for (int i = NeverPlayedOnLocal.Num()-1; i >= 0; --i)
			{
				if (CurrentTime >= NeverPlayedOnLocal[i].Timestamp)
				{
					Log("NeverLocal: " + NeverPlayedOnLocal[i].UniqueId + ", Type: " + NeverPlayedOnLocal[i].TypeOfPostEvent);
					NeverPlayedOnLocal.RemoveAtSwap(i);
					continue;
				}

				LeftOutput += WrapWithColor(NeverPlayedOnLocal[i].UniqueId + ", Type: " + NeverPlayedOnLocal[i].TypeOfPostEvent, "<Yellow>");
			}
		}

		for (FString Key: TrackedToRemove)
		{
			TrackedActors.Remove(Key);
		}

		for (FString Key: TrackedFireForgetToRemove)
		{
			TrackedFireForget.Remove(Key);
		}

		for (auto KeyValueActorPair: TrackedActors)
		{
			auto& TrackedEvents = KeyValueActorPair.Value.TrackedEvents;
			auto& EventsToRemove = KeyValueActorPair.Value.EventsToRemove;
			for (auto Key: EventsToRemove)
			{
				TrackedEvents.Remove(Key);
			}
			EventsToRemove.Reset();
		}

		for (auto KeyValueActorPair: TrackedFireForget)
		{
			auto& TrackedEvents = KeyValueActorPair.Value.TrackedEvents;
			auto& EventsToRemove = KeyValueActorPair.Value.EventsToRemove;
			for (auto Key: EventsToRemove)
			{
				TrackedEvents.Remove(Key);
			}
			EventsToRemove.Reset();
		}

		#if TEST
		SetConstantOutput(EAudioDebugMode::NetworkCompare, "Network Diff", LeftOutput, FLinearColor::LucBlue, World.HasControl());
		SetConstantOutput(EAudioDebugMode::NetworkCompare, "Network Same", RightOutput, FLinearColor::LucBlue, !World.HasControl());
		#endif
	}

	FString WrapWithColor(FString InOutput, FString Color)
	{
		return Color + InOutput + "</> \n";
	}
}
