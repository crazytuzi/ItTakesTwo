import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;
class UMassiveSpeakerVolumeControlMoveCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMassiveSpeakerVolumeControl VolumeControl;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		VolumeControl = Cast<AMassiveSpeakerVolumeControl>(Owner);
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
	void TickActive(float DeltaTime)
	{
		if (Game::GetCody().HasControl())
		{
			if(!VolumeControl.bMovedLastFrame)
			{
				VolumeControl.CurrentSpeed = FMath::Lerp(VolumeControl.CurrentSpeed, 0.f, DeltaTime * 15);
			}
			VolumeControl.Progress += VolumeControl.CurrentSpeed * DeltaTime * 60.f;
			VolumeControl.ProgressSync.Value = VolumeControl.Progress;
			VolumeControl.bMovedLastFrame = false;
		}
		else
		{
			VolumeControl.Progress = VolumeControl.ProgressSync.Value;
		}

		VolumeControl.Progress = FMath::Clamp(VolumeControl.Progress, 0, VolumeControl.Spline.SplineLength);
		VolumeControl.Mesh.SetWorldLocation(VolumeControl.Spline.GetLocationAtDistanceAlongSpline(VolumeControl.Progress, ESplineCoordinateSpace::World));
	}
}