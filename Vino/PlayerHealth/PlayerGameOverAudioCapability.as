import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Peanuts.Fades.FadeManagerComponent;

class UPlayerGameOverAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerHealthComponent HealthComp;
	UFadeManagerComponent FadeComp;

	default CapabilityTags.Add(n"GameOverAudio");

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);	
		FadeComp = UFadeManagerComponent::Get(Player);
	}

	private bool bFadeInStarted = false;
	private float LastFadeAlpha = 0.f;
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!RespawnComp.bIsGameOver && !RespawnComp.bAudioGamerOverIsDirty)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(RespawnComp.bIsGameOver || RespawnComp.bIsAudioGameOver)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!bFadeInStarted)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(Game::IsInLoadingScreen())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)	
	{		
		Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, 0.f);

		bFadeInStarted = false;
		LastFadeAlpha = 0.f;

		if(Player.IsMay())
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_GameOver_IsActivated", 1.f);	

		RespawnComp.bAudioGamerOverIsDirty = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(FadeComp.CurrentFadeAlpha < LastFadeAlpha)
			bFadeInStarted = true;

		LastFadeAlpha = FadeComp.CurrentFadeAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, 1.f);		
		if(Player.IsMay())
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_GameOver_IsActivated", 0.f);
			Player.PlayerHazeAkComp.HazePostEvent(AudioHealthComp.PlayersGameOverRespawnEvent);
		}
	}	
}