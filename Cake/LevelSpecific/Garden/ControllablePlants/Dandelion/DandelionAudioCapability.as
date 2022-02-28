import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Peanuts.Audio.AudioStatics;

class UDandelionAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	ADandelion Dandelion;
	UDandelionSettings Settings;
	UHazeMovementComponent MoveComp;
	UHazeAkComponent DandelionAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnBecomingPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitPlant;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Dandelion = Cast<ADandelion>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		DandelionAkComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Dandelion.bDandelionActive)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DandelionAkComp.HazePostEvent(OnBecomingPlant);
		Settings = Dandelion.DandelionSettings;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Dandelion.bDandelionActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DandelionAkComp.HazePostEvent(OnExitPlant);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float DandelionHorizontalVelocity = MoveComp.ActualVelocity.Size2D();
		float DandelionVelocityNormalized = HazeAudio::NormalizeRTPC01(DandelionHorizontalVelocity, 0.0f, Settings.HorizontalVelocityMaximum);

		float CurrentFallVelocity = FMath::Clamp(MoveComp.ActualVelocity.Z, -Settings.FallSpeedMaximum, 500.0f);
		float FallSpeedNormalized = HazeAudio::NormalizeRTPC(CurrentFallVelocity, -Settings.FallSpeedMaximum, 500.0f, -1.0f, 1.0f);

		DandelionAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_Dandelion_HorizontalMovement", DandelionVelocityNormalized, 0.0f);
		DandelionAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_Dandelion_FallSpeed", FallSpeedNormalized, 0.0f);
	}
}
