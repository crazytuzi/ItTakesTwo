import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallEqualizerSweeper;
import Peanuts.Audio.AudioStatics;

class UMusicTechWallEqRoomAudioCapability : UHazeCapability
{
	AMusicTechWallEqualizerSweeper EqualizeSweeper;
	UHazeAkComponent EqHazeAkComp;	
	UHazeAkComponent TopNoiseHazeAkComp;
	UHazeAkComponent BotNoiseHazeAkComp;

	UPROPERTY()
	UAkAudioEvent TopNoiseEvent;

	UPROPERTY()
	UAkAudioEvent BotNoiseEvent;

	UPROPERTY()
	UAkAudioEvent EqSweepLoopingEvent;

	UPROPERTY()
	UAkAudioEvent NoiseDeathEvent;

	UPROPERTY(EditConst)
	FString LowNotchFrequencyRtpc = "Rtpc_Gameplay_Gadgets_EqualizerSweeper_Low_Notch_Freq";

	UPROPERTY(EditConst)
	FString HighNotchFrequencyRtpc = "Rtpc_Gameplay_Gadgets_EqualizerSweeper_High_Notch_Freq";

	UPROPERTY(EditConst)
	FString FilterMovedRtpc = "Rtpc_Gameplay_Gadgets_EqualizerSweeper_FilterIsMoving";
	
	UPROPERTY(EditConst)
	FString FilterLoudnessCompensationRtpc = "Rtpc_Gameplay_Gadgets_EqualizerSweeper_LoudnessCompensation";

	private float LastTopNoisePanning;
	private float LastBotNoisePanning;

	private float LastLowFilterFreq;
	private float LastHighFilterFreq;
	private float LastLoudnessCompensation;
	private bool bLastFilterMoved = false;

	private int32 StateGroupId;
	private int32 StateId;
	private int32 EndStateId;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		EqualizeSweeper = Cast<AMusicTechWallEqualizerSweeper>(Owner);
		EqHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		TopNoiseHazeAkComp = UHazeAkComponent::Create(Owner, n"TopNoiseHazeAkComp");
		BotNoiseHazeAkComp = UHazeAkComponent::Create(Owner, n"BotNoiseHazeAkComp");

		if(EqualizeSweeper.TopDeathVolume != nullptr)
			EqualizeSweeper.TopDeathVolume.OnActorBeginOverlap.AddUFunction(this, n"OnNoiseOverlap");

		if(EqualizeSweeper.BotDeathVolume != nullptr)
			EqualizeSweeper.BotDeathVolume.OnActorBeginOverlap.AddUFunction(this, n"OnNoiseOverlap");

		// This progress point isn't it in natural progression, handle setting states from this capability
		Audio::GetAkIdFromString("StateGroup_Checkpoints", StateGroupId);
		Audio::GetAkIdFromString("Stt_CheckPoints_Music_Backstage_Music_Tech_Wall__EQ_Sweeper", StateId);
		Audio::GetAkIdFromString("Stt_CheckPoints_Music_Backstage_Music_Tech_Wall__End", EndStateId);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		EqHazeAkComp.HazePostEvent(EqSweepLoopingEvent);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Efforts_IsBlocked", 1.f);
		Audio::SetAkStateById(StateGroupId, StateId);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(EqualizeSweeper.bAudioActive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		EqHazeAkComp.HazeStopEvent();
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Efforts_IsBlocked", 0.f);

		EqHazeAkComp.PerformDisabled();
		TopNoiseHazeAkComp.PerformDisabled();
		BotNoiseHazeAkComp.PerformDisabled();

		Audio::SetAkStateById(StateGroupId, EndStateId);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioStartTopNoise") == EActionStateStatus::Active)
		{
			TopNoiseHazeAkComp.HazePostEvent(TopNoiseEvent);
		}

		if(ConsumeAction(n"AudioStartBotNoise") == EActionStateStatus::Active)
		{
			BotNoiseHazeAkComp.HazePostEvent(BotNoiseEvent);
		}

		if(EqualizeSweeper.SyncedTopNoiseRotationValue.Value != LastTopNoisePanning)
		{
			const float NormalizedPanning = HazeAudio::NormalizeRTPC(EqualizeSweeper.SyncedTopNoiseRotationValue.Value, 0.f, 1.f, -1.f, 1.f);
			HazeAudio::SetPlayerPanning(TopNoiseHazeAkComp, nullptr, NormalizedPanning);
			LastTopNoisePanning = EqualizeSweeper.SyncedTopNoiseRotationValue.Value;
			// PrintToScreen("EqualizeSweeper LastTopNoisePanning: " + LastTopNoisePanning);
		}

		if(EqualizeSweeper.SyncedBottomNoiseRotationValue.Value != LastBotNoisePanning)
		{
			const float NormalizedPanning = HazeAudio::NormalizeRTPC(EqualizeSweeper.SyncedBottomNoiseRotationValue.Value, 0.f, 1.f, -1.f, 1.f);
			HazeAudio::SetPlayerPanning(BotNoiseHazeAkComp, nullptr, NormalizedPanning);
			LastBotNoisePanning = EqualizeSweeper.SyncedBottomNoiseRotationValue.Value;
			// PrintToScreen("EqualizeSweeper LastBotNoisePanning: " + LastBotNoisePanning);
		}

		bool bFilterMoved = false;

		if(EqualizeSweeper.CurrentLeftEQPlacement != LastLowFilterFreq)
		{
			EqHazeAkComp.SetRTPCValue(LowNotchFrequencyRtpc, EqualizeSweeper.CurrentLeftEQPlacement);
			LastLowFilterFreq = EqualizeSweeper.CurrentLeftEQPlacement;
			bFilterMoved = true;
		}

		if(EqualizeSweeper.CurrentRightEQPlacement != LastHighFilterFreq)
		{
			EqHazeAkComp.SetRTPCValue(HighNotchFrequencyRtpc, EqualizeSweeper.CurrentRightEQPlacement);
			LastHighFilterFreq = EqualizeSweeper.CurrentRightEQPlacement;
			bFilterMoved = true;
		}

		if(bLastFilterMoved != bFilterMoved)
		{
			bLastFilterMoved = bFilterMoved;
			const float MovedValue = bFilterMoved ? 1.f : 0.f;
			EqHazeAkComp.SetRTPCValue(FilterMovedRtpc, MovedValue);
		
		}

		const float LoudnessCompensation = EqualizeSweeper.CurrentLeftEQPlacement + (1 - EqualizeSweeper.CurrentRightEQPlacement);
		if(LoudnessCompensation != LastLoudnessCompensation)
		{
			EqHazeAkComp.SetRTPCValue(FilterLoudnessCompensationRtpc, LoudnessCompensation);
			LastLoudnessCompensation = LoudnessCompensation;
		}

		if(ConsumeAction(n"AudioOnKilledByNoise") == EActionStateStatus::Active)
			EqHazeAkComp.HazePostEvent(NoiseDeathEvent);
	}

	UFUNCTION()
	void OnNoiseOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		EqHazeAkComp.HazePostEvent(NoiseDeathEvent);
	}

}