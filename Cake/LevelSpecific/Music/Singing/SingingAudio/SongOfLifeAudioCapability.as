import Cake.LevelSpecific.Music.Singing.SingingAudio.SingingAudioComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Peanuts.Foghorn.FoghornStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.MovementSystemTags;

class USongOfLifeAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SongOfLife");
	
	USingingComponent SingingComp;
	USingingAudioComponent SingingAudioComp;
	UMusicTargetingComponent TargetComp;
	AHazePlayerCharacter Player;

	bool bInteractionVFXActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SingingComp = USingingComponent::Get(Owner);
		SingingAudioComp = USingingAudioComponent::Get(Owner);
		TargetComp = UMusicTargetingComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SingingComp.GetSongOflifeCurrentState() != ESongOfLifeState::Singing)
			return EHazeNetworkActivation::DontActivate;

		if(TargetComp.bIsTargeting)
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsPlayerDead())
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetCanPlayEfforts(Player.PlayerHazeAkComp, false);
		SingingAudioComp.StartSongOfLife();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SingingComp.GetSongOflifeCurrentState() != ESongOfLifeState::Singing)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Game::IsInLoadingScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(Game::IsPausedForAnyReason())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		const bool bForceStop = Player.IsPlayerDead() || Player.bIsParticipatingInCutscene;
		if(!bForceStop)
			SingingAudioComp.StopSongOfLife();
		else
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_ActiveDuration", 0.f, 100);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_VocalIsActive", 0.f, 100);
		}
			
		SetCanPlayEfforts(Player.PlayerHazeAkComp, true);
		bInteractionVFXActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration <= 5.f && !bInteractionVFXActive)
		{
			const float NormalizedSongDuration = HazeAudio::NormalizeRTPC01(ActiveDuration, 0.f, 5.f);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_ActiveDuration", NormalizedSongDuration);
		}

		if(ConsumeAction(n"AudioSongInteractionEffectActive") == EActionStateStatus::Active)
		{
			bInteractionVFXActive = true;
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Gameplay_Abilities_SongOfLife_ActiveDuration", 1, 100);
		}

		if(ConsumeAction(n"AudioSongInteractionEffectInactive") == EActionStateStatus::Active)
		{
			bInteractionVFXActive = false;
		}
	}

}