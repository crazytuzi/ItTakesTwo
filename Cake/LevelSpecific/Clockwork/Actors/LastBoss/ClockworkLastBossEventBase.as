import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossStatics;

event void FClockworkEventFinishedSignature(int EventNumber);
event void FClockworkEventStartedSignature(int EventNumber);

class AClockworkLastBossEventBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	EClockworkEventNumber EventNumber;

	UPROPERTY()
	FClockworkEventFinishedSignature FinishedEvent;

	UPROPERTY()
	FClockworkEventStartedSignature StartedEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	// UFUNCTION()
	// void StartEvent()
	// {
		
	// }
}