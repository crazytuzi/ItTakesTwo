import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalPlayerLaunchPreviewCapability;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseAimCapability;
import Cake.LevelSpecific.Garden.Vine.VineAimCapability;


class USpiderWallWalkCameraCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		if (Player.IsAnyCapabilityActive(UWallWalkingAnimalPlayerLaunchPreviewCapability::StaticClass())
			 || Player.IsAnyCapabilityActive(UWaterHoseAimCapability::StaticClass())
			 || Player.IsAnyCapabilityActive(UVineAimCapability::StaticClass()))
		{
			return false;
		}
			
		else
		{
			return true;
		}
			
	}
}