import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlant;

class UTurretPlantAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnBecomingPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitPlant;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitSoil;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnTurretReload;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnTurretShoot;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BulletWhiz;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BulletImpact;

	ATurretPlant TurretPlant;
	UHazeAkComponent TurretPlantAkComp;
	URangedWeaponComponent RangedWeapon;
	
	private bool bHasPlayedExit = false;
	private FHazeAudioEventInstance OnEnterEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TurretPlant = Cast<ATurretPlant>(Owner);
		TurretPlantAkComp = UHazeAkComponent::GetOrCreate(Owner);
		RangedWeapon = URangedWeaponComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TurretPlant.bActive)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		OnEnterEventInstance = TurretPlantAkComp.HazePostEvent(OnBecomingPlant);
		//PrintScaled("OnBecomingPlant", 2.f, FLinearColor::Black, 2.f);
		bHasPlayedExit = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TurretPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bHasPlayedExit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(TurretPlantAkComp.EventInstanceIsPlaying(OnEnterEventInstance))
			TurretPlantAkComp.HazeStopEvent(OnEnterEventInstance.PlayingID);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"TurretPlantReload_Audio") == EActionStateStatus::Active)
		{
			TurretPlantAkComp.HazePostEvent(OnTurretReload);
			//PrintScaled("OnTurretReload", 2.f, FLinearColor::Black, 2.f);
		}

		FVector FireLoc;

		if(ConsumeAttribute(n"TurretPlantFireLocation", FireLoc))
		{
			UHazeAkComponent::HazePostEventFireForget(BulletWhiz, FTransform(FireLoc));
			TurretPlantAkComp.HazePostEvent(OnTurretShoot);
			//PrintScaled("OnTurretShoot", 2.f, FLinearColor::Black, 2.f);
			
			FVector WizzbyLoc;
			
			if(ConsumeAttribute(n"TurretPlantWhizLocation", WizzbyLoc))
			{
				UHazeAkComponent::HazePostEventFireForget(BulletWhiz, FTransform(WizzbyLoc));
				//PrintScaled("BulletWhiz", 2.f, FLinearColor::Black, 2.f);
			}

			FVector ImpactLocation;

			if(ConsumeAttribute(n"TurretPlantBulletImpact", ImpactLocation))
			{
				UObject MaterialImpactEventObject = nullptr;
				if(ConsumeAttribute(n"TurretPlantImpactEvent", MaterialImpactEventObject))
				{
					UAkAudioEvent MaterialImpactEvent = Cast<UAkAudioEvent>(MaterialImpactEventObject);
					UHazeAkComponent::HazePostEventFireForget(MaterialImpactEvent, FTransform(ImpactLocation));
				}
				else
				{
					UHazeAkComponent::HazePostEventFireForget(BulletImpact, FTransform(ImpactLocation));
					//PrintScaled("BulletImpact", 2.f, FLinearColor::Black, 2.f);
				}
			}

		}

		if(ConsumeAction(n"OnExitPlant") == EActionStateStatus::Active)
		{
			TurretPlantAkComp.HazePostEvent(OnExitPlant);
			//PrintScaled("OnExitPlant", 2.f, FLinearColor::Black, 2.f);

			if(OnExitSoil == nullptr)
				bHasPlayedExit = true;
		}

		if(ConsumeAction(n"Audio_OnExitSoil") == EActionStateStatus::Active)
		{
			Game::GetCody().PlayerHazeAkComp.HazePostEvent(OnExitSoil);
			bHasPlayedExit = true;
		}
		
		const float YawRotationDelta = HazeAudio::NormalizeRTPC01(FMath::Abs(TurretPlant.YawRotationDelta), 0.0f, 10.0f);
		const float PitchRotationDelta = HazeAudio::NormalizeRTPC01(FMath::Abs(TurretPlant.PitchRotationDelta), 0.0f, 1.0f);

		TurretPlantAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_CactusTurret_RotationVelocity", YawRotationDelta, 0.f);

		TurretPlantAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_CactusTurret_PitchVelocity", PitchRotationDelta, 0.f);

		TurretPlantAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_CactusTurret_AmmoAmount", RangedWeapon.GetRemainingAmmoInClipAsFraction(), 0.f);

		TurretPlantAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_CactusTurret_IsZooming", TurretPlant.ZoomFraction, 0.f);
	}
}
