import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;
import Vino.Movement.Components.MovementComponent;

class USeedSprayerPlantAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	ASeedSprayerPlant SeedSprayer;
	USeedSprayerPlantMovementComponent MoveComp;
	UHazeAkComponent SeedSprayerAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnBecomingPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnChangeColor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SeedSprayerAkComp = UHazeAkComponent::GetOrCreate(Owner);
		SeedSprayerAkComp.bUseAutoDisable = false;
		MoveComp = USeedSprayerPlantMovementComponent::Get(Owner);
		SeedSprayer = Cast<ASeedSprayerPlant>(Owner);
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
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SeedSprayerAkComp.HazePostEvent(OnExitPlant);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ConsumeAction(n"AudioOnBecomeSeedSprayer") == EActionStateStatus::Active)
		{
			SeedSprayerAkComp.HazePostEvent(OnBecomingPlant);
			//PrintScaled("On Become SeedSprayer", 2.f, FLinearColor::Green, 2.f);
		}
	
		if (ConsumeAction(n"AudioChangeColorSeedSprayer") == EActionStateStatus::Active)
		{
			SeedSprayerAkComp.HazePostEvent(OnChangeColor);
			//PrintScaled("On Change Color SeedSprayer", 2.f, FLinearColor::Green, 2.f);
		}

		float SeedSprayerVelocity = MoveComp.GetActualVelocity().Size();
		float SeedSprayerVelocityNormalized = HazeAudio::NormalizeRTPC01(SeedSprayerVelocity, 0.f, 850.f);
		SeedSprayerAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_Seedsprayer_Velocity", SeedSprayerVelocityNormalized, 0.f);
		//PrintToScreen("SeedSprayerVelocity" + SeedSprayerVelocityNormalized);

		 float SeedSprayerAngularVelocity = MoveComp.GetRotationDelta();
		 float SeedSprayerAngularVelocityNormalized = HazeAudio::NormalizeRTPC01(SeedSprayerAngularVelocity, 0.f, 0.25f);
		 SeedSprayerAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_Seedsprayer_AngularVelocity", SeedSprayerAngularVelocityNormalized, 0.f);
		 //PrintToScreen("SeedSprayerRotationDelta" + SeedSprayerAngularVelocityNormalized);

	}


}