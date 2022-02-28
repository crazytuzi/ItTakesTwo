import Peanuts.Triggers.HazeTriggerBase;
import Cake.LevelSpecific.SnowGlobe.Boatsled.Boatsled;

enum EBoatsledWhaleDomeTriggerType
{
	Enter,
	Exit
}

class ABoatsledWhaleDomeTrigger : AHazeTriggerBase
{
	default bTriggerLocally = false;

	UPROPERTY()
	EBoatsledWhaleDomeTriggerType TriggerType;

	UPROPERTY()
	AHazeProp SnowglobeDome;

	TArray<AActor> BoatsledsGoneThroughTrigger;

	bool ShouldTrigger(AActor Actor) override
	{
		return Actor.IsA(ABoatsled::StaticClass());
	}

	void EnterTrigger(AActor Actor) override
	{
		BoatsledsGoneThroughTrigger.AddUnique(Actor);
		if(BoatsledsGoneThroughTrigger.Num() > 1)
		{
			if(TriggerType == EBoatsledWhaleDomeTriggerType::Enter)
				HideSnowglobeDome();
			else if(TriggerType == EBoatsledWhaleDomeTriggerType::Exit)
				RestoreSnowglobeDome();

			OnReset();
		}
	}

	void RestoreSnowglobeDome()
	{
		SnowglobeDome.SetActorHiddenInGame(false);
	}

	void HideSnowglobeDome()
	{
		SnowglobeDome.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnReset()
	{
		BoatsledsGoneThroughTrigger.Empty();
	}
}