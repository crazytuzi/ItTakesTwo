import Peanuts.Audio.AmbientZone.AmbientZone;
import Peanuts.Audio.AudioStatics;

struct AmbientZones
{
	TArray<AAmbientZone> AmbientZones;
}

class UAmbientZoneManager : UHazeSingleton
{
	TArray<AmbientZones> ActiveAmbientZones;

	TMap<UHazeListenerComponent, float> MaxRelevance;
	TMap<UHazeListenerComponent, float> ConsumedRelevance;
	TSet<UHazeAkComponent> ProcessedComponents;

	void RegisterAmbientZone(AAmbientZone AmbientZone)
	{
		uint32 Priority = AmbientZone.Priority;
		if (Priority >= uint32(ActiveAmbientZones.Num()))
		{
			ActiveAmbientZones.SetNum(Priority + 1);
		}

		ActiveAmbientZones[Priority].AmbientZones.AddUnique(AmbientZone);	
	}

	void UnregisterAmbientZone(AAmbientZone AmbientZone)
	{
		int Priority = AmbientZone.Priority;

		if(Priority < ActiveAmbientZones.Num())
		{
			ActiveAmbientZones[Priority].AmbientZones.Remove(AmbientZone);
			if (AmbientZone.HasActorBegunPlay())
				AmbientZone.SetRtpcValue(0.f);				
		}

		for(UHazeAkComponent& HazeAkComp : AmbientZone.AkCompsInAttenuationRange)
		{
			if(HazeAkComp == nullptr)
				continue;

			if(AmbientZone.EnsureReverbReady())
			{			
				UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent(bCreateIfNeeded = false);
				if (ReverbComp != nullptr)
					ReverbComp.RemoveObjectAuxSend(AmbientZone, AmbientZone.ZoneAsset.ReverbBus);					
			}
		}
	}

	float GetLowerPrioReverbSendValue(AAmbientZone Zone, UHazeAkComponent HazeAkComp)
	{
		int32 ZonePriority = Zone.ZonePriority;
		float SendReductionValue = 0;

		for(const FAmbientZoneOverlap& Overlap : HazeAkComp.AmbientZoneOverlaps)
		{
			AHazeAmbientZone AmbientZone = Overlap.AmbientZone;
			if(AmbientZone == nullptr || !AmbientZone.EnsureReverbReady() || AmbientZone == Zone)
				continue;

			if(AmbientZone.ZonePriority < ZonePriority)
				continue;

			SendReductionValue += AmbientZone.GetWantedReverbSendForObject(HazeAkComp);
		}

		return FMath::Clamp(SendReductionValue, 0.f, 1.f);
	}

	void ResetGlobalScope()
	{
		ConsumedRelevance.Reset();
		ProcessedComponents.Reset();
	}

	void ResetMaxRelevanceCalculation()
	{
		MaxRelevance.Reset();
	}

