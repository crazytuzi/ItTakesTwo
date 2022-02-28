import Peanuts.Audio.AudioStatics;
import Peanuts.Foghorn.FoghornStatics;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Peanuts.Fades.FadeManagerComponent;

class UPlayerDeathFadeToBlackAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UFadeManagerComponent FadeComp;

	private float FilterHoldTime = 0.f;
	private bool bReleaseFilter = false;
	private float LastFadeAlpha = 0;
	bool bFadeInStarted = false;
	bool bForceDeactivation = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		AudioHealthComp = UPlayerHealthAudioComponent::Get(Player);
		FadeComp = UFadeManagerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FadeComp.bIsFadingFromLoading)
			return EHazeNetworkActivation::DontActivate;

		if(RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;

		if(FadeComp.CurrentFadeAlpha <= LastFadeAlpha)
			return EHazeNetworkActivation::DontActivate;

		if(RespawnComp.HealthSettings.bDisplayHealth && RespawnComp.bIsRespawning)
			return EHazeNetworkActivation::DontActivate;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Always check forced deactivation first
		if(bForceDeactivation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!bReleaseFilter)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!bFadeInStarted)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(FadeComp.CurrentFadeAlpha < LastFadeAlpha)
			return EHazeNetworkDeactivation::DontDeactivate;
			
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		FilterHoldTime = 0.f;
		bReleaseFilter = false;
		Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, AudioHealthComp.AudioHealthParams.FilterAttackSlew);
		Player.SetCapabilityActionState(n"AudioFadedToBlack", EHazeActionState::Active);	 
		bFadeInStarted = false;
		bForceDeactivation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FilterHoldTime += DeltaSeconds;
		bReleaseFilter = (FilterHoldTime >= AudioHealthComp.AudioHealthParams.FILTER_HOLD);	

		if(FadeComp.CurrentFadeAlpha < LastFadeAlpha)
		{
			ResetFilterRtpc();
			bFadeInStarted = true;
		}
		else
			bFadeInStarted = false;

		LastFadeAlpha = FadeComp.CurrentFadeAlpha;	

		// Handle a previously un-handled fade-in. This will happen if we paused during a fade which then ran in background. Deactivate immediately.
		if(!bFadeInStarted && FadeComp.CurrentFadeAlpha == 0)
		{
			bForceDeactivation = true;		
		}	
	}

	void ResetFilterRtpc()
	{
		if(bFadeInStarted)
			return;

		if(!RespawnComp.bIsGameOver)
			Player.SetCapabilityAttributeValue(AudioHealthComp.AudioHealthParams.CombinedHealthFilteringAttribute, AudioHealthComp.AudioHealthParams.FilterReleaseSlew);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		LastFadeAlpha = FadeComp.CurrentFadeAlpha; 
	}
}