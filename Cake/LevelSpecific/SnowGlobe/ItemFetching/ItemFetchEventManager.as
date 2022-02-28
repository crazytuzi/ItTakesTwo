import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchDropOffPoint;

class AItemFetchEventManager : AHazeActor
{
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet FetchCapabilitySheet;

	UPROPERTY(Category = "Setup")
	TArray<AItemFetchDropOffPoint> DropOffPointsArrays;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Game::GetMay().AddCapabilitySheet(FetchCapabilitySheet);
		Game::GetCody().AddCapabilitySheet(FetchCapabilitySheet);

		// if (DropOffPointsArrays.Num() > 0)
		// {
		// 	for (AItemFetchDropOffPoint DropOff : DropOffPointsArrays)
		// 	{
		// 		DropOff.SetCompReferences();
		// 	}
		// }
	} 
}