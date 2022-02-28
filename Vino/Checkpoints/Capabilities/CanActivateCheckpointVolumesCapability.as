import Vino.PlayerHealth.PlayerRespawnComponent;

import void UpdateCheckpointVolumes(AHazePlayerCharacter Player) from "Vino.Checkpoints.Volumes.CheckpointVolume";

// Marker capability to indicate whether the player can currently activate any checkpoint volumes
class UCanActivateCheckpointVolumesCapability : UHazeCapability
{
	default RespondToEvent(n"NeverActivate");

    default CapabilityTags.Add(n"CanActivateCheckpointVolumes");
    default CapabilityTags.Add(n"MarkerCapability");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
        return EHazeNetworkActivation::DontActivate;
	}

	void Update()
    {
		bool bBlocked = IsBlocked();
		if (RespawnComp.bCheckpointVolumesBlocked != bBlocked)
		{
			RespawnComp.bCheckpointVolumesBlocked = bBlocked;
			if (!bBlocked)
				UpdateCheckpointVolumes(Cast<AHazePlayerCharacter>(Owner));
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		Update();
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		Update();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Update();
	}
};