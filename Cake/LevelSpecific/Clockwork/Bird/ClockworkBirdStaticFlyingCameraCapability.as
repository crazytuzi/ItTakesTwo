import Vino.Movement.Components.MovementComponent;

import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingSettings;
import Effects.PostProcess.PostProcessing;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UClockworkBirdStaticFlyingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdFlying");

	default CapabilityDebugCategory = n"ClockworkBirdFlying";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	// Movement Component
	AClockworkBird Bird;
	UClockworkBirdFlyingSettings Settings;
	AHazePlayerCharacter Player;
	UHazeCameraUserComponent CameraUser;

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
		Bird.StaticCamera.DetachFromParent(true);

		CameraUser = UHazeCameraUserComponent::Get(Player);

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		Player.ActivateCamera(Bird.StaticCamera, BlendSettings, this);

		FOVAccel.SnapTo(70.f);

		CurrentLocalOffset = GetTargetStaticCameraLocation() - Bird.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.StopAllInstancesOfCameraShake(Bird.HighSpeedCamShake);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector LocalStaticCameraLocation = GetTargetStaticCameraLocation() - Bird.ActorLocation;
		FVector InterpedLocationOffset = FMath::VInterpTo(CurrentLocalOffset, LocalStaticCameraLocation, DeltaTime, 2.f);

		Bird.StaticCamera.SetWorldLocation(Bird.ActorLocation + InterpedLocationOffset);
		CurrentLocalOffset = InterpedLocationOffset;

		FVector TargetLookAt = Bird.Mesh.WorldLocation;
		FVector LookAtOffset = TargetLookAt - Bird.StaticCamera.WorldLocation;

		// Apply a small amount of camera roll relative to the bird's roll
		FRotator BirdRotation = Bird.ActorRotation;
		BirdRotation.Pitch = Bird.Mesh.RelativeRotation.Pitch;
		BirdRotation.Roll = FMath::GetMappedRangeValueClamped(
			FVector2D(-60.f, 60.f),
			FVector2D(-25.f, 25.f),
			Bird.Mesh.RelativeRotation.Roll);

		FVector VerticalAxis = BirdRotation.UpVector;
		FRotator RotationOffset = FRotator::MakeFromXZ(LookAtOffset, VerticalAxis);

		Bird.StaticCamera.SetWorldRotation(RotationOffset);

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		FOVAccel.AccelerateTo(GetMappedFlightSpeed(FVector2D(70.f, 100.f)), 1.f, DeltaTime);
		Player.ApplyFieldOfView(FOVAccel.Value, BlendSettings, this);

		const bool bIsDiving = Bird.Mesh.RelativeRotation.Pitch < -25.f && !Bird.bIsLanding;
		if (bIsDiving)
		{
			float HighSpeedCamShakeScale = FMath::GetMappedRangeValueClamped(
				FVector2D(Settings.HighSpeedThreshold, Settings.FlyingSpeed),
				FVector2D(0.f, 0.125f),
				Bird.FlightSpeed);

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
		return FMath::GetMappedRangeValueClamped(FVector2D(-25.f, -75.f), WantedOutput, Bird.StaticCamera.GetWorldRotation().Pitch);
	}

	FVector GetTargetStaticCameraLocation()
	{
		float MappedFlightCamPitch = GetMappedFlightCamPitch(FVector2D(1.f, 0.f)) * 500.f;
		FVector ZLocationOffset = Bird.Mesh.GetUpVector() * 500.f;

		float MappedPitch = GetMappedFlightCamPitch(FVector2D(1.f, 0.f));
		float MappedPitchWithFlightSpeed = 500.f * MappedPitch * GetMappedFlightSpeed(FVector2D(1.f, 0.f));
		FVector YLocationOffset = Bird.Mesh.GetRightVector() * MappedPitchWithFlightSpeed;

		float ForwardFlightspeedMapped = GetMappedFlightSpeed(FVector2D(-1800.f, -1000.f));
		FVector XLocationOffset = Bird.Mesh.GetForwardVector() * ForwardFlightspeedMapped;

		FVector CombinedLocationOffsets = Bird.ActorLocation + ZLocationOffset + YLocationOffset + XLocationOffset;

		return CombinedLocationOffsets;
	}
}