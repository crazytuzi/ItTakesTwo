import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class UMagnetHarpoonRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonRotationCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor Harpoon;

	FHazeAcceleratedRotator AccelFinalRotPlatform;
	FHazeAcceleratedRotator AccelFinalRotHolder;

	float YawRange = 38.f;
	float YawMin;
	float YawMax;
	
	float PitchMin = -45.f;
	float PitchMax = 5.f;

	float PitchSpeed = 30.f;
	float YawSpeed = 45.f;

	FVector StartingForward;

	FHazeAcceleratedFloat AccelInput;	

	bool bRTCPOn;

	float TargetPitchAmount;
	float TargetYawAmount;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Harpoon = Cast<AMagnetHarpoonActor>(Owner);
		YawMin = -YawRange;
		YawMax = YawRange;
		Harpoon.CameraEndPoint = Harpoon.AimPoint.WorldLocation + (Harpoon.HarpoonBaseSkel.ForwardVector * 2000.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelInput.SnapTo(0.f);
		TargetPitchAmount = Harpoon.AccelPitch.Value;
		TargetYawAmount = Harpoon.AccelYaw.Value;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Harpoon.SpearTargetLocation = Harpoon.AimPoint.WorldLocation;

		if (HasControl())
		{
			float BeforeAccel = 0.f;

			if (Harpoon.CameraUserComp != nullptr)
			{
				if (!Harpoon.CameraUserComp.HasPointOfInterest(EHazePointOfInterestType::Forced))
					RotationBehaviour(DeltaTime, BeforeAccel);
			}
			else
			{
				RotationBehaviour(DeltaTime, BeforeAccel);
			}	

			float AfterAccel = Harpoon.AccelPitch.Value + Harpoon.AccelYaw.Value;

			float Diff = FMath::Abs(BeforeAccel - AfterAccel);

			float InputValue = (Harpoon.YawInput + Harpoon.PitchInput);
			InputValue = FMath::Abs(InputValue);
			InputValue = FMath::Clamp(InputValue, 0.f, 1.f);

			AccelInput.AccelerateTo(InputValue, 0.8f, DeltaTime);

			if (Diff > 0.05f && !bRTCPOn)
			{
				bRTCPOn = true;
				Harpoon.AudioStartGunMovement();
			}
			else if (Diff < 0.05f && bRTCPOn)
			{
				bRTCPOn = false;
				Harpoon.AudioStopGunMovement();
			}

			Harpoon.AudioRTCPGunMovement(Diff);
			Harpoon.RotationSyncComp.SetValue(Harpoon.HarpoonRotation.Value);
		}
		else
		{
			Harpoon.HarpoonRotation.AccelerateTo(Harpoon.RotationSyncComp.Value, 0.25f, DeltaTime);
		}
	}

	void RotationBehaviour(float DeltaTime, float& BeforeAccel)
	{
		TargetPitchAmount += Harpoon.PitchInput * PitchSpeed * DeltaTime; 
		TargetYawAmount += Harpoon.YawInput * YawSpeed * DeltaTime; 
		TargetPitchAmount = FMath::Clamp(TargetPitchAmount, PitchMin, PitchMax);
		TargetYawAmount = FMath::Clamp(TargetYawAmount, YawMin, YawMax);

		BeforeAccel = Harpoon.AccelPitch.Value + Harpoon.AccelYaw.Value;

		Harpoon.AccelPitch.AccelerateTo(TargetPitchAmount, 1.f, DeltaTime);
		Harpoon.AccelYaw.AccelerateTo(TargetYawAmount, 1.f, DeltaTime);

		FVector Direction = Harpoon.CameraEndPoint - Harpoon.AimPoint.WorldLocation;
		Direction.Normalize();
		
		FRotator ForwardRot = FRotator::MakeFromXZ(Direction, Harpoon.ActorUpVector);
		Harpoon.HarpoonRotation.AccelerateTo(ForwardRot, 0.5f, DeltaTime);
	}
}