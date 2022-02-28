import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossOverlapActor;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossEventBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossStatics;
class AClockworkLastBossEventManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	TArray<AClockworkLastBossOverlapActor> OverlapActorArray;
	TArray<AClockworkLastBossEventBase> EventArray;

	UPROPERTY()
	AHazeLevelSequenceActor LaunchPlatformSequence;

	UPROPERTY()
	EClockworkEventNumber EventNumber;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(OverlapActorArray);
		GetAllActorsOfClass(EventArray);
		
		for (AClockworkLastBossOverlapActor OverlapActor : OverlapActorArray)
		{
			OverlapActor.EventOverlapWasTriggered.AddUFunction(this, n"EventOverlapWasTriggered");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}
	
	UFUNCTION()
	void EventOverlapWasTriggered(EClockworkEventNumber NewEventNumber)
	{
		for(AClockworkLastBossEventBase Event : EventArray)
		{
			if (Event.EventNumber == NewEventNumber)
			{
				//Event.StartEvent();
			}
		}
	}
}