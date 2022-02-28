import Cake.LevelSpecific.Basement.ShadowActors.ShadowTrain;
import Peanuts.Triggers.HazeTriggerBase;
import Vino.Checkpoints.Checkpoint;

class AShadowTrainCheckpointTrigger : AHazeTriggerBase
{
	UPROPERTY()
	ACheckpoint TargetCheckpoint;

    bool ShouldTrigger(AActor Actor) override
    {
		AShadowTrain ShadowTrain = Cast<AShadowTrain>(Actor);
		if (ShadowTrain != nullptr)
			return true;
		
		return false;
    }

    void EnterTrigger(AActor Actor) override
    {
		AShadowTrain ShadowTrain = Cast<AShadowTrain>(Actor);
		if (ShadowTrain == nullptr)
			return;

		if (!ShadowTrain.bPlayersCaught)
			return;

		ShadowTrain.ReleasePlayers(TargetCheckpoint);
    }

    void LeaveTrigger(AActor Actor) override
    {
		AShadowTrain ShadowTrain = Cast<AShadowTrain>(Actor);
		if (ShadowTrain == nullptr)
			return;
    }
}