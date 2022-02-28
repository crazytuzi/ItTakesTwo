import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagFloor;
class ATagFloorManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<ATagFloor> FloorPieces;

	UPROPERTY(Category = "Setup")
	TArray<int> FloorsIndexesUsedUp;

	int MaxNum = 6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(FloorPieces);
	}

	UFUNCTION(NetFunction)
	void SetFloorsGameActiveState(bool IsActive)
	{
		if (FloorPieces.Num() < 0)
			return;
		
		for (ATagFloor Floor : FloorPieces)
		{
			Floor.bGameIsActive = IsActive;
		}
	}

	UFUNCTION()
	void ResetFloors()
	{
		if (FloorPieces.Num() < 0)
			return;
		
		for (ATagFloor Floor : FloorPieces)
		{
			if (!Floor.bIsActive)
				Floor.FloorReappear();

			Floor.ResetFloorLife();
		}

		FloorsIndexesUsedUp.Empty();
	}

}