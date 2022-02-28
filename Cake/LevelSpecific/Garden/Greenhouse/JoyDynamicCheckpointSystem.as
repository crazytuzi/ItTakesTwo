import Vino.Checkpoints.Checkpoint;

class AJoyDynamicCheckpointSystem : AHazeActor
{
	//Yes very generous name for what it actually does
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY()
	ACheckpoint Checkpoint;

	UPROPERTY()
	AActor CheckpointLocationOne;
	UPROPERTY()
	AActor CheckpointLocationTwo;
	UPROPERTY()
	AActor CheckpointLocationThree;
	UPROPERTY()
	AActor CheckpointLocationFour;
	UPROPERTY()
	AActor CheckpointLocationFive;
	UPROPERTY()
	AActor CheckpointLocationSix;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds){}

	UFUNCTION()
	void MoveCheckpoint(int LocationToActivate)
	{	
		if(LocationToActivate == 1)
		{
			Checkpoint.SetActorLocation(CheckpointLocationOne.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationOne.GetActorRotation());
		}
		if(LocationToActivate == 2)
		{
			Checkpoint.SetActorLocation(CheckpointLocationTwo.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationTwo.GetActorRotation());
		}
		if(LocationToActivate == 3)
		{
			Checkpoint.SetActorLocation(CheckpointLocationThree.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationThree.GetActorRotation());
		}
		if(LocationToActivate == 4)
		{
			Checkpoint.SetActorLocation(CheckpointLocationFour.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationFour.GetActorRotation());
		}
		if(LocationToActivate == 5)
		{
			Checkpoint.SetActorLocation(CheckpointLocationFive.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationFive.GetActorRotation());
		}
		if(LocationToActivate == 6)
		{
			Checkpoint.SetActorLocation(CheckpointLocationSix.GetActorLocation());
			Checkpoint.SetActorRotation(CheckpointLocationSix.GetActorRotation());
		}
	}
}

