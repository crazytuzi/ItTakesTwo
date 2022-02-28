import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

// This capability will link the boats blocks with the boatparts blocks
class UWheelBoatHandleBlocksCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WheelBoat");

	AWheelBoatActor WheelBoat;
	int BlockCounter = 0;

	int WheelBoatBlocksCount = 0;

	UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
    }
	
	UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if(Tag == n"WheelBoat")
		{
			WheelBoatBlocksCount++;
			if(WheelBoatBlocksCount == 1)
			{
				WheelBoat.SetWheelBoatBlocked(true);
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		if(Tag == n"WheelBoat")
		{
			WheelBoatBlocksCount--;
			if(WheelBoatBlocksCount == 0)
			{
				WheelBoat.SetWheelBoatBlocked(false);
			}
		}
	}
}