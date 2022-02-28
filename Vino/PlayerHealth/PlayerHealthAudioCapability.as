import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Vino.PlayerHealth.PlayerHealthDisplayCapability;
import Vino.Audio.Capabilities.AudioTags;

class UPlayerHealthAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HealthDisplay");

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerHealthDisplayWidget HealthWidget;
	
	protected float LastHealthRtpcValue = 0.f;
	protected float LastHealthValue;
	protected float LastHealthDeltaRtpcValue;
	protected float LastDecayStartAmount = 0.f;
	protected float RegenHealthDeltaSeconds = 0.f;

	protected bool bIsRegenerating = false;
	protected bool bNeedsCachedDecayStartAmount = true;
	protected bool bHasPerformedDeath = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Player);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HealthComp.HealthSettings.bDisplayHealth)
			return EHazeNetworkActivation::DontActivate;

		if(HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HealthComp.HealthSettings.bDisplayHealth)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(HealthComp.bIsDead && bHasPerformedDeath)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AudioHealthComp.StartLowHealth();	

		// Consume potential missed attributes from before activation
		int32 ClearAttribute;
		ConsumeAttribute(n"AudioDamagedHealth", ClearAttribute);
		ConsumeAttribute(n"AudioHealthRegen", ClearAttribute);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AudioHealthComp.StopLowHealth();
		bHasPerformedDeath = false;	

		// If deactivated while regenerating health, force stop the event from here
		if(AudioHealthComp.PlayerHazeAkComp.HazeIsEventActive(AudioHealthComp.HealthRegenEventInstance.EventID))
			AudioHealthComp.PlayerHazeAkComp.HazeStopEvent(AudioHealthComp.HealthRegenEventInstance.PlayingID);

		// Safety check to make sure that we don't get stuck in filtering
		if(!HealthComp.bIsDead)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue(AudioHealthComp.AudioHealthParams.FilteringRTPC, 1);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const float CurrentHealth = HealthComp.CurrentHealth;
		if(ConsumeAction(n"AudioPlayerDied") == EActionStateStatus::Active)
		{
			AudioHealthComp.PlayerDied();
			LastHealthRtpcValue = -1.f;
			bHasPerformedDeath = true;
		}
		
		if(!HealthComp.bIsDead)
		{
			if(ConsumeAction(n"AudioFadedToBlack") == EActionStateStatus::Active)
				LastHealthRtpcValue = -1.f;

			if(HealthComp.CurrentHealth != LastHealthRtpcValue)
			{
				Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::PlayerHealthValue, CurrentHealth);							
				LastHealthRtpcValue = CurrentHealth;
			}

			float RawDamagedValue = 0.f;
			if(ConsumeAttribute(n"AudioDamagedHealth", RawDamagedValue))
			{
				Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::PlayerHealthDelta, RawDamagedValue);				
			}

			if(HealthComp.bStartedDamageCharge)
			{
				AudioHealthComp.StartHealthDecay();
				const float DecayHealthRtpcValue = CurrentHealth + HealthComp.RecentlyLostHealth;				

				if(bNeedsCachedDecayStartAmount)
				{
					LastDecayStartAmount = 1 - CurrentHealth;
					Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::HealthDecayStartAmount, LastDecayStartAmount);								
					bNeedsCachedDecayStartAmount = false;
				}				
			}
			else if(AudioHealthComp.bIsDecayingHealth)
			{
				AudioHealthComp.StopHealthDecay();			
				bNeedsCachedDecayStartAmount = true;
			}

			const float HealthDeltaRtpcValue = CurrentHealth == LastHealthValue ? 0.f : 1.f;
		}

		float HealedHealth = 0.f;
		if(ConsumeAttribute(n"AudioHealthRegen", HealedHealth))
		{
			RegenHealthDeltaSeconds = 0.f;				
			AudioHealthComp.StartHealthRegen(HealedHealth);		
			bIsRegenerating = true;
		}
	
		if(bIsRegenerating)
		{
			RegenHealthDeltaSeconds += DeltaSeconds;
			if(HealthComp.RecentlyRegeneratedHealth == 0)
			{
				bIsRegenerating = false;
				AudioHealthComp.PlayerFullHealth();
			}
		}		
	}
}
