import Peanuts.Triggers.HazeTriggerBase;
import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;

event void FTriggerHeadButtingDinoEvent(AHeadButtingDino Actor);

class AHeadButtingDinoKillTrigger : AHazeTriggerBase
{
    UPROPERTY(Category = "Actor Trigger")
    TArray<TSubclassOf<AHazeActor>> TriggerOnActorClasses;

    UPROPERTY(Category = "Actor Trigger")
    TArray<AHazeActor> TriggerOnSpecificActors;

	UPROPERTY(Category = "Actor Trigger")
	AHazeActor RespawnPosition;

    UPROPERTY(Category = "Actor Trigger")
    FTriggerHeadButtingDinoEvent OnActorEnter;

    bool ShouldTrigger(AActor Actor) override
    {
        if (TriggerOnSpecificActors.Contains(Cast<AHeadButtingDino>(Actor)))
            return true;

        for (auto SubClass : TriggerOnActorClasses)
        {
            if (!SubClass.IsValid())
                continue;
            if (Actor.IsA(SubClass))
                return true;
        }

        return false;
    }

    void EnterTrigger(AActor Dino) override
    {
        OnActorEnter.Broadcast(Cast<AHeadButtingDino>(Dino));
		TriggerDeathEffects(Cast<AHeadButtingDino>(Dino));
    }

	void TriggerDeathEffects(AHeadButtingDino Dino)
	{
		Dino.TriggerDeathEffets(RespawnPosition.ActorTransform);
	}
}	