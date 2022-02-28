import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.Health.ParentBlobHealthComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobTrigger;

class AParentBlobCheckpointVolume : AParentBlobTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.f, 1.f, 0.8f, 1.f));

	UPROPERTY()
	ACheckpoint Checkpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"ParentBlobEnterTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void ParentBlobEnterTrigger(AHazeActor Actor)
	{
		UParentBlobHealthComponent HealthComp = UParentBlobHealthComponent::Get(GetActiveParentBlobActor());
		HealthComp.CurrentCheckpoint = Checkpoint;
	}
}