import Vino.PlayerHealth.PlayerHealthAudioCapability;

class UFullscreenSharedHealthAudioCapability : UPlayerHealthAudioCapability
{	
	UPlayerRespawnComponent RespawnComp;
	bool bIsDecayingHealth = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Game::GetMay();
		HealthComp = UPlayerHealthComponent::Get(Player);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Player);		
		RespawnComp = UPlayerRespawnComponent::Get(Player);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds) override
	{
		if(RespawnComp.bIsGameOver || RespawnComp.bIsRespawning)
			return;

		const float CurrentHealth = HealthComp.CurrentHealth;

		float RawDamagedValue = 0.f;
		if(ConsumeAttribute(n"AudioDamagedHealth", RawDamagedValue))
		{
			Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::PlayerHealthDelta, RawDamagedValue);				
		}

		if(ConsumeAction(n"AudioStartDecayHealth") == EActionStateStatus::Active)
			bIsDecayingHealth = true;

		if(ConsumeAction(n"AudioStopDecayHealth") == EActionStateStatus::Active)
			bIsDecayingHealth = false;

		if(bIsDecayingHealth)
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