import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class AHarpoonFishAchievement : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<AMagnetFishActor> MagnetFishArray;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;
}