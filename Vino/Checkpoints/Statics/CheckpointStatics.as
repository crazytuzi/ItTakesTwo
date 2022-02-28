import Vino.Checkpoints.Checkpoint;
import Vino.PlayerHealth.PlayerRespawnComponent;

import void OnCheckpointVolumeRemovedFromSticky(AHazePlayerCharacter Player, UObject CheckpointVolume) from "Vino.Checkpoints.Volumes.CheckpointVolume";
import bool IsPlayerInsideCheckpointVolume(AHazePlayerCharacter Player) from "Vino.Checkpoints.Volumes.CheckpointVolume";
import bool IsPlayerDead(AHazePlayerCharacter Player) from "Vino.PlayerHealth.PlayerHealthStatics";

// Remove any checkpoint volume we've previously entered and recorded as sticky
UFUNCTION(Category = "Checkpoints")
void ResetStickyCheckpointVolume(AHazePlayerCharacter Player)
{
    UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
    if (RespawnComp.StickyCheckpointVolume != nullptr)
    {
        OnCheckpointVolumeRemovedFromSticky(Player, RespawnComp.StickyCheckpointVolume);
        RespawnComp.StickyCheckpointVolume = nullptr;
    }

	if (RespawnComp.StickyCheckpoint != nullptr)
	{
		Cast<ACheckpoint>(RespawnComp.StickyCheckpoint).DisableForPlayer(Player);
		RespawnComp.StickyCheckpoint = nullptr;
	}
}

// Manually add a sticky checkpoint as if it was added by a volume
UFUNCTION(Category = "Checkpoints")
void SetStickyCheckpoint(AHazePlayerCharacter Player, ACheckpoint Checkpoint)
{
	ResetStickyCheckpointVolume(Player);

	if (Checkpoint != nullptr)
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
		RespawnComp.StickyCheckpoint = Checkpoint;
		Checkpoint.EnableForPlayer(Player);
	}
}

// Check whether the player is allowed to activate any checkpoint volumes
UFUNCTION(Category = "Checkpoints")
bool CanPlayerActivateCheckpointVolumes(AHazePlayerCharacter Player)
{
    if (IsPlayerDead(Player))
        return false;

    UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
	if (RespawnComp.bCheckpointVolumesBlocked)
		return false;
    return true;
}

// Respawn player with camera snapped behind
UFUNCTION(Category = "Checkpoints")
void TeleportPlayerToCheckpointWithCameraSnap(ACheckpoint Checkpoint, AHazePlayerCharacter Player)
{
	Checkpoint.TeleportPlayerToCheckpoint(Player);
	Player.SnapCameraAtEndOfFrame();
}

// Disable all checkpoints that are enabled for the specified player
UFUNCTION(Category = "Checkpoints")
void DisableAllCheckpointsForPlayer(AHazePlayerCharacter Player)
{
	if (IsPlayerInsideCheckpointVolume(Player))
	{
		devEnsure(false, "Cannot DisableAllCheckpointsForPlayer while the player is still inside an active checkpoint volume.");
		return;
	}

	// Remove any sticky volume we had before
	ResetStickyCheckpointVolume(Player);

	// TODO: Optimize this instead of looping through all checkpoints?
	//  Probably not a problem.

	// Disable any checkpoints that are enabled
	TArray<ACheckpoint> AllCheckpoints;
	GetAllActorsOfClass(AllCheckpoints);

	for (ACheckpoint Checkpoint : AllCheckpoints)
		Checkpoint.DisableForPlayer(Player);
}