import Vino.Movement.Components.MovementComponent;

import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingSettings;
import Peanuts.SpeedEffect.SpeedEffectStatics;
import Vino.Camera.Settings.CameraVehicleChaseSettings;

settings NoLazyChaseSettings for UCameraVehicleChaseSettings
{
	NoLazyChaseSettings.CameraInputDelay = 1.f;
	NoLazyChaseSettings.MovementInputDelay = 0.1f;
	NoLazyChaseSettings.AccelerationDuration = 3.f;
};

class UClockworkBirdFlyingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkBirdFlying";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	// Movement Component
	AClockworkBird Bird;
	UClockworkBirdFlyingSettings Settings;
	AHazePlayerCharacter Player;
	UHazeActiveCameraUserComponent CameraUser;

	FHazeAcceleratedFloat FOVAccel;
	FVector CurrentLocalOffset;

	FRotator CameraControlRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Bird.bIsFlying && !Bird.bIsLanding)
			return EHazeNetworkActivation::DontActivate;
		if (Bird.ActivePlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Bird.bIsFlying && !Bird.bIsLanding)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (Bird.ActivePlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player = Bird.ActivePlayer;

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		//Bird.UseVehicleChaseCam(true);

		CameraUser = UHazeActiveCameraUserComponent::Get(Player);
		Player.ApplyCameraSettings(Bird.CameraSettings, BlendSettings, Instigator = this, Priority = EHazeCameraPriority::Low);
		Player.ApplySettings(NoLazyChaseSettings, Instigator = this);

		Player.ActivateCamera(Bird.FlightCamera, BlendSettings, this);

		FOVAccel.SnapTo(70.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(Instigator = this);
		Player.DeactivateCameraByInstigator(this);
		Player.StopAllInstancesOfCameraShake(Bird.HighSpeedCamShake);
		Player.ClearSettingsByInstigator(Instigator = this);
		Player.ClearIdealDistanceByInstigator(Instigator = this);

		//Bird.UseVehicleChaseCam(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Bird.CameraOffset.RelativeRotation = FRotator(Bird.Mesh.RelativeRotation.Pitch - 15.f, 0.f, 0.f);

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		FOVAccel.AccelerateTo(GetMappedFlightSpeed(FVector2D(60.f, 90.f)), 2.f, DeltaTime);
		Player.ApplyFieldOfView(FOVAccel.Value, BlendSettings, this, Priority = EHazeCameraPriority::Low);

		Player.ApplyIdealDistance(
			GetMappedFlightSpeed(FVector2D(1200.f, 1500.f)),
			BlendSettings, Instigator = this, Priority = EHazeCameraPriority::Low);

		const bool bIsDiving = Bird.Mesh.RelativeRotation.Pitch < -25.f && !Bird.bIsLanding;
		const bool bIsBoosting = Bird.BoostDuration > 0.f;
		if (bIsDiving || bIsBoosting)
		{
			float HighSpeedCamShakeScale = FMath::GetMappedRangeValueClamped(
				FVector2D(Settings.FlyingSpeed, Settings.HighSpeedThreshold),
				FVector2D(0.f, 0.125f),
				Bird.FlightSpeed);

			if (bIsBoosting)
			{
				HighSpeedCamShakeScale = FMath::Lerp(0.125f, 0.f, (Bird.BoostTimer / Bird.BoostDuration));

				float ForceFeedback = FMath::Lerp(0.125f, 0.f, (Bird.BoostTimer / Bird.BoostDuration));
				Player.SetFrameForceFeedback(ForceFeedback, ForceFeedback);
			}

			SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(GetMappedFlightSpeed(FVector2D(0.1f, 1.f)), this));
			Player.PlayCameraShake(Bird.HighSpeedCamShake, HighSpeedCamShakeScale);
		}
		else
		{
			Player.PlayCameraShake(Bird.HighSpeedCamShake, 0.f);
		}
	}

	float GetMappedFlightSpeed(FVector2D WantedOutput)
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.f, Settings.FlyingSpeed), WantedOutput, Bird.FlightSpeed);
	}

	float GetMappedFlightCamPitch(FVector2D WantedOutput)
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(-25.f, -75.f), WantedOutput, Bird.FlightCamera.GetWorldRotation().Pitch);
	}
}