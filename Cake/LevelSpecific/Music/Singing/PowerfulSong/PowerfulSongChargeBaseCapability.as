import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongPlayerUserComponent;
import Peanuts.SpeedEffect.SpeedEffectStatics;

UCLASS(Abstract)
class UPowerfulSongChargeBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"PowerfulSong");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	USingingComponent SingingComp;
	AHazePlayerCharacter Player;
	UPowerfulSongPlayerUserComponent SongUserComponent;

	UCameraShakeBase CameraShake;

	float Cooldown = 0.0f;
	float TargetCooldown = 0.1f;
	
	float CurrentCharge = 0.0f;
	float ChargeTarget = 0.25f;
	float ChargeTotal = 0.3f;

	bool bChargeFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingingComp = USingingComponent::Get(Owner);
		SongUserComponent = UPowerfulSongPlayerUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SingingComp.bChargingPowerfulSong = true;
		bChargeFinished = false;
		CurrentCharge = 0.0f;
		Cooldown = 0.0f;

		if(SingingComp.ChargingCameraShake.IsValid())
		{
			CameraShake = Player.PlayCameraShake(SingingComp.ChargingCameraShake, 0.1f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(bChargeFinished)
			SyncParams.AddActionState(n"ChargeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		const bool bFirePowerfulSong = DeactivationParams.GetActionState(n"ChargeFinished");
		
		if(bFirePowerfulSong)
		{
			SongUserComponent.bWantsToShoot = true;
			Player.PlayForceFeedback(SingingComp.PowerfulSongForceFeedback, false, false, n"PowerfulSong");
			Cooldown = TargetCooldown;

			if(SingingComp.ShootingCameraShake.IsValid())
			{
				Player.PlayCameraShake(SingingComp.ShootingCameraShake);
			}
		}
		
		SingingComp.bChargingPowerfulSong = false;
		Player.ClearFieldOfViewByInstigator(this);
		StopCameraShake();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bChargeFinished)
		{
			const float ChargeIncrease = 0.0f;
			CurrentCharge = FMath::Min(CurrentCharge + (ChargeIncrease > 0.99f ? 1.0f : 0.0f) * DeltaTime, ChargeTotal);

			float ForceFeedbackIntensity = FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(0.25f, 0.85f), ChargeIncrease);
			float PowedForceFeedback = FMath::Pow(ForceFeedbackIntensity, 5.0f);

			Player.SetFrameForceFeedback(PowedForceFeedback, PowedForceFeedback);

			if(CameraShake != nullptr)
			{
				CameraShake.ShakeScale = ChargeIncrease;
			}

			if(CurrentCharge >= ChargeTotal)
			{
				bChargeFinished = true;
			}

			SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(ChargeIncrease, this));
		}
	}

	void StopCameraShake()
	{
		if(CameraShake != nullptr)
		{
			Player.StopCameraShake(CameraShake);
			CameraShake = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Cooldown -= DeltaTime;
	}
}
