import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;

class UMagnetHarpoonSpearToOriginCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonSpearToOriginCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor MagnetHarpoon;

	// FHazeAcceleratedFloat AccelFloat;

	bool bAudioOn;
	bool bReturnSoundPlaying = false;

	int RandomPlayer;

	bool bFirstTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(Owner);
		bFirstTime = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (MagnetHarpoon.HarpoonSpearState == EHarpoonSpearState::ToOrigin /* && MagnetHarpoon.CanPendingFire()*/)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (MagnetHarpoon.HarpoonSpearState != EHarpoonSpearState::ToOrigin)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (RandomPlayer == 0)
			RandomPlayer = FMath::RandRange(2, 4);	

		RandomPlayer--;

		OutParams.AddNumber(n"RandomPlayer", RandomPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bAudioOn = true;

		if (!MagnetHarpoon.bGotCatch)
			MagnetHarpoon.SetClawState(EHarpoonClawAnimState::Closed);

		MagnetHarpoon.AkCompHarpoon.HazePostEvent(MagnetHarpoon.ClawCloseAudioEvent);
		MagnetHarpoon.AkCompHarpoon.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_MagnetHarpoon_Line", 0.f);
			// Set Rtpc to 0 here and post claw event
		MagnetHarpoon.ResetWaterSplash();
		MagnetHarpoon.AccelSpearSpeed.SnapTo((MagnetHarpoon.SpearSpeed * 0.2f));
		MagnetHarpoon.BlockCapabilities(n"MagnetHarpoonRotationCapability", this);
		MagnetHarpoon.AudioStopGunMovement();

		RandomPlayer = ActivationParams.GetNumber(n"RandomPlayer");

		System::SetTimer(this, n"DelayedVOReaction", 0.4f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (MagnetHarpoon.UsingPlayer != nullptr)
		{
			UHarpoonPlayerComponent Comp = UHarpoonPlayerComponent::Get(MagnetHarpoon.UsingPlayer); 
			Comp.PlayFeedback(MagnetHarpoon.UsingPlayer, 0.25f);
		}

		MagnetHarpoon.UnblockCapabilities(n"MagnetHarpoonRotationCapability", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MagnetHarpoon.SpearTargetLocation = MagnetHarpoon.SpearAttached.WorldLocation;

		MagnetHarpoon.AccelSpearSpeed.AccelerateTo((MagnetHarpoon.SpearSpeed * 1.5f), 1.5f, DeltaTime);

		float Distance = (MagnetHarpoon.HarpoonSpearSkel.WorldLocation - MagnetHarpoon.SpearAttached.WorldLocation).Size();
		FMath::Abs(Distance);

		if (Distance <= 10.f && MagnetHarpoon.GetCatch())
			MagnetHarpoon.SetCanRelease(true);

		if (Distance <= 700.f && !bReturnSoundPlaying)
		{
			MagnetHarpoon.AudioHarpoonReturn();
			bReturnSoundPlaying = true;
		}	

		if (Distance <= 1.f && bAudioOn)
		{
			bAudioOn = false;
			bReturnSoundPlaying = false;
			MagnetHarpoon.AudioStopHarpoonMovement();
			MagnetHarpoon.HarpoonSpearState = EHarpoonSpearState::Still;
		}
	}

	UFUNCTION()
	void DelayedVOReaction()
	{
		if (!bFirstTime || RandomPlayer == 0)
		{
			if (MagnetHarpoon.bGotCatch)
				VOGotCatch();
			else
				VOMissedCatch();

			bFirstTime = true;
		}
	}

	UFUNCTION()
	void VOGotCatch()
	{
		if (MagnetHarpoon.UsingPlayer == nullptr)
			return;

		if (MagnetHarpoon.UsingPlayer.IsMay())
			PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonCatchFishMay");
		else
			PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonCatchFishCody");
	}

	UFUNCTION()
	void VOMissedCatch()
	{
		if (MagnetHarpoon.UsingPlayer == nullptr)
			return;

		if (MagnetHarpoon.UsingPlayer.IsMay())
			PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonMissMay");
		else
			PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonMissCody");
	}
}