import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;
class UMassiveSpeakerVolumeControlInteractedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MassiveVolumeSpeaker");
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
		if (IsActioning(n"IsInteracting"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"IsInteracting"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"RectractCapability", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"RectractCapability", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveDir = GetAttributeVector(n"MoveVector");

		float Dot = MoveDir.GetSafeNormal().DotProduct(VolumeControl.ActorForwardVector);
		VolumeControl.Move(Dot, VolumeControl.ProgressAcceleration);
	}
}