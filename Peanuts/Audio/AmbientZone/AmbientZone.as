import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Peanuts.Audio.AmbientZone.AmbientZoneDataAsset;

import AAmbientZone GetHighestPriorityZone(UHazeListenerComponent) from "Peanuts.Audio.AmbientZone.AmbientZoneStatics";
import void RegisterAmbientZone(AAmbientZone) from "Peanuts.Audio.AmbientZone.AmbientZoneStatics";
import void UnregisterAmbientZone(AAmbientZone) from "Peanuts.Audio.AmbientZone.AmbientZoneStatics";

event void FListenerEnteringSignature(UHazeListenerComponent Listener);
event void FListenerExitingSignature(UHazeListenerComponent Listener);

enum EAmbientZoneCurve
{
	Linear,
	Exponential,
	Logarithmic
}

class AAmbientZone : AHazeAmbientZone
{
	UPROPERTY(BlueprintReadOnly)
	UAmbientZoneDataAsset ZoneAsset;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AmbEventComp;

	default AmbEventComp.bIsStatic = true;
	default AmbEventComp.SetAudioFlags(EAudioHazeAkComponentFlag::IgnoredByAmbientOverlaps);
	default SetTickGroup(ETickingGroup::TG_EndPhysics);

	UPROPERTY()
	FListenerEnteringSignature ListenerEntering;

	UPROPERTY()
	FListenerExitingSignature ListenerExiting;

	UPROPERTY(EditConst)
	float CurrentRtpcValue;
	
	float LastPanningValue;
	float LastListenerProximityCompensationValue;