	void ProcessAmbientZone(AAmbientZone AmbientZone, UHazeAudioManager AudioManager)
	{
		if (AmbientZone == nullptr || !AudioManager.IsAmbientZonesLevelActive(AmbientZone))
			return;

		float FinalRelevance = 0.f;		
		// Process relevance, affected by previous ambient zones
		for (UHazeListenerComponent Listener : AmbientZone.ListenersInAttenuationRange)
		{
			if (!ConsumedRelevance.Contains(Listener))
			{
				ConsumedRelevance.Add(Listener, 0.f);
			}

			float Relevance = FMath::Min(FMath::Clamp(1.f - ConsumedRelevance.FindOrAdd(Listener), 0.f, 1.f), AmbientZone.GetWantedRelevanceForObject(Listener));
			FinalRelevance = FMath::Max(Relevance, FinalRelevance);

			if (!MaxRelevance.Contains(Listener))
			{
				MaxRelevance.Add(Listener, 0.f);
			}

			float& MaxRel = MaxRelevance.FindOrAdd(Listener);
			MaxRel = FMath::Max(MaxRel, Relevance);
		}
		AmbientZone.SetRtpcValue(FinalRelevance);

		if(!AmbientZone.EnsureReverbReady())
			return;

		// Setting Reverb Sends	
		for(UHazeAkComponent HazeAkComp : AmbientZone.AkCompsInAttenuationRange)
		{
			if(HazeAkComp == nullptr || 
				HazeAkComp == AmbientZone.AmbEventComp ||
				// Ignore HazeAkComp's which all zones aren't loaded in yet.
				// This is so the EAudioHazeAkComponentFlag::QueuedForReverbProcessing isn't removed yet.
				!AudioManager.IsHazeAkComponentsLevelActive(HazeAkComp))
				continue;

			// Flag that is only changed when component changes position
			if (!HazeAkComp.HasAudioFlags(EAudioHazeAkComponentFlag::QueuedForReverbProcessing, true) &&
				!ProcessedComponents.Contains(HazeAkComp))
				continue;

			ProcessedComponents.Add(HazeAkComp);
			
			bool bHasAmbientZonesAnyListeners = AmbientZone.ListenersInAttenuationRange.Num() > 0;
			// No need to check for listeners if ambientzone has any. 
			// ReverbComponent will make a listener check if needed.
			bool bHasComponentAnyListeners = bHasAmbientZonesAnyListeners || HazeAkComp.AnyListenerInRange();
			if(!bHasAmbientZonesAnyListeners && !bHasComponentAnyListeners)
				continue;
				
			// If the AmbientZone doesn't have any listeners the tick is disabled, i.e doesn't update it's emitters distance value
			// Used in GetWantedRelevanceForObject
			if (!bHasAmbientZonesAnyListeners && bHasComponentAnyListeners)
			{
				AmbientZone.UpdateEmitter(HazeAkComp, true);
			}

			AAmbientZone PrioritizedZone = Cast<AAmbientZone>(HazeAkComp.GetPrioReverbZone());																									
			// Calculating reverb send values based on current zones per HazeAkComp														
					
			float SendLevelMultiplier = AmbientZone.ZoneAsset.SendLevel;						
			float ObjectSendLevel = AmbientZone.GetWantedRelevanceForObject(HazeAkComp);

			float FinalSendValue;

			if(AmbientZone != PrioritizedZone && PrioritizedZone != nullptr)
			{
				if(AmbientZone.ZoneAsset.ReverbBus == PrioritizedZone.ZoneAsset.ReverbBus)
					continue;

				float AttenuatedReverSendValue = GetLowerPrioReverbSendValue(AmbientZone, HazeAkComp);
				FinalSendValue = FMath::Clamp((ObjectSendLevel * SendLevelMultiplier) - AttenuatedReverSendValue, 0.f, 1.f);														
			}
			else
			{
				FinalSendValue	= ObjectSendLevel * SendLevelMultiplier;							
			}							

			UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent(false);
			if(ReverbComp != nullptr)
			{
				UPlayerHazeAkComponent PlayerAkComp = Cast<UPlayerHazeAkComponent>(HazeAkComp);	
				if(PlayerAkComp == nullptr)
				{								
					ReverbComp.UpdateObjectAuxSendValue(AmbientZone.ZoneAsset.ReverbBus, FinalSendValue);															
				}	
				else
				{								
					UHazeListenerComponent PlayerListener = PlayerAkComp.GetPlayerListener();								
					ReverbComp.UpdateObjectAuxSendValue(AmbientZone.ZoneAsset.ReverbBus, FinalSendValue, PlayerListener);															
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActiveAmbientZones.Num() <= 0)
			return;

		ResetGlobalScope();
		UHazeAudioManager AudioManager = GetAudioManager();

		for (int i = ActiveAmbientZones.Num() - 1; i > 0; i--)
		{
			// Reset for each priority level, i.e "i"
			ResetMaxRelevanceCalculation();
		
			for (AAmbientZone AmbientZone : ActiveAmbientZones[i].AmbientZones)
			{
				ProcessAmbientZone(AmbientZone, AudioManager);
			}
			
			// This affects the next priority zones
			for (auto& Element : MaxRelevance)
			{
				ConsumedRelevance.FindOrAdd(Element.Key) += Element.Value;
			}
		}

		// Settings for Zone with Prio 0, ignored in the above for loop.
		for (AAmbientZone AmbientZone : ActiveAmbientZones[0].AmbientZones)
		{
			float RtpcValue = AmbientZone.GetZoneUnmanagedRtpcValue();
			if (AmbientZone.AmbEventComp.IsGameObjectRegisteredWithWwise())
				AmbientZone.SetRtpcValue(RtpcValue);
		}
	}
}