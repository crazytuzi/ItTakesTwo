import Peanuts.Audio.AudioStatics;
import Vino.Audio.Capabilities.AudioTags;
import Vino.PlayerHealth.PlayerHealthComponent;

class UPlayerHealthAudioComponent : UActorComponent
{	

	UPROPERTY(Category = "Healthbar")
	UAkAudioEvent StartHealthDecayEvent;

	UPROPERTY(Category = "Healthbar")
	UAkAudioEvent StartHealthRegenEvent;

	UPROPERTY(Category = "Healthbar")
	UAkAudioEvent PlayerFullHealthEvent;

	UPROPERTY(Category = "Healthbar")
	UAkAudioEvent StartLowHealthEvent;

	UPROPERTY(Category = "Healthbar")
	UAkAudioEvent StopLowHealthEvent;

	UPROPERTY(Category = "Character")
	UAkAudioEvent PlayerDamagedEvent;

	UPROPERTY(Category = "Character")
	UAkAudioEvent OnPlayerStartTakingDamageEvent;

	UPROPERTY(Category = "Character")
	UAkAudioEvent OnPlayerStartConstantDamageEvent;

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayerDiedEvent;	

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayerStartRespawningEvent;

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayerRespawnSpeedupEvent;

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayerRespawnSpeedupFailEvent;
	
	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayerRespawnCompleteEvent;

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayersGameOverEvent;

	UPROPERTY(Category = "Respawning")
	UAkAudioEvent PlayersGameOverRespawnEvent;

	AHazePlayerCharacter Player;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UPlayerHealthComponent OtherPlayerHealthComp;
	FPlayerHealthAudioParams AudioHealthParams;

	bool bRespawnWidgetActive = false;

	bool bHasPerformedRespawnComplete = false;
	bool bIsDecayingHealth = false;

	FHazeAudioEventInstance RespawningLoopEventInstance;
	FHazeAudioEventInstance HealthDecayEventInstance;
	FHazeAudioEventInstance HealthRegenEventInstance;
	FHazeAudioEventInstance ConstantDamageEventInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerHazeAkComp = Player.PlayerHazeAkComp != nullptr? Player.PlayerHazeAkComp : UPlayerHazeAkComponent::Get(Player);
		OtherPlayerHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		AudioHealthParams = HazeAudio::GetHealthAudioParams(Player);	
	}

	UFUNCTION()
	void StartLowHealth()
	{
		PlayerHazeAkComp.HazePostEvent(StartLowHealthEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION()
	void StopLowHealth()
	{
		PlayerHazeAkComp.HazePostEvent(StopLowHealthEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION()
	void PlayerTookDamage(const float& RtpcValue)
	{

	}

	UFUNCTION()
	void StartConstantDamage()
	{
		if(!PlayerHazeAkComp.EventInstanceIsPlaying(ConstantDamageEventInstance))
		{
			ConstantDamageEventInstance = PlayerHazeAkComp.HazePostEvent(OnPlayerStartConstantDamageEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
		}


	}

	UFUNCTION()
	void StartHealthDecay()
	{
		if(!PlayerHazeAkComp.EventInstanceIsPlaying(HealthDecayEventInstance))
		{
			HealthDecayEventInstance = PlayerHazeAkComp.HazePostEvent(StartHealthDecayEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
			bIsDecayingHealth = HealthDecayEventInstance.PlayingID != 0;
		}

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_UI_Health_ConstantDamage_IsActive", 1.f);
	}
	
	UFUNCTION()
	void StopHealthDecay()
	{
		if(PlayerHazeAkComp.EventInstanceIsPlaying(HealthDecayEventInstance))
		{
			PlayerHazeAkComp.HazeStopEvent(HealthDecayEventInstance.PlayingID);
			bIsDecayingHealth = false;
		}
	}

	UFUNCTION()
	void PlayerDied()
	{
		Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::PlayerHealthValue, 0.f);
		Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::RespawnProgressValue, 0.f);

		UAkAudioEvent DeathEvent = OtherPlayerHealthComp.bIsDead ? PlayersGameOverEvent : PlayerDiedEvent;

		Player.PlayerHazeAkComp.HazePostEvent(DeathEvent);
	}

	UFUNCTION()
	void StartHealthRegen(const float& HealedAmount)
	{
		HealthRegenEventInstance = PlayerHazeAkComp.HazePostEvent(StartHealthRegenEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION()
	void PlayerFullHealth()
	{
		PlayerHazeAkComp.HazePostEvent(PlayerFullHealthEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION()
	void OnStartRespawning()
	{
		if(!Player.IsAnyCapabilityActive(AudioTags::FullScreenListener))
			UHazeAkComponent::HazeSetGlobalRTPCValue(AudioHealthParams.FilteringRTPC, 0.f, 0.f);

		RespawningLoopEventInstance = PlayerHazeAkComp.HazePostEvent(PlayerStartRespawningEvent, PostEventType = EHazeAudioPostEventType::UIEvent);

		//PrintToScreenScaled("OnStartRespawning", 1.f);
	}

	UFUNCTION()
	void OnRespawningSpeedup(const float& NumSpeedups)
	{
		PlayerHazeAkComp.HazePostEvent(PlayerRespawnSpeedupEvent);

		if(NumSpeedups == 2 && PlayerHazeAkComp.EventInstanceIsPlaying(RespawningLoopEventInstance))
			PlayerHazeAkComp.HazeStopEvent(RespawningLoopEventInstance.PlayingID);			
	}

	UFUNCTION()
	void OnRespawningSpeedupFailed()
	{
		PlayerHazeAkComp.HazePostEvent(PlayerRespawnSpeedupFailEvent, PostEventType = EHazeAudioPostEventType::UIEvent);
	}

	UFUNCTION()
	void OnRespawnComplete()
	{
		bHasPerformedRespawnComplete = true;
		PlayerHazeAkComp.HazePostEvent(PlayerRespawnCompleteEvent, PostEventType = EHazeAudioPostEventType::UIEvent);

		//PrintToScreenScaled("OnRespawnComplete", 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		if(PlayerHazeAkComp.EventInstanceIsPlaying(RespawningLoopEventInstance))
			PlayerHazeAkComp.HazeStopEvent(RespawningLoopEventInstance.PlayingID);	

		if(PlayerHazeAkComp.EventInstanceIsPlaying(HealthRegenEventInstance))
			PlayerHazeAkComp.HazeStopEvent(HealthRegenEventInstance.PlayingID);						
	}		
}