	float CurveValue;
	float PanningValue;
	float FurthestListenerDistance;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	URandomSpotSoundsDataAsset RandomSpotSounds;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	int RandomSpotsPoolsize = 8;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	uint32 Priority = 1;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, meta=(ClampMin="0.0", UIMin="0.0", ClampMax="1.0", UIMax="1.0"))
	float Relevance = 1.f;

	UPROPERTY(EditInstanceOnly)
	EAmbientZoneCurve RtpcCurve = EAmbientZoneCurve::Linear;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	bool bDebug = false;

	private bool bCanPlayQuad = true;
	private bool bActivatingZone = false;
	private bool bIsRegistered = false;

	float CurvePower = 1.f;

	int MayReverbBusIndex = 0;
	int CodyReverbBusIndex = 0;	
	FString MayAuxBusSendName;
	FString CodyAuxBusSendName;

	UPROPERTY(NotEditable)
	bool MayBusInUse = false;
	UPROPERTY(NotEditable)
	bool CodyBusInUse = false;

	TArray<UHazeAkComponent> RandomSpotsAkComps;
	bool bRandomSpotsShouldBeEnabled = false;
	
	TMap<UHazeListenerComponent, float> ListenerDistance;
	TMap<UHazeAkComponent, float> HazeAkCompDistance;

	UFUNCTION(BlueprintOverride)
	int32 GetZonePriority()
	{
		return Priority;
	}

	UFUNCTION(BlueprintOverride)
	float GetZoneRelevance()
	{
		return CurrentRtpcValue;
	}

	bool IsOcclusionZone()
	{
		return Relevance == 0 && !EnsureReverbReady();
	}

	UFUNCTION(BlueprintOverride)
	float GetWantedReverbSendForObject(UHazeAkComponent HazeAkComp)
	{
		return GetWantedRelevanceForObject(HazeAkComp);
	}

	UFUNCTION(BlueprintOverride)
	UAkAuxBus GetReverbBus()
	{
		auto Bus = ZoneAsset == nullptr ? nullptr : ZoneAsset.ReverbBus;
		return Bus;
	}

	UFUNCTION(BlueprintOverride)
	bool IsActualListener(UHazeListenerComponent Listener)
	{
		return ListenersInAttenuationRange.Contains(Listener);
	}

	UFUNCTION(BlueprintOverride)
	bool IsEmitterWithinZone(UHazeAkComponent HazeAkComp)
	{
		return AkCompsInAttenuationRange.Contains(HazeAkComp);
	}

	UFUNCTION(BlueprintOverride)
	bool IsStealingReverb()
	{
		if(!EnsureReverbReady())
			return false;

		return ZoneAsset.bStealReverbSends;
	}

	UFUNCTION(BlueprintOverride)
	bool EnsureReverbReady()
	{
		if(ZoneAsset == nullptr)
			return false;
		if(ZoneAsset.ReverbBus == nullptr)
			return false;
		if(!ZoneAsset.bUseReverbVolumes)
			return false;

		return true;
	}

	bool IsAmbientZoneActive()
	{
		return 
			ListenersInAttenuationRange.Num() != 0 || 
			AkCompsInAttenuationRange.Num() != 0;
	}

	// This is from the view of the AmbientZone, doesn't check with the AmbientZoneManager
	bool IsAmbientRegistered()
	{
		return bIsRegistered;
	}

	bool CanAmbientZoneRegister(UHazeAkComponent HazeAkCompOverride = nullptr)
	{
		if (bIsRegistered)
			return false;

		if (HazeAkCompOverride != nullptr)
			return ZoneAsset != nullptr && HazeAkCompOverride.bIsPlaying && HazeAkCompOverride.AnyListenerInRange();

		if (!IsAmbientZoneActive())
			return false;

		return true;
	}

	void RegisterToManager(bool bRegister, UHazeAkComponent HazeAkCompOverride = nullptr)
	{
		if (bIsRegistered == bRegister)
			return;

		if (bRegister && !CanAmbientZoneRegister(HazeAkCompOverride))
			return;

		bIsRegistered = bRegister;
		if (bRegister)
			RegisterAmbientZone(this);
		else
			UnregisterAmbientZone(this);
	}

	UFUNCTION(BlueprintOverride)
	void InitializeReverbOnObject(UHazeAkComponent HazeAkComp)
	{
		if(!EnsureReverbReady() || !HazeAkComp.bUseReverbVolumes)
			return;	

		FVector Location = HazeAkComp.GetWorldLocation();
		FVector OutPos;

		float Distance = GetClosestDistanceOnBrushComponent(Location, OutPos);
		HazeAkCompDistance.FindOrAdd(HazeAkComp) = Distance;

		float ObjectSendValue = GetWantedRelevanceForObject(HazeAkComp);
		
		if(ObjectSendValue <= 0)
			return;

		FHazeAuxBusData SendData;

		SendData.AuxBus = ZoneAsset.ReverbBus;		
		SendData.Value = ObjectSendValue;

		UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent();

		if(ReverbComp != nullptr)
		{			
			ReverbComp.AddAuxSendFireForget(SendData);					
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedListenerInAttenuationRange(UHazeListenerComponent Listener)
	{
		if(!bZoneIsEnabled)
			return;		

		if (!IsActorTickEnabled())
		{
			SetAmbientZoneTickEnabled(true);
		}

		RegisterToManager(true);

		UpdatePanning();

		if (ListenersInAttenuationRange.Num() == 1)
		{	
			if (ZoneAsset != nullptr && ZoneAsset.QuadEvent != nullptr && bCanPlayQuad)
				AmbEventComp.HazePostEvent(ZoneAsset.QuadEvent, PostEventType = EHazeAudioPostEventType::Ambience);
		}

		TArray<UAkComponent> AkListeners;
		for (UHazeListenerComponent NearbyListener : ListenersInAttenuationRange)
			AkListeners.Add(NearbyListener);
		AmbEventComp.SetListeners(AkListeners);
		ListenerEntering.Broadcast(Listener);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedListenerInAttenuationRange(UHazeListenerComponent Listener)
	{
		if(!bZoneIsEnabled)
			return;
			
		UpdatePanning();

		TArray<UAkComponent> AkListeners;
		for (UHazeListenerComponent NearbyListener : ListenersInAttenuationRange)
			AkListeners.Add(NearbyListener);

		if (HasActorBegunPlay())
			AmbEventComp.SetListeners(AkListeners);
			
		ListenerExiting.Broadcast(Listener);

		if (ListenersInAttenuationRange.Num() <= 0)
		{
			if (HasActorBegunPlay())
				SetRtpcValue(0);
			AmbEventComp.HazeStopEvent();
			SetAmbientZoneTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedAkCompInAttenuationRange(UHazeAkComponent HazeAkComp)
	{
		if(!bZoneIsEnabled)
			return;		

		if (EnsureReverbReady())
		{
			FHazeAuxBusData SendData;					
			SendData.AuxBus = ZoneAsset.ReverbBus;

			AHazeAmbientZone PrioZone = HazeAkComp.PrioReverbZone;

			if(PrioZone == nullptr)
				PrioZone = HazeAkComp.FindPrioritizedZone();
			else if (bActivatingZone)
				HazeAkComp.QueryPrioritizedZone(this);

			if(PrioZone == this)
			{
				SendData.Value = GetWantedRelevanceForObject(HazeAkComp);
			}				
			else
			{
				SendData.Value = GetWantedRelevanceForObject(HazeAkComp) - Cast<AAmbientZone>(PrioZone).GetWantedRelevanceForObject(HazeAkComp);
			}

			UPlayerHazeAkComponent PlayerHazeAkComp = Cast<UPlayerHazeAkComponent>(HazeAkComp);
			if(PlayerHazeAkComp != nullptr)
			{
				UHazeListenerComponent PlayerListener = PlayerHazeAkComp.GetPlayerListener();
				SendData.AuxReceiverObject = PlayerListener;
			}				

			UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent();
			if(ReverbComp != nullptr)
			{									
				if (ReverbComp.HasActiveSendToBus(ZoneAsset.ReverbBus))
					ReverbComp.UpdateObjectAuxSendValue(ZoneAsset.ReverbBus, SendData.Value, SendData.AuxReceiverObject);
				else
					ReverbComp.AddObjectAuxSendData(SendData);
			}				
		}		

		QueryEnvironmentSwitch(HazeAkComp);	
		RegisterToManager(true, HazeAkComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedAkCompInAttenuationRange(UHazeAkComponent HazeAkComp)
	{
		if (!HazeAkComp.bUseReverbVolumes || HazeAkComp.bIsStatic)
			return;

		if (EnsureReverbReady())
		{
			UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent(bCreateIfNeeded = false);
			if (ReverbComp != nullptr)
				ReverbComp.RemoveObjectAuxSend(this, ZoneAsset.ReverbBus);
		}

		QueryEnvironmentSwitch(HazeAkComp);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		FVector Origin;
		FVector BoundsExtent;
		float Radius;
		
		System::GetComponentBounds(BrushComponent, Origin, BoundsExtent, Radius);

		BrushComponent.SetCollisionProfileName(n"AmbientZone");	
		BrushComponent.SetGenerateOverlapEvents(false);

		switch (RtpcCurve)
		{
		case EAmbientZoneCurve::Linear:
			CurvePower = 1.f;
			break;
		case EAmbientZoneCurve::Exponential:
			CurvePower = 2.f;
			break;
		case EAmbientZoneCurve::Logarithmic:
			CurvePower = 0.5f;
			break;
		}

		AmbEventComp.SetWorldLocation(Origin);

		if (ZoneAsset != nullptr)
		{
			AmbEventComp.AttenuationScalingFactor = ZoneAsset.AttenuationScalingFactor;
			AmbEventComp.OcclusionRefreshInterval = ZoneAsset.OcclusionRefreshInterval;
			AmbEventComp.bUseReverbVolumes = false;
		}

		if (RandomSpotSounds != nullptr)
		{		
			for (FRandomSpotSound& SpotSound : RandomSpotSounds.SpotSounds)
			{
				SpotSound.NextTime = FMath::RandRange(SpotSound.MinRepeatRate, SpotSound.MaxRepeatRate);
			}
		}		

		if(ZonePriority == 0)
			SetZeroZoneReverbSend();

		if (ListenersInAttenuationRange.Num() == 0)
			SetAmbientZoneTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RegisterToManager(false);
	}

	float GetWantedRelevanceForObject(UAkComponent AkComp, bool bManaged = true)
	{
		UHazeListenerComponent Listener = Cast<UHazeListenerComponent>(AkComp);
		UHazeAkComponent Emitter = Cast<UHazeAkComponent>(AkComp);
		float Ratio = 0.f;

		if(Listener != nullptr)
		{
			float ShortestDistance = ListenerDistance.FindOrAdd(Listener);
			if (ShortestDistance < AttenuationLength)
			{
				Ratio = 1 - (ShortestDistance / AttenuationLength);
			}

			if(bManaged)
				Ratio *= Relevance;		
		}
		if(Emitter != nullptr)
		{			
			float ShortestDistance = HazeAkCompDistance.FindOrAdd(Emitter);
			if (ShortestDistance < AttenuationLength)
			{
				Ratio = 1 - (ShortestDistance / AttenuationLength);
			}					
		}
		return Ratio;
	}

	void SetRtpcValue(float Value)
	{
		CurveValue = FMath::Pow(Value, CurvePower);	
		if(CurrentRtpcValue == CurveValue)
			return;

		CurrentRtpcValue = CurveValue;
		if(AmbEventComp.IsGameObjectRegisteredWithWwise())
			AmbEventComp.SetRTPCValue(HazeAudio::RTPC::AmbZoneFade, CurveValue, 0);						
	}

	void UpdateListeners()
	{
		float ShortestDist = AttenuationLength + 100.f;
		for (UHazeListenerComponent Listener : ListenersInAttenuationRange)
		{
			FVector ListenerLocation = Listener.GetWorldLocation();
			FVector OutPosition;
			float Distance = GetClosestDistanceOnBrushComponent(ListenerLocation, OutPosition);			

			ListenerDistance.FindOrAdd(Listener) = Distance;
			SetListenerProximityBoostCompensation(Listener, Distance);

#if EDITOR
			if(bDebug)
			{				
				System::DrawDebugArrow(OutPosition, Listener.GetWorldLocation(), 150, FLinearColor::Red);
			}
#endif
		}
	}

	void UpdateEmitters()
	{
		for(UHazeAkComponent HazeAkComp : AkCompsInAttenuationRange)
		{
			UpdateEmitter(HazeAkComp, false);
		}
	}

	void UpdateEmitter(UHazeAkComponent HazeAkComp, bool bForce)
	{
		if (HazeAkComp == nullptr || !HazeAkComp.HasAudioFlags(EAudioHazeAkComponentFlag::QueuedForReverbProcessing, false) && !bForce)
			return;

  		FVector Location = HazeAkComp.GetWorldLocation();
		FVector OutPos;

		float Distance = GetClosestDistanceOnBrushComponent(Location, OutPos);
		HazeAkCompDistance.FindOrAdd(HazeAkComp) = Distance;
	}

	void UpdateRandomSpots(float DeltaSeconds)
	{
		if (ListenersInAttenuationRange.Num() <= 0)
			return;

		if (RandomSpotSounds == nullptr)
			return;

		if (bRandomSpotsShouldBeEnabled)
		{
			bRandomSpotsShouldBeEnabled = false;
			for(UHazeAkComponent Comp : RandomSpotsAkComps)
			{										
				Comp.PerformEnabled();
			}
		}

		bool bShouldUpdateRandomSpotSounds = false;
		for(UHazeListenerComponent Listener : ListenersInAttenuationRange)
		{
			if(GetHighestPriorityZone(Listener) == this)
				bShouldUpdateRandomSpotSounds = true;
		}

		if(!bShouldUpdateRandomSpotSounds || !bCanPlayQuad)
			return;

		for (FRandomSpotSound& RandomSpot : RandomSpotSounds.SpotSounds)
		{
			RandomSpot.CurrentTime += DeltaSeconds;
			if (RandomSpot.CurrentTime < RandomSpot.NextTime)
				continue;

			RandomSpot.CurrentTime = 0;
			RandomSpot.NextTime = FMath::RandRange(RandomSpot.MinRepeatRate, RandomSpot.MaxRepeatRate);

			float Yaw = FMath::RandRange(0.f, 360.f);
			FRotator Rotation = FRotator(0, Yaw, 0);
			FVector Normal = Rotation.GetForwardVector();

			float Length = FMath::RandRange(RandomSpot.MinLength, RandomSpot.MaxLength);
			FVector Location = Normal * Length;

			FVector ListenerLocation;
			if (ListenersInAttenuationRange.Num() == 1 || FMath::RandBool())
			{
				ListenerLocation = ListenersInAttenuationRange[0].GetWorldLocation();
			}
			else
			{
				ListenerLocation = ListenersInAttenuationRange[1].GetWorldLocation();
			}

			Location += ListenerLocation;
#if EDITOR
			if (bDebug)
			{				
				for(UHazeAkComponent Comp : RandomSpotsAkComps)
				{										
					Comp.SetDebugAudio(true);
				}
			}
			else
			{
				for(UHazeAkComponent Comp : RandomSpotsAkComps)
				{
					Comp.SetDebugAudio(false);
				}
			}
#endif
			UHazeAkComponent RandomSpotAkComp = GetAvaliableHazeAkComp();

			if(RandomSpotAkComp != nullptr)
			{				
				RandomSpotAkComp.SetWorldLocation(Location);	
				RandomSpotAkComp.SetRTPCValue(HazeAudio::RTPC::AmbZoneFade, CurveValue, 0.f);	
				RandomSpotAkComp.SetRTPCValue(HazeAudio::RTPC::AmbZonePanning, PanningValue, 0.f);						
				RandomSpotAkComp.HazePostEvent(RandomSpot.Event, PostEventType = EHazeAudioPostEventType::Ambience);
			}	
		}
	}	

	UHazeAkComponent GetAvaliableHazeAkComp()
	{
		for (UHazeAkComponent HazeAkComp : RandomSpotsAkComps)
		{
			if(HazeAkComp.bIsPlaying == true)
				continue;		
			
			else			
				return HazeAkComp;			
		}

		if(RandomSpotsAkComps.Num() < RandomSpotsPoolsize)
		{
			const bool bReverb = ZoneAsset != nullptr && ZoneAsset.bUseReverbVolumes;
			const FName ComponentName = FName(GetName()+"_RandomSpotComp_"+RandomSpotsAkComps.Num());
			auto RandomSpotComp = GetOrCreateHazeAkComponent(ComponentName, bReverb, true);
			RandomSpotsAkComps.AddUnique(RandomSpotComp);	
			return RandomSpotComp;	
		}
		
		return nullptr;
	}

	void UpdatePanning()
	{
		if(ListenersInAttenuationRange.Num() > 1 )
		{
			PanningValue = 0.5f;			
		}
		else if(ListenersInAttenuationRange.Num() != 0)
		{			
			AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(ListenersInAttenuationRange[0].GetOwner());

			if(PlayerOwner == nullptr)
				return;

			if(PlayerOwner.IsMay())	
			{
				PanningValue = 0.0f;				
			}
			else
			{
				PanningValue = 1.0f;				
			}
		}

		if(PanningValue == LastPanningValue)
			return;
		LastPanningValue = PanningValue;

		if (HasActorBegunPlay())
			AmbEventComp.SetRTPCValue(HazeAudio::RTPC::AmbZonePanning, PanningValue * GetPanningMultiplierValue(), 0.f);
	}

	void SetListenerProximityBoostCompensation(UHazeListenerComponent Listener, float Distance)
	{
		if(ListenersInAttenuationRange.Num() < 2 || Distance > AttenuationLength || Distance < FurthestListenerDistance)
			return;

		FurthestListenerDistance = Distance;

		float ListenerProximityCompensationValue = Distance / AttenuationLength;

		if(ListenerProximityCompensationValue == LastListenerProximityCompensationValue)
			return;

		if(AmbEventComp.IsGameObjectRegisteredWithWwise())
		{
			AmbEventComp.SetRTPCValue(HazeAudio::RTPC::ListenerProximityBoostCompensation, ListenerProximityCompensationValue, 0.f);	
			LastListenerProximityCompensationValue = ListenerProximityCompensationValue;		
		}
	}

#if TEST
	void DrawDebugBox()
	{
		FVector Origin;
		FVector BoundsExtent;
		float Radius;
		System::GetComponentBounds(BrushComponent, Origin, BoundsExtent, Radius);
		FLinearColor Color = CurrentRtpcValue == 0 ? FLinearColor::Red : FLinearColor::Green;
		System::DrawDebugBox(Origin, BoundsExtent, Color, BrushComponent.GetWorldRotation());
	
		FVector OuterBounds = BoundsExtent + AttenuationLength;
		System::DrawDebugBox(Origin, OuterBounds, FLinearColor::Blue, BrushComponent.GetWorldRotation());
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateListeners();

		UpdateEmitters();
	
		UpdateRandomSpots(DeltaSeconds);		
	
#if Editor
		if(bDebug)
		{
			DrawDebugBox();
			BrushComponent.SetHiddenInGame(false);							
		}
		else if(!BrushComponent.bHiddenInGame)
		{			
			BrushComponent.SetHiddenInGame(true);	
		}
#endif

	}

	float GetClosestDistanceOnBrushComponent(FVector Location, FVector& OutVector)
	{		
		float Dist = BrushComponent.GetClosestPointOnCollision(Location, OutVector);
		if (Dist > 0 && !bVerticalFade)
		{
			FVector Direction = OutVector - Location;				
			if (FMath::Abs(Direction.Z) > 0.01f)
			{
				// Make the distance somewhat larger than AttenuationLength to make sure that the rest of the code thinks that we are outside
				Dist = AttenuationLength + 100.f;
			}
		}

		return Dist;
	}
	
	float GetZoneUnmanagedRtpcValue()
	{		
		float FinalRelevance = 0.f;
		for (UHazeListenerComponent Listener : ListenersInAttenuationRange)
		{
			float Rel = GetWantedRelevanceForObject(Listener, false);
			FinalRelevance = FMath::Max(Rel, FinalRelevance);				
		}

		return FinalRelevance;
	}

	float GetZoneManagedRtpcValue()
	{		
		float FinalRelevance = 0.f;
		for (UHazeListenerComponent Listener : ListenersInAttenuationRange)
		{
			float Rel = GetWantedRelevanceForObject(Listener, false);
			FinalRelevance = FMath::Max(Rel, FinalRelevance);				
		}

		return FinalRelevance;
	}

	void QueryEnvironmentSwitch(UHazeAkComponent& HazeAkComp)
	{		
		HazeAkComp.UpdateEnvironmentSwitch(HazeAkComp.PrioritizedZone);		
	}

	void SetZeroZoneReverbSend()
	{
		if(!EnsureReverbReady() || ZonePriority != 0)
			return;

		UHazeReverbComponent ReverbComp = AmbEventComp.GetReverbComponent();
		if (ReverbComp == nullptr)
			return;
			
		FHazeAuxBusData SendData;
		SendData.AuxBus = ZoneAsset.ReverbBus;
		SendData.Value = ZoneAsset.SendLevel * 1.f;

		ReverbComp.AddAuxSendFireForget(SendData);	
	}

	void SetAmbientZoneTickEnabled(bool bShouldBeEnabled)
	{
		SetActorTickEnabled(bShouldBeEnabled);
		
		if(bShouldBeEnabled)
		{
			AmbEventComp.PerformEnabled();
			bRandomSpotsShouldBeEnabled = true;
			// We can't enabled random spots here, can result in a recursion of UpdateAmbientZoneOverlaps()
			// for(auto SpotComp : RandomSpotsAkComps)
			// {
			// 	SpotComp.PerformEnabled();
			// }
		}
		else
		{
			AmbEventComp.PerformDisabled();
			for(auto SpotComp : RandomSpotsAkComps)
			{
				SpotComp.PerformDisabled();
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetEnabledQuadEvent(bool bEnabled, float FadeOutTimeMS = 0.f, EAkCurveInterpolation FadeOutCurve = EAkCurveInterpolation::Linear)
	{
		if(!bCanPlayQuad && bEnabled)
		{
			bCanPlayQuad = true;
			if(ListenersInAttenuationRange.Num() > 0 && ZoneAsset != nullptr)
			{
				AmbEventComp.HazePostEvent(ZoneAsset.QuadEvent, PostEventType = EHazeAudioPostEventType::Ambience);
			}
			
		}	
		else if(!bEnabled && bCanPlayQuad)
		{
			AmbEventComp.HazeStopEvent(FadeOutTimeMs = FadeOutTimeMS, CurveType = FadeOutCurve);
			bCanPlayQuad = false;

			for(auto& RandomSpotComp : RandomSpotsAkComps)
			{
				RandomSpotComp.HazeStopEvent(FadeOutTimeMs = FadeOutTimeMS, CurveType = FadeOutCurve);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void BP_SetZoneEnabled(bool bEnabled)
	{
		if(bEnabled == bZoneIsEnabled)
			return;

		bZoneIsEnabled = bEnabled;
		SetAmbientZoneTickEnabled(bZoneIsEnabled);
		SetEnabledQuadEvent(bZoneIsEnabled);

		if(!bZoneIsEnabled)
		{
			RegisterToManager(false);
		}
		else
		{
			// I see three problems we must look out for,
			// 1. All the HazeAkComps must run QueryPrioritizedZone again, since it was ignored before.
			// 2. AmbientZone's tick etc is based on the events Add/Remove Listener/AkComp, these won't be run properly if no components exists.
			// 3. RegisterAmbientZone will most likely be called for each component and listener
			
			// Negates #1 
			bActivatingZone = true;
			// Negates #2 and #3
			RegisterToManager(true);

			for(auto& PendingListener : ListenersInAttenuationRange)
			{
				OnAddedListenerInAttenuationRange(PendingListener);
			}

			for(auto& PendingHazeAkComp : AkCompsInAttenuationRange)
			{
				OnAddedAkCompInAttenuationRange(PendingHazeAkComp);
			}

			bActivatingZone = false;
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetDebug(bool Value)
	{
		bDebug = Value;
	}

	UFUNCTION(BlueprintCallable)
	bool GetDebugState()
	{
		return bDebug;
	}
}
