import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionTags;

class UDandelionComponent : UActorComponent
{
	AHazeActor HazeOwner;

	bool bDandelionActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}
}
