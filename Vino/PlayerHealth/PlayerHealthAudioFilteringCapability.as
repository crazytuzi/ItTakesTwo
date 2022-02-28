import Vino.PlayerHealth.PlayerHealthAudioComponent;

class UPlayerHealthAudioFilteringCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AudioHealthFiltering");

	AHazePlayerCharacter Player;
	UPlayerHealthAudioComponent AudioHealthComp;
	FPlayerHealthAudioParams AudioHealthParams;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Player.IsAnyCapabilityActive(AudioTags::FullScreenListener))
			return EHazeNetworkActivation::DontActivate;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}	
	
	void SetFilteringRtpc(const float RtpcValue, const int32 Interpolation = 0)
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue(AudioHealthComp.AudioHealthParams.FilteringRTPC, RtpcValue, Interpolation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Consume immediately when activating to not act upon any attributes set from before
		float OutFilterVal;
		ConsumeAttribute(n"AudioSetHealthFilteringValue", OutFilterVal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetFilteringRtpc(1.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Player.IsAnyCapabilityActive(AudioTags::FullScreenListener))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float OutFilterVal = 0.f;
		if(ConsumeAttribute(n"AudioSetHealthFilteringValue", OutFilterVal))
		{
			int32 Interpolation = 0;
			if(OutFilterVal == AudioHealthComp.AudioHealthParams.FilterAttackSlew)
			{
				OutFilterVal = 0.f;
				Interpolation = AudioHealthComp.AudioHealthParams.FilterAttackSlew;
			}
			else if(OutFilterVal == AudioHealthComp.AudioHealthParams.FilterReleaseSlew)
			{
				OutFilterVal = 1.f;
				Interpolation = AudioHealthComp.AudioHealthParams.FilterReleaseSlew;
			}

			SetFilteringRtpc(OutFilterVal, Interpolation);
		}
	}
}