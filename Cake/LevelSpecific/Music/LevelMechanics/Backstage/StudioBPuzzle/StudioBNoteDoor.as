import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioBPuzzle.StudioBStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalReceptacle;

event void FStudioBNoteDoorSignature(ETypeOfNote TypeOfNote);

class AStudioBNoteDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent NoteMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NoteSpawnLocation;

	UPROPERTY()
	ACymbalReceptacle ConnectedReceptable;

	UPROPERTY()
	ETypeOfNote TypeOfNoteToSpawn;

	UPROPERTY()
	FHazeTimeLike OpenDoorTimeline;
	default OpenDoorTimeline.Duration = 0.3f;

	UPROPERTY()
	TArray<UStaticMesh> NoteMeshArray;

	UPROPERTY()
	FStudioBNoteDoorSignature DoorWasOpened;

	float DoorOpenedHeight = 250.f;

	FVector StartLoc;
	FVector TargetLoc;

	FVector NoteLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorTimeline.BindUpdate(this, n"OpenDoorTimelineUpdate");

		StartLoc = MeshRoot.RelativeLocation;
		TargetLoc = StartLoc + FVector(0.f, 0.f, DoorOpenedHeight);
		
		if (ConnectedReceptable == nullptr)
			return;

		ConnectedReceptable.OnCymbalAttached.AddUFunction(this, n"CymbalAttached");
		ConnectedReceptable.OnCymbalDetached.AddUFunction(this, n"CymbalDetached");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		NoteMesh.SetStaticMesh(NoteMeshArray[TypeOfNoteToSpawn]);

		switch (TypeOfNoteToSpawn)
		{
			case ETypeOfNote::Fourth:
				NoteLocation = FVector(0.f, 0.f, 50.f);
				break;

			case ETypeOfNote::Eighth:
				NoteLocation = FVector(-25.f, 0.f, 50.f);
				break;

			case ETypeOfNote::Sixteenth:
				NoteLocation = FVector(-50.f, 0.f, 50.f);
				break;
		}

		NoteMesh.SetRelativeLocation(NoteLocation);
		
	}

	UFUNCTION()
	void OpenDoorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void CymbalAttached()
	{
		OpenDoorTimeline.Play();
		DoorWasOpened.Broadcast(TypeOfNoteToSpawn);
	}

	UFUNCTION()
	void CymbalDetached()
	{
		OpenDoorTimeline.Reverse();
	}
}