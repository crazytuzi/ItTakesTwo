import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionRuneDoor;
import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionWood;
import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionBuilding;
class ATimeDimensionStorageManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY()
	ATimeDimensionRuneDoor RuneDoor;

	TArray<ATimeDimensionWood> WoodArray;

	UPROPERTY()
	TArray<ATimeDimensionBuilding> BuildingArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> ActorArray;

		BoxCollision.GetOverlappingActors(ActorArray);

		for (AActor Actor : ActorArray)
		{
			ATimeDimensionWood Wood = Cast<ATimeDimensionWood>(Actor);
			if (Wood != nullptr)
			{
				WoodArray.Add(Wood);
			}
		}		
		RuneDoor.DoorOpenedEvent.AddUFunction(this, n"DoorOpened");
	}

	UFUNCTION()
	void DoorOpened()
	{
		for (ATimeDimensionWood Wood : WoodArray)
		{
			Wood.ScaleWood();
		}

		for (ATimeDimensionBuilding Building : BuildingArray)
		{
			Building.ScaleUpBuilding();
		}
	}
}