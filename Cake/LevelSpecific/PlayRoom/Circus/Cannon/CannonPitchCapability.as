import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Peanuts.Audio.AudioStatics;

class UCannonPitchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CannonMovement");

	default CapabilityDebugCategory = n"CannonMovement";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	FHazeAcceleratedFloat AcceleratedPitch;
	ACannonToShootMarbleActor Cannon;

	float TargetPitch;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cannon = Cast<ACannonToShootMarbleActor>(Owner);
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

		float NormalizedPitch = HazeAudio::NormalizeRTPC01(FMath::Abs(AcceleratedPitch.Velocity), 0.f, 15.f);

		Cannon.HazeAkComp.SetRTPCValue("Rtpc_Goldberg_Circus_MarbleCannonn_Tilt", NormalizedPitch);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cannon.PitchSyncComp.OverrideControlSide(Cannon.InteractingPlayer);
	}

	void UpdateRotation (float DeltaTime)
	{
		if (Cannon.InteractingPlayer.HasControl())
		{
			float Axis = Cannon.YAxis;			
			TargetPitch += Axis * Cannon.PitchRate * DeltaTime;
			if (Cannon.ClampDown + Cannon.ClampUp < 360.f)
				TargetPitch = FMath::Clamp(TargetPitch, -Cannon.ClampDown, Cannon.ClampUp);
			AcceleratedPitch.AccelerateTo(TargetPitch, 0.4f, DeltaTime);

			Cannon.BarrelPitch = AcceleratedPitch.Value;
			Cannon.PitchSyncComp.Value = AcceleratedPitch.Value;
		}
		else
		{
			TargetPitch = Cannon.PitchSyncComp.Value;
			AcceleratedPitch.AccelerateTo(TargetPitch, 0.4f, DeltaTime);

			Cannon.BarrelPitch = AcceleratedPitch.Value;
		}
	}
}