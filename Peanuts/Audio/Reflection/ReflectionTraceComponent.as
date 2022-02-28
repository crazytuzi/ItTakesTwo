import Peanuts.Audio.AmbientZone.AmbientZone;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

import bool SetDelayParameterRanges(FReflectionTraceValues&, EEnvironmentType) from "Peanuts.Audio.Reflection.ReflectionTraceStatics";

#if TEST
import void SetDelayDebugData(
		FReflectionTraceData& TraceData, 
		FHitResult& TraceResult,
		UPhysicalMaterialAudio AudioPhysMat,
		AAmbientZone PlayerOwnerPrioZone, 
		int Index,
		bool bIsMay) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

class UReflectionTraceComponent : UHazeReflectionTraceComponent
{
	UPROPERTY(EditAnywhere)
	FReflectionTraceData FrontLeftSendData;

	UPROPERTY(EditAnywhere)
	FReflectionTraceData FrontRightSendData;
	
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UHazeListenerComponent PlayerListener;
	UHazeReverbComponent PlayerReverb;
	AHazePlayerCharacter PlayerOwner;

	const float MaxTraceDistance = 340.f * 100.f;

	float LastEnvironmentTypeRtpc = -1.f;
	TArray<FHitResult> LastHitResults;
	EEnvironmentType LastEnviromentType;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerHazeAkComp = PlayerOwner.PlayerHazeAkComp;
		PlayerListener = PlayerOwner.PlayerListener;
		PlayerReverb = PlayerHazeAkComp.GetReverbComponent();
		AttachTo(GetOwner().RootComponent);

		LastHitResults.Add(FHitResult());
		LastHitResults.Add(FHitResult());

