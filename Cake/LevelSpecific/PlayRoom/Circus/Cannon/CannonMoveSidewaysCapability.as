import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Peanuts.Audio.AudioStatics;

class UCannonMoveSidewaysCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CannonMovement");

	default CapabilityDebugCategory = n"CannonMovement";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	FHazeAcceleratedFloat AcceleratedYaw;
	ACannonToShootMarbleActor Cannon;

	float InitialYaw;
	float TargetYaw;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cannon = Cast<ACannonToShootMarbleActor>(Owner);
		InitialYaw = Cannon.ActorRotation.Yaw;
		TargetYaw = InitialYaw;
		AcceleratedYaw.SnapTo(InitialYaw);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Cannon.InteractingPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Cannon.InteractingPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateRotation(DeltaTime);

		float NormalizedYaw = HazeAudio::NormalizeRTPC01(FMath::Abs(AcceleratedYaw.Velocity), 0.f, 20.f);

		Cannon.HazeAkComp.SetRTPCValue("Rtpc_Goldberg_Circus_MarbleCannonn_Turn", NormalizedYaw);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cannon.YawSyncComp.OverrideControlSide(Cannon.InteractingPlayer);
	}

	void UpdateRotation (float DeltaTime)
	{
		if (Cannon.InteractingPlayer.HasControl())
		{
			float Axis = Cannon.XAxis;			
			TargetYaw += Axis * Cannon.YawRate * DeltaTime;
			if (Cannon.ClampLeft + Cannon.ClampRight < 360.f)
				TargetYaw = FMath::Clamp(TargetYaw, InitialYaw - Cannon.ClampLeft, InitialYaw + Cannon.ClampRight);
			AcceleratedYaw.AccelerateTo(TargetYaw, 0.4f, DeltaTime);

			float DeltaYaw = AcceleratedYaw.Value - Cannon.GetActorRotation().Yaw;
			RotateWheels(DeltaYaw);
			
			FRotator CannonRotation = Cannon.ActorRotation;
			CannonRotation.Yaw = AcceleratedYaw.Value;
			Cannon.SetActorRotation(CannonRotation);

			Cannon.YawSyncComp.Value = TargetYaw;
		}
		else
		{
			// [Tom] Sycned float alone looked trash, so I added the same acceleration on the remote as the control
			TargetYaw = Cannon.YawSyncComp.Value;
			AcceleratedYaw.AccelerateTo(TargetYaw, 0.4f, DeltaTime);

			float DeltaYaw = AcceleratedYaw.Value - Cannon.ActorRotation.Yaw;
			RotateWheels(DeltaYaw);

			FRotator CannonRotation = Cannon.ActorRotation;
			CannonRotation.Yaw = AcceleratedYaw.Value;
			Cannon.SetActorRotation(CannonRotation);
		}
	}

	void RotateWheels(float Yaw)
	{
		const float WheelRadius = 57.5f;
		const float WheelTrack = 80.f;
		const float DistanceTraveled = Yaw * WheelTrack * DEG_TO_RAD;

		float Rotation = 0.f;
		if (!FMath::IsNearlyZero(DistanceTraveled))
			Rotation = (DistanceTraveled / WheelRadius) * RAD_TO_DEG;

		Cannon.LeftWheelRot.Pitch -= Rotation;
		Cannon.RightWheelRot.Pitch += Rotation;
	}
}