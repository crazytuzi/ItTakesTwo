import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Mage.CastleMageBeamUltimateComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

class UCastlePlayerMageBeamUltimateAudioCapability : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent BeamActivatedEvent;

	UPROPERTY()
	UAkAudioEvent BeamStoppedEvent;

	UPROPERTY()
	UAkAudioEvent StartImpactEvent;

	UPROPERTY()
	UAkAudioEvent StopImpactEvent;

	UHazeAkComponent BeamImpactHazeAkComp;
	FHazeAudioEventInstance BeamImpactEventInstance;
	private float LastBeamLength;
	FVector2D LastImpactScreenPos;

	AHazePlayerCharacter Player;
	UCastleComponent CastleComp;
	UCastleMageBeamUltimateComponent UltComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeamImpactHazeAkComp = UHazeAkComponent::Create(Player, n"BeamImpactHazeAkComp");
		CastleComp = UCastleComponent::Get(Player);
		UltComp = UCastleMageBeamUltimateComponent::Get(Player);
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!CastleComp.bComboCanAttack)
			return EHazeNetworkActivation::DontActivate;   

		if (!UltComp.bActivated)
			return EHazeNetworkActivation::DontActivate;  

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.PlayerHazeAkComp.HazePostEvent(BeamActivatedEvent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UltComp.bActivated)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.PlayerHazeAkComp.HazePostEvent(BeamStoppedEvent);

		if(BeamImpactHazeAkComp.EventInstanceIsPlaying(BeamImpactEventInstance))	
			BeamImpactHazeAkComp.HazePostEvent(StopImpactEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bIsPlayingImpactEvent = BeamImpactHazeAkComp.EventInstanceIsPlaying(BeamImpactEventInstance);
		if(UltComp.bLastHitBlocking)
		{
			BeamImpactHazeAkComp.SetWorldLocation(UltComp.BeamEnd);
			FVector2D ImpactScreenPos;
			if(SceneView::ProjectWorldToScreenPosition(Player, UltComp.BeamEnd, ImpactScreenPos))
			{
				if(ImpactScreenPos.X != LastImpactScreenPos.X)
				{
					const float NormalizedScreenPos = HazeAudio::NormalizeRTPC(ImpactScreenPos.X, 0.f, 1.f, -1.f, 1.f);
					HazeAudio::SetPlayerPanning(BeamImpactHazeAkComp, nullptr, NormalizedScreenPos);
					LastImpactScreenPos = ImpactScreenPos;
				}
			}

			if(!bIsPlayingImpactEvent)
				BeamImpactEventInstance = BeamImpactHazeAkComp.HazePostEvent(StartImpactEvent);
		}
		else if(bIsPlayingImpactEvent)
			BeamImpactHazeAkComp.HazePostEvent(StopImpactEvent);

		const float NormalizedBeamLength = HazeAudio::NormalizeRTPC01(UltComp.BeamLength / 100, 0.f, 30.f);

		if(NormalizedBeamLength != LastBeamLength)
		{
			BeamImpactHazeAkComp.SetRTPCValue("Rtpc_Abilities_Spells_IceBeam_Length", NormalizedBeamLength);
			LastBeamLength = NormalizedBeamLength;
		}
	}
}