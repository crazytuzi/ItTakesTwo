import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelVehicle;

class MusicTunnelVehicleAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	AMusicTunnelVehicle MusicTunnelVehicle;
	AHazePlayerCharacter PlayerOwner;

	private float LastTurningValue;
	private int32 BoostCount = 0;
	private float TimeSinceLastBoost = 0;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent JumpEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LandEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TakeDamageEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BoostEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicTunnelVehicle = Cast<AMusicTunnelVehicle>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UObject RawObject;

		if (ConsumeAttribute(n"MusicTunnelVehicleStartAudioEvent", RawObject))
		{
			PlayerOwner = Cast<AHazePlayerCharacter>(RawObject);
			if (PlayerOwner != nullptr)
			{
				PlayerOwner.PlayerHazeAkComp.HazePostEvent(StartEvent);
				//PrintScaled("MusicTunnelVehicleStartAudioEvent", 2.f, FLinearColor::Black, 2.f);
			}
		}

		if (PlayerOwner == nullptr)
			return;

		if (ConsumeAction(n"MusicTunnelVehicleTakeDamageAudioEvent") == EActionStateStatus::Active)
		{
			PlayerOwner.PlayerHazeAkComp.HazePostEvent(TakeDamageEvent);
			//PrintScaled("MusicTunnelVehicleTakeDamageAudioEvent", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"MusicTunnelVehicleBoostAudioEvent") == EActionStateStatus::Active)
		{
			PlayerOwner.PlayerHazeAkComp.HazePostEvent(BoostEvent);
			//PrintScaled("MusicTunnelVehicleBoostAudioEvent", 2.f, FLinearColor::Black, 2.f);
			BoostCount ++;
			TimeSinceLastBoost = 0.f;
			PlayerOwner.PlayerHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Vehicles_MusicTunnelVehicle_BoostCount", FMath::Min(BoostCount, 4));
			//Print("BoostCount" + BoostCount, 2.f);
		}

		if (ConsumeAction(n"MusicTunnelVehicleJumpAudioEvent") == EActionStateStatus::Active)
		{
			PlayerOwner.PlayerHazeAkComp.HazePostEvent(JumpEvent);
			//PrintScaled("MusicTunnelVehicleJumpAudioEvent", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"MusicTunnelVehicleLandAudioEvent") == EActionStateStatus::Active)
		{
			PlayerOwner.PlayerHazeAkComp.HazePostEvent(LandEvent);
			//PrintScaled("MusicTunnelVehicleLandAudioEvent", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"MusicTunnelVehicleStopAudioEvent") == EActionStateStatus::Active)
		{
			PlayerOwner.PlayerHazeAkComp.HazePostEvent(StopEvent);
			//PrintScaled("MusicTunnelVehicleStopAudioEvent", 2.f, FLinearColor::Black, 2.f);
		}

		//Velocity
		float MusicTunnelVehicleVelocity = GetAttributeValue(n"MusicTunnelVehicleAudioVelocity");
		float NormalizedMusicTunnelVehicleVelocity = HazeAudio::NormalizeRTPC01(MusicTunnelVehicleVelocity, 0.f, 7000.f);
		PlayerOwner.PlayerHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Vehicles_MusicTunnelVehicle_Velocity", NormalizedMusicTunnelVehicleVelocity);

		//Print("Velocity: " + NormalizedMusicTunnelVehicleVelocity, 0.f);

		//Turning
		float MusicTunnelVehicleTurning = GetAttributeValue(n"MusicTunnelVehicleAudioTurning");
		if (MusicTunnelVehicleTurning != LastTurningValue)
			{
				PlayerOwner.PlayerHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Vehicles_MusicTunnelVehicle_IsTurning", FMath::Abs(MusicTunnelVehicleTurning));
				LastTurningValue = MusicTunnelVehicleTurning;
			}
		
		//Print("IsTurning: " + FMath::Abs(MusicTunnelVehicleTurning), 0.f);


		//IsJumping
		float MusicTunnelVehicleIsJumping = GetAttributeValue(n"MusicTunnelVehicleAudioIsJumping");
		PlayerOwner.PlayerHazeAkComp.SetRTPCValue("Rtpc_Gameplay_Vehicles_MusicTunnelVehicle_IsJumping", MusicTunnelVehicleIsJumping);

		//Print("IsJumping: " + MusicTunnelVehicleIsJumping, 0.f);
	
		//BoostCount
		if (BoostCount > 0)
		{
			TimeSinceLastBoost += DeltaTime;
			if (TimeSinceLastBoost >= 3.f)
				BoostCount = 0;

		}

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//if (PlayerOwner == nullptr)
		//	return;
		//PlayerOwner.PlayerHazeAkComp.HazePostEvent(StopEvent);
		//PrintScaled("MusicTunnelVehicleStopAudioEvent", 2.f, FLinearColor::Black, 2.f);
	}
}