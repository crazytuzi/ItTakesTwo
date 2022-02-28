import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.Audio.Capabilities.AudioTags;

class UPlayerRespawnAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerHealthComponent HealthComp;

	private float SpeedUpsCount = 0.f;	
	private bool bAudioRespawnComplete = false;	
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;

		if(!HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;		

		if(RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;

		if(!AudioHealthComp.bRespawnWidgetActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SpeedUpsCount = 0.f;
		AudioHealthComp.bHasPerformedRespawnComplete = false;
		bAudioRespawnComplete = false;		
		// Consume left overs
		float RespawnProgress = 0.f;
		ConsumeAttribute(n"AudioRespawnProgress", RespawnProgress);
		
		AudioHealthComp.OnStartRespawning();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(RespawnComp.bIsGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bAudioRespawnComplete)	
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!AudioHealthComp.bRespawnWidgetActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!RespawnComp.bIsGameOver)
		{
			Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::RespawnProgressValue, 1.f);			

			if(!Player.IsAnyCapabilityActive(AudioTags::FullScreenListener))
				Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, 1.f);
		}

		if(AudioHealthComp.PlayerHazeAkComp.HazeIsEventActive(AudioHealthComp.RespawningLoopEventInstance.EventID) && !bAudioRespawnComplete)
			AudioHealthComp.PlayerHazeAkComp.HazeStopEvent(AudioHealthComp.RespawningLoopEventInstance.PlayingID);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float RespawnProgress = 0.f;
		ConsumeAttribute(n"AudioRespawnProgress", RespawnProgress);
		Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::RespawnProgressValue, RespawnProgress);

		//Print("RespawnProgress: " + RespawnProgress, 0.f);

		if(!Player.IsAnyCapabilityActive(AudioTags::FullScreenListener))
			Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, RespawnProgress);

		if(ConsumeAction(n"AudioHitRespawnSpeedup") == EActionStateStatus::Active)
		{
			AudioHealthComp.OnRespawningSpeedup(SpeedUpsCount);
			SpeedUpsCount ++;
		}		

		if(ConsumeAction(n"AudioFailedRespawnSpeedup") == EActionStateStatus::Active)
			AudioHealthComp.OnRespawningSpeedupFailed();		

		if(FMath::IsNearlyEqual(RespawnProgress, 1, 0.01f) && !AudioHealthComp.bHasPerformedRespawnComplete)
		{
			AudioHealthComp.OnRespawnComplete();
		}

		if(!HealthComp.bIsDead && AudioHealthComp.bHasPerformedRespawnComplete)
			bAudioRespawnComplete = true;
	}
}