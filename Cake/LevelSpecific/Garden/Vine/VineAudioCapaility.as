import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

class VineAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UPlayerHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioThrow;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioCatch;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioImpact;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioCrack;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioAttach;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AudioDetach;

	AHazePlayerCharacter Player;

	FHazeAudioEventInstance VineAttachLoopEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UPlayerHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkActivation::DontActivate;

		if(IsPlayerDead(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if (ConsumeAction(n"AudioVineThrow") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(AudioThrow);
			//PrintScaled("VineThrow", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioVineCatch") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(AudioCatch);
			//PrintScaled("VineCatch", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioVineImpact") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(AudioImpact);
			//PrintScaled("VineImpact", 0.5f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioVineCrack") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(AudioCrack);
			//PrintScaled("VineCrack", 0.5f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioVineAttach") == EActionStateStatus::Active)
		{
			VineAttachLoopEventInstance = HazeAkComp.HazePostEvent(AudioAttach);
			//PrintScaled("VineAttach", 0.5f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioVineDetach") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(AudioDetach);
			//PrintScaled("VineAttach", 0.5f, FLinearColor::Red, 2.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HazeAkComp.EventInstanceIsPlaying(VineAttachLoopEventInstance))
			HazeAkComp.HazeStopEvent(VineAttachLoopEventInstance.PlayingID, 100.f);
	}
}