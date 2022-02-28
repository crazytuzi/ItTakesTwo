import Peanuts.Triggers.PlayerTrigger;

class ACapabilityBlockingVolume : APlayerTrigger
{
	UPROPERTY()
	TArray<FName> CapabilityTags;

	void EnterTrigger(AActor Actor) override
    {
		Super::EnterTrigger(Actor);

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player == nullptr)
			return;

		for (int i = 0, Count = CapabilityTags.Num(); i < Count; ++i)
		{
			Player.BlockCapabilities(CapabilityTags[i], this);
		}
    }

	void LeaveTrigger(AActor Actor) override
	{
		Super::LeaveTrigger(Actor);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player == nullptr)
			return;

		for (int i = 0, Count = CapabilityTags.Num(); i < Count; ++i)
		{
			Player.UnblockCapabilities(CapabilityTags[i], this);
		}
	}

}