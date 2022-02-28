import Cake.LevelSpecific.Garden.WaterHose.WaterHoseAimCapability;

class UCameraVolumeSprinklerCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		if (Player.IsAnyCapabilityActive(UWaterHoseAimCapability::StaticClass()))
		{
			return false;
		}
			
		else
		{
			return true;
		}
			
	}
}