import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.AmbientZone.AmbientZone;

class UZoneLinkEffect : UHazeAudioEffect
{	
	AAmbientZone PrioritizedZone;
	float LastRtpcValue;

	bool bFollowRelevance = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SetZoneLinkRtpc(0.f);
		LastRtpcValue = 0.f;
		SetEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemove()
	{
		// So it doesn't, for some reason, not set the rtpc when it's enabled again.
		LastRtpcValue = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void SetupShouldUseZonePriority(bool bLinkToPrio)
	{			
		SetFollowZoneRelevance(bLinkToPrio);		
	}

	UFUNCTION(BlueprintCallable)
	void SetFollowZoneRelevance(bool bShouldFollowRelevance)
	{
		bFollowRelevance = bShouldFollowRelevance;
	}	

	UFUNCTION(BlueprintOverride)
	void TickEffect(float DeltaSeconds)
	{
		if(!HazeAkOwner.AnyListenerInRange())
		{
			SetZoneLinkRtpc(0.f);
			return;
		}

		PrioritizedZone = HazeAkOwner.PrioritizedZone != nullptr ? 
			Cast<AAmbientZone>(HazeAkOwner.PrioritizedZone) : 
			Cast<AAmbientZone>(HazeAkOwner.FindPrioritizedZone());

		if(PrioritizedZone == nullptr)
			return;		

		float CurrentRtpcValue = ModifyByOcclusion(PrioritizedZone.GetZoneUnmanagedRtpcValue());
		if (bFollowRelevance)
		{
			float ReductionValue = GetOcclusionReductionValue();
			CurrentRtpcValue -= ReductionValue;
		}

		if(CurrentRtpcValue == LastRtpcValue)
			return;

		SetZoneLinkRtpc(CurrentRtpcValue);
	}

	float ModifyByOcclusion(float CurrentValue)
	{
		if (CurrentValue == 1)
			return CurrentValue;

		float Value = 0;
		float InsideZoneValue = 0;
		for	(FAmbientZoneOverlap AmbientOverlap: HazeAkOwner.AmbientZoneOverlaps)
		{
			if (AmbientOverlap.AmbientZone == nullptr ||
				AmbientOverlap.AmbientZone == PrioritizedZone)
				continue;	

			auto Zone = Cast<AAmbientZone>(AmbientOverlap.AmbientZone);
			if (!Zone.IsOcclusionZone() || Zone.Priority < PrioritizedZone.Priority)
				continue;

			float ZonesRelevanceValue = Zone.GetZoneUnmanagedRtpcValue();
			if (ZonesRelevanceValue == 1)
			{
				InsideZoneValue = 1;
				continue;
			}

			Value = FMath::Max(Value, ZonesRelevanceValue);
		}

		if (Value == 0)
			// We are inside another occlusion zone but not crossfading currently.
			Value = InsideZoneValue;

		return FMath::Max(Value, CurrentValue);
	}

	float GetOcclusionReductionValue()
	{
		float SendReductionValue = 0;

		TArray<AAmbientZone> PlayerPrioZones;
		for (auto Listener : PrioritizedZone.ListenersInAttenuationRange)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Listener.GetOwner());
			auto PlayerZone = Cast<AAmbientZone>(Player.PlayerHazeAkComp.PrioritizedZone);
			if (PlayerZone != nullptr && PlayerZone.Priority > PrioritizedZone.Priority)
			{
				PlayerPrioZones.AddUnique(PlayerZone);
			}
		}

		float HighestReductionValue = 0;
		for(AAmbientZone PlayerZone : PlayerPrioZones)
		{
			float UnmanagedValue = PlayerZone.GetZoneUnmanagedRtpcValue();
			HighestReductionValue = FMath::Max(HighestReductionValue, UnmanagedValue);
		}

		return HighestReductionValue;
	}

	void SetZoneLinkRtpc(const float& RtpcValue)
	{
		HazeAkOwner.SetRTPCValue(HazeAudio::RTPC::AmbZoneFade, RtpcValue);
		LastRtpcValue = RtpcValue;
	}
}