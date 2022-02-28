import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Peanuts.Audio.HazeAudioManager.HazeAudioManager;
import Vino.Characters.PlayerCharacter;
import Peanuts.Audio.Reflection.ReflectionTraceCapability;
import Cake.DebugMenus.Audio.AudioDebugStatics;

event void OnTraceUpdate(int Index, FHitResult& HitResult);
event void OnGetTraceData(int Index, FTraceReflectionData& Value);

#if TEST
import bool IsDebugEnabled(EAudioDebugMode DebugMode) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

struct FTraceSubscriptionData
{
	//Events
	OnTraceUpdate OnUpdate;
	OnGetTraceData OnGetData;

	UObject Subscriber;
	int NumOfTraces;
	//Only internally used in manager
	int InternalIndex;
}

struct FAsyncRaycastSubscriberInfo
{
	int SubscriberIndex;
	int TraceId;

	bool bSubscriberRemoved = false;
};

class UReflectionTraceManager : UActorComponent
{
	UHazeAsyncTraceComponent AsyncTrace;

	TArray<FTraceSubscriptionData> Subscribers;
	FString TraceIdBase = "ReflectionTrace_";
	TMap<FName, FAsyncRaycastSubscriberInfo> ActiveAsyncRaycasts;
	uint FrameCountOnAsyncCall = 0;
	TArray<AActor> ActorsToIgnore;

	// Absolute max
	float MaxDistanceInMeters = 350. * 100.;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Setup();
	}

	void Setup() 
	{
		ActorsToIgnore.Reset();
		auto Players = Game::GetPlayers();
		for (auto Player: Players) 
		{
			ActorsToIgnore.Add(Player);
		}

		ActiveAsyncRaycasts.Reset();
		AsyncTrace = UHazeAsyncTraceComponent::GetOrCreate(Owner);
	}

	void Subscribe(UReflectionTraceCapability TraceCapability)
	{
		for (int i = Subscribers.Num() -1 ; i >= 0; --i)
		{
			if (Subscribers[i].Subscriber == TraceCapability) 
			{
				devEnsure(false, "New subscriber ["+ TraceCapability +"] is already a subscriber, ignored!");
				return;
			}
		}

		FTraceSubscriptionData Data;
		Data.Subscriber = TraceCapability;
		Data.OnUpdate.AddUFunction(TraceCapability, n"OnTraceUpdate");
		Data.OnGetData.AddUFunction(TraceCapability, n"OnGetTraceData");
		Data.NumOfTraces = TraceCapability.NumOfTracesAndDirections();
		Data.InternalIndex = 0;

		Subscribers.Add(Data);

		if (Subscribers.Num() == 1)
			Reset::RegisterPersistentComponent(this);
	}

	void Unsubscribe(UReflectionTraceCapability TraceCapability)
	{
		for (int i = Subscribers.Num() -1 ; i >= 0; --i)
		{
			if (Subscribers[i].Subscriber == TraceCapability) 
			{
				Subscribers.RemoveAt(i);
				RemoveSubscriberFromActiveRaycasts(i);
				// if (ActiveSubscriberIndex >= Subscribers.Num())
				// 	GotoNext();
				break;
			}
		}

		if (Subscribers.Num() == 0)
		{
			Reset::UnregisterPersistentComponent(this);
		}
	}

	void RemoveSubscriberFromActiveRaycasts(int Index)
	{
		for	(auto& KeyValuePair: ActiveAsyncRaycasts)
		{
			FAsyncRaycastSubscriberInfo& Info = KeyValuePair.Value;

			if (Info.SubscriberIndex == Index)
			{
				Info.bSubscriberRemoved = true;
			}
			else if (Info.SubscriberIndex > Index)
			{
				--Info.SubscriberIndex;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Subscribers.Num() == 0)
		{
			return;
		}

		UpdateTrace();
	}

	void UpdateTrace() 
	{
		// Unsure if this is only in editor or not. Keeping as is.
		if (AsyncTrace == nullptr)
		{
			Setup();
		}

		// Waiting for all responses.
		if (ActiveAsyncRaycasts.Num() > 0 || FrameCountOnAsyncCall >= Time::GetFrameNumber())
		{
			return;
		}
		FrameCountOnAsyncCall = Time::GetFrameNumber(); 

		FHazeTraceParams TraceSettings;
		TraceSettings.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceSettings.IgnoreActors(ActorsToIgnore);
		TraceSettings.SetToLineTrace();
		
		FTraceReflectionData TraceData;
		int Count = 0;
		for (int Index = 0; Index < Subscribers.Num(); ++Index)
		{
			FTraceSubscriptionData& Subscriber = Subscribers[Index];
			for (int InternalIndex = 0; InternalIndex < Subscriber.NumOfTraces; ++InternalIndex)
			{
				Subscriber.OnGetData.Broadcast(InternalIndex, TraceData);
				float MaxDistance = FMath::Min(TraceData.TraceLength, MaxDistanceInMeters);

				TraceSettings.From = TraceData.Location;
				TraceSettings.To = TraceData.Location + TraceData.Direction * MaxDistance;
				
				FName AsyncTraceId = FName(TraceIdBase + Count);
				++Count;

				FAsyncRaycastSubscriberInfo Info;
				Info.SubscriberIndex = Index;
				Info.TraceId = InternalIndex;
				ActiveAsyncRaycasts.Add(AsyncTraceId, Info);

				auto TraceDelegate = FHazeAsyncTraceComponentCompleteDelegate(this, n"TraceDone");
				AsyncTrace.TraceSingle(TraceSettings, this, AsyncTraceId, TraceDelegate);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void TraceDone(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		FHitResult HitResult = Obstructions.Num() > 0 ? Obstructions[0] : FHitResult();
		FAsyncRaycastSubscriberInfo Info;
		if (!ActiveAsyncRaycasts.Find(TraceId, Info)) 
		{
			PrintToScreen("[ReflectionManager] Couldn't find subscriber for: " + TraceId);
			return;
		}
		
		ActiveAsyncRaycasts.Remove(TraceId);
		if (Info.bSubscriberRemoved)
		{
			PrintToScreen("[ReflectionManager] Subscriber for trace: " + TraceId + " has been removed");
			return;
		}

		FTraceSubscriptionData& Subscriber = Subscribers[Info.SubscriberIndex];
		Subscriber.OnUpdate.Broadcast(Info.TraceId, HitResult);

		#if TEST
		if (IsDebugEnabled(EAudioDebugMode::Delay))
		{
			if (HitResult.bBlockingHit)
				System::DrawDebugLine(HitResult.TraceStart, HitResult.TraceEnd, FLinearColor::Green, 0.25f, 1.f);
			// If no hit was done, the hit result is empty
			// else
				// System::DrawDebugLine(HitResult.TraceStart, HitResult.TraceEnd, FLinearColor::Red, 0.25f, 1.f);
		}
		#endif
	}
}