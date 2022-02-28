import Cake.LevelSpecific.Tree.Boat.TreeWaterLarva;

class ATreeWaterLarvaManager : AHazeActor
{
	UPROPERTY(DefaultComponent, NotEditable)
	UBillboardComponent BillboardComponent;
	default BillboardComponent.SetRelativeScale3D(4.f);

	TArray<ATreeWaterLarva> WaterLarvas;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(WaterLarvas);
	}

	UFUNCTION()
	void DisableGroup(int GroupIndex)
	{
		for (auto WaterLarva : WaterLarvas)
		{
			if (WaterLarva.GroupIndex == GroupIndex)
				WaterLarva.DeactivateLarva();
		}
	}

}