		//CreateTraceAkComponents();
	}

	UFUNCTION(BlueprintOverride)
	void SetTraceAkComponents()
	{
		FrontLeftSendData.TraceAkComp = LeftTraceAkComp;
		FrontRightSendData.TraceAkComp = RightTraceAkComp;	
	}

	UFUNCTION(BlueprintCallable)
	void UpdateTraceComponentLocation(FReflectionTraceData& TraceData, FVector& Location)
	{
		if(TraceData.TraceAkComp != nullptr)
			TraceData.TraceAkComp.SetWorldLocation(Location);
	}

	void OnCapabilityDisabled()
	{
		SetRtpcData(FrontLeftSendData, EReflectionRtpcType::AuxBusVolume, -200.f);
		SetRtpcData(FrontRightSendData, EReflectionRtpcType::AuxBusVolume, -200.f);
	}

	void ResetDynamicValues()
	{
		LastHitResults[0].Component = nullptr;
		LastHitResults[0].Distance = -1;
		LastHitResults[1].Component = nullptr;
		LastHitResults[1].Distance = -1;
	}

	void ResetStaticValues()
	{
	}

	UFUNCTION(BlueprintCallable)
	void UpdateReflectionSendData(
		AAmbientZone PrioReverbZone, 
		FReflectionTraceData& TraceData, 
		FHitResult& TraceResult, 
		int Index)
	{
		// NOTE: TBD if required.
		// AAmbientZone TracePrioZone = Cast<AAmbientZone>(TraceData.TraceAkComp.GetPrioReverbZone());	
		// AAmbientZone PlayerOwnerPrioZone = Cast<AAmbientZone>(PlayerHazeAkComp.GetPrioReverbZone());	

		if(PrioReverbZone == nullptr)
			return;

		if (TraceData.CurrentTraceValues.bIsStatic)
		{
			ResetDynamicValues();
		}else{
			auto LastHitResult = LastHitResults[Index];
			if (LastEnviromentType ==  PrioReverbZone.EnvironmentType &&
				LastHitResult.Component == TraceResult.Component &&
				FMath::IsNearlyEqual(LastHitResult.Distance, TraceResult.Distance, 10.f))
				return;

			ResetStaticValues();
			LastHitResults[Index] = TraceResult;
		}

		LastEnviromentType = PrioReverbZone.EnvironmentType;

		UPhysicalMaterialAudio AudioPhysMat;
		if(TraceData.CurrentTraceValues.bIsStatic ||
			(TraceResult.bBlockingHit && 
			SetDelayParameterRanges(TraceData.CurrentTraceValues, PrioReverbZone.EnvironmentType)))
		{
			float NormalizedTraceVolume;
			float NormalizedReverbSendLevel;
			float NormalizedTraceDelayTime;
			float NormalizedTraceHfShelfFreq;
			float NormalizedTraceLfShelfFreq;
			float NormalizedTraceFeedback;

			if (!TraceData.CurrentTraceValues.bIsStatic)
			{
				// Get current RTPC values based on trace distance
				NormalizedTraceVolume = GetNormalizedTraceDistanceValue(EReflectionRtpcType::AuxBusVolume, TraceResult.Distance, TraceData.CurrentTraceValues);			
				NormalizedReverbSendLevel = GetNormalizedTraceDistanceValue(EReflectionRtpcType::ReverbSendLevel, TraceResult.Distance, TraceData.CurrentTraceValues);
				NormalizedTraceDelayTime = GetNormalizedTraceDistanceValue(EReflectionRtpcType::DelayTime, TraceResult.Distance, TraceData.CurrentTraceValues);			
				NormalizedTraceHfShelfFreq = GetNormalizedTraceDistanceValue(EReflectionRtpcType::HfShelfFilterFrequency, TraceResult.Distance, TraceData.CurrentTraceValues);
				NormalizedTraceLfShelfFreq = GetNormalizedTraceDistanceValue(EReflectionRtpcType::LfShelfFilterFrequency, TraceResult.Distance, TraceData.CurrentTraceValues);		
				NormalizedTraceFeedback = GetNormalizedTraceDistanceValue(EReflectionRtpcType::FeedbackAmount, TraceResult.Distance, TraceData.CurrentTraceValues);									
			
				// Get RTPC multipliers based on trace hit material
				AudioPhysMat = PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(TraceResult.Component);

				// If trace returned with a phys mat, get material multipliers
				if(AudioPhysMat != nullptr)
				{				
					HazeAudio::EMaterialFootstepType MaterialType = AudioPhysMat.GetMaterialHardness();

					if(MaterialType == HazeAudio::EMaterialFootstepType::Soft)
					{
						NormalizedTraceHfShelfFreq *= TraceData.CurrentTraceValues.SoftMaterialFreqMultiplier;
						NormalizedTraceLfShelfFreq *= TraceData.CurrentTraceValues.SoftMaterialFreqMultiplier;
						NormalizedTraceFeedback *= TraceData.CurrentTraceValues.SoftMaterialFreqMultiplier;	
					}
					else if(MaterialType == HazeAudio::EMaterialFootstepType::Hard)
					{
						NormalizedTraceHfShelfFreq *= TraceData.CurrentTraceValues.HardMaterialFreqMultiplier;
						NormalizedTraceLfShelfFreq *= TraceData.CurrentTraceValues.HardMaterialFreqMultiplier;
						NormalizedTraceFeedback *= TraceData.CurrentTraceValues.HardMaterialFreqMultiplier;	
					}
				}
			}
			else {
				NormalizedTraceVolume = TraceData.CurrentTraceValues.MaxDelayVolume;
				NormalizedReverbSendLevel  = TraceData.CurrentTraceValues.ReverbSendLevel;
				NormalizedTraceDelayTime  = TraceData.CurrentTraceValues.MaxDelayTime;
				NormalizedTraceHfShelfFreq  = TraceData.CurrentTraceValues.MaxHighShelfFilterFreq;
				NormalizedTraceLfShelfFreq  = TraceData.CurrentTraceValues.MaxLowShelfFilterFreq;
				NormalizedTraceFeedback  = TraceData.CurrentTraceValues.MaxFeedback;
			}

			// Set Environment-type RTPC as multiplier for delay-send values
			float EnvironmentTypeRtpcValue = GetEnvironmentTypeRtpcValue(PrioReverbZone.EnvironmentType);
			if(EnvironmentTypeRtpcValue != LastEnvironmentTypeRtpc)
			{
				PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::EnvironmentType, EnvironmentTypeRtpcValue);
				LastEnvironmentTypeRtpc = EnvironmentTypeRtpcValue;
			}

			// Set all RtpcDatas
			
			// Bus Volume
			SetRtpcData(TraceData, EReflectionRtpcType::AuxBusVolume, NormalizedTraceVolume);

			// Delay Time
			SetRtpcData(TraceData, EReflectionRtpcType::DelayTime, NormalizedTraceDelayTime);

			// Feedback
			SetRtpcData(TraceData, EReflectionRtpcType::FeedbackAmount, NormalizedTraceFeedback);

			// Hf Shelf Filter Freq	
			SetRtpcData(TraceData, EReflectionRtpcType::HfShelfFilterFrequency, NormalizedTraceHfShelfFreq);

			// Lf Shelf Filter Freq	
			SetRtpcData(TraceData, EReflectionRtpcType::LfShelfFilterFrequency, NormalizedTraceLfShelfFreq);

			// Peak Filter Freq
			SetRtpcData(TraceData, EReflectionRtpcType::PeakFilterFrequency, TraceData.CurrentTraceValues.PeakFilterFreq);

			// Peak Filter Gain
			SetRtpcData(TraceData, EReflectionRtpcType::PeakFilterGain, TraceData.CurrentTraceValues.PeakFilterGain);

			// Reverb Send Level
			SetRtpcData(TraceData, EReflectionRtpcType::ReverbSendLevel, TraceData.CurrentTraceValues.ReverbSendLevel);
		}
		else
		{
			// Trace hit wasn't blocking, mute send
			SetRtpcData(TraceData, EReflectionRtpcType::AuxBusVolume, -200.f);
		}

		UpdateReflectionRtpc(TraceData);	

		#if TEST
		SetDelayDebugData(TraceData, TraceResult, AudioPhysMat, PrioReverbZone, Index, PlayerOwner.IsMay());
		#endif
		
		//UpdateReflectionReverbSends(TraceData);
	}

	float GetNormalizedTraceDistanceValue(EReflectionRtpcType RtpcValueType, float& TraceDist,  FReflectionTraceValues& TraceValues)
	{		
		const float TraceDistClamped = FMath::Clamp(TraceDist, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance);	
			
		switch(RtpcValueType)
		{
			case EReflectionRtpcType::AuxBusVolume:				
				return HazeAudio::NormalizeRTPC(TraceDistClamped, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, TraceValues.MaxDelayVolume, TraceValues.MinDelayVolume);
			
			case EReflectionRtpcType::DelayTime:
				return HazeAudio::NormalizeRTPC(TraceDistClamped, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, TraceValues.MaxDelayTime, TraceValues.MinDelayTime);

			case EReflectionRtpcType::HfShelfFilterFrequency:
				return HazeAudio::NormalizeRTPC(TraceDistClamped, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, TraceValues.MaxHighShelfFilterFreq, TraceValues.MinHighShelfFilterFreq);

			case EReflectionRtpcType::LfShelfFilterFrequency:
				return HazeAudio::NormalizeRTPC(TraceDistClamped, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, TraceValues.MaxLowShelfFilterFreq, TraceValues.MinLowShelfFilterFreq);

			case EReflectionRtpcType::FeedbackAmount:
				return HazeAudio::NormalizeRTPC(TraceDistClamped, TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, TraceValues.MaxFeedback, TraceValues.MinFeedback);			
			
			default:
				break;
		}

		return 0;
	}

	void SetRtpcData(FReflectionTraceData& TraceData,  EReflectionRtpcType RtpcType, float InValue)
	{
		FReflectionRtpcData& RtpcData = TraceData.TraceRtpcDatas[int(RtpcType)];
		RtpcData.Value = InValue;
		RtpcData.bHasChanged = true;
	}

	void UpdateReflectionRtpc(FReflectionTraceData& TraceData)
	{
		for(FReflectionRtpcData RtpcData : TraceData.TraceRtpcDatas)
		{
			if(!RtpcData.bHasChanged)
				continue;
		
			UHazeAkComponent::HazeSetGlobalRTPCValue(RtpcData.Name, RtpcData.Value);			
			RtpcData.bHasChanged = false;
		}
	}

	void UpdateReflectionReverbSends(FReflectionTraceData& TraceData)
	{
		/* TODO:
		if(!ReverbComp.HasActiveReflectionSend(TraceData.TraceAkComp.PrioReverbZone))
			ReverbComp.AddReflectionSend(TraceData.TraceAkComp.PrioReverbZone)
		else	
			ReverbComp.UpdateReflectionSend(TraceData.TraceAkComp.PrioReverbZone, SendValue);

			Make sure to calc reflection reverb sends for all TraceAkComp-overlapping zones
		*/
	}

	float GetEnvironmentTypeRtpcValue(EEnvironmentType PlayerEnvironment)
	{
		switch(PlayerEnvironment)
		{
			case EEnvironmentType::Swtc_Environment_Exterior_Canyon:
				return 1.f;			
			
			case EEnvironmentType::Swtc_Environment_Exterior_Field:
				return 2.f;

			case EEnvironmentType::Swtc_Environment_Exterior_Forest:
				return 3.f;

			case EEnvironmentType::Swtc_Environment_Interior_Small:
				return 4.f;

			case EEnvironmentType::Swtc_Environment_Interior_Large:
				return 5.f;

			case EEnvironmentType::Swtc_Environment_Interior_XLarge:
				return 6.f;

			case EEnvironmentType::Swtc_Environment_Tunnel_Small:
				return 7.f;
			
			case EEnvironmentType::Swtc_Environment_Tunnel_Large:
				return 8.f;

			default:
				break;
		}

		return 0.f;
	}

}
