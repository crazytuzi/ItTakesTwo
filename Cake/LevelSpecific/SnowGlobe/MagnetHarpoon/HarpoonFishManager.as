import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class AHarpoonFishManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<AMagnetFishActor> MagnetFishArray;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(MagnetFishArray);
	}
}