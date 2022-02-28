import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioBPuzzle.StudioBNote;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioBPuzzle.StudioBNoteDoor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioBPuzzle.StudioBStatics;

class AStudioBManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	TArray<AStudioBNote> NoteArray;
	TArray<AStudioBNoteDoor> DoorArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(NoteArray);
		GetAllActorsOfClass(DoorArray);

		for (AStudioBNoteDoor Door : DoorArray)
		{
			Door.DoorWasOpened.AddUFunction(this, n"DoorWasOpened");
		}
	}

	UFUNCTION()
	void DoorWasOpened(ETypeOfNote TypeOfNote)
	{
	
	}
}