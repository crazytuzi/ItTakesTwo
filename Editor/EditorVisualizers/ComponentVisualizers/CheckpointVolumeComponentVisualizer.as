import Vino.Checkpoints.Volumes.CheckpointVolume;

class UCheckpointVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCheckpointVolumeVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UCheckpointVolumeVisualizerComponent Comp = Cast<UCheckpointVolumeVisualizerComponent>(Component);
        if (Comp == nullptr)
            return;

		ACheckpointVolume CheckpointVolume = Cast<ACheckpointVolume>(Component.Owner);
		if (CheckpointVolume == nullptr)
			return ;

		FVector Offset = FVector(0.f, 0.f, 90.f);
		FVector StartLocation = CheckpointVolume.ActorLocation + Offset;
		for (ACheckpoint Checkpoint : CheckpointVolume.EnabledCheckpoints)
		{
			if (Checkpoint == nullptr)
				continue;

			// Colour depending on who can use it
			FLinearColor Colour = FLinearColor(1.f, 0.4f, 0.f);
			if (!Checkpoint.bCanMayUse && !Checkpoint.bCanCodyUse)
				continue;
			else if (Checkpoint.bCanMayUse && !Checkpoint.bCanCodyUse)
				Colour = FLinearColor::Blue;
			else if (!Checkpoint.bCanMayUse && Checkpoint.bCanCodyUse)
				Colour = FLinearColor::Green;

			FVector EndLocation = Checkpoint.ActorLocation + Offset;
			DrawLine(StartLocation, EndLocation, Colour, 5.f);
		}
    }
}