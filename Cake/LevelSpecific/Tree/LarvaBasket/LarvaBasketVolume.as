import Peanuts.Triggers.PlayerTrigger;

class ALarvaBasketVolume : AHazeTriggerBase
{
	default BrushComponent.SetCollisionProfileName(n"TriggerPlayerOnly");

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	UHazeCapabilitySheet PlayerSheet;

    bool ShouldTrigger(AActor Actor) override
    {
        auto Player = Cast<AHazePlayerCharacter>(Actor);
        if (Player == nullptr)
            return false;

        return true;
    }

    void EnterTrigger(AActor Actor) override
    {
    	auto Player = Cast<AHazePlayerCharacter>(Actor);
    	Player.AddCapabilitySheet(PlayerSheet, EHazeCapabilitySheetPriority::Interaction, this);
    }

    void LeaveTrigger(AActor Actor) override
    {
    	auto Player = Cast<AHazePlayerCharacter>(Actor);
    	Player.RemoveCapabilitySheet(PlayerSheet, this);
    }
}