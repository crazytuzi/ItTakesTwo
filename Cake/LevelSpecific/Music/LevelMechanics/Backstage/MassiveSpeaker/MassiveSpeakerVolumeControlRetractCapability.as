import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;
class UMassiveSpeakerVolumeControlRetractCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MassiveVolumeSpeaker");
	default CapabilityTags.Add(n"RectractCapability");
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
		if (IsActioning(n"StopMoving"))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.HasControl())
		{
			VolumeControl.Move(-1, VolumeControl.ProgressAcceleration, 15.f);
		}
	}
}