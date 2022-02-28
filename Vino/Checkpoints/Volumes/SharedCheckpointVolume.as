import Vino.Checkpoints.Volumes.CheckpointVolume;

class ASharedCheckpointVolume : ACheckpointVolume
{
	default bSharedByBothPlayers = true;
};