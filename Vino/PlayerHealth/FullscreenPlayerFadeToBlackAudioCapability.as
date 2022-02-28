/*
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Peanuts.Fades.FadeManagerComponent;
import Vino.PlayerHealth.PlayerHealthAudioComponent;

class UFullscreenPlayerFadeToBlackAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthAudioComponent AudioHealthComp;
	UPlayerHealthComponent HealthComp;
	UFadeManagerComponent FadeComp;

	private float LastFadeAlpha = 0.f;
	private bool bFadeInStarted = false;

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

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;
			
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;

		if(FadeComp.bIsFadingFromLoading)
			return EHazeNetworkActivation::DontActivate;

		if(RespawnComp.bIsGameOver)
			return EHazeNetworkActivation::DontActivate;

		if(!Player.MovementComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(FadeComp.CurrentFadeAlpha <= LastFadeAlpha)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue(AudioHealthComp.AudioHealthParams.FilteringRTPC, 0.f, AudioHealthComp.AudioHealthParams.FilterAttackSlew);
		bFadeInStarted = false;
		
		if(Player.IsMay() && Player.OtherPlayer.FadeOutPercentage > 0)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_GameOver_IsActivated", 1.f);	
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(FadeComp.CurrentFadeAlpha < LastFadeAlpha)
		{
			ResetFadeRtpc();
			bFadeInStarted = true;
		}
		else
			bFadeInStarted = false;

		LastFadeAlpha = FadeComp.CurrentFadeAlpha;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bFadeInStarted && FadeComp.CurrentFadeAlpha == LastFadeAlpha)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	void ResetFadeRtpc()
	{
		if(bFadeInStarted)
			return;

		if(!RespawnComp.bIsGameOver)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue(AudioHealthComp.AudioHealthParams.FilteringRTPC, 1.f, AudioHealthComp.AudioHealthParams.FilterReleaseSlew);
			if(Player.IsMay())
			{
				UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_GameOver_IsActivated", 0.f);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		LastFadeAlpha = FadeComp.CurrentFadeAlpha; 

		if(!bFadeInStarted)
			ResetFadeRtpc();
	}
}
*/