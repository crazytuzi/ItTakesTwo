import Peanuts.Triggers.ActorTrigger;

class ABurningPillarTrigger : AActorTrigger
{
	UPROPERTY()
	TArray<AHazeActor> Pillars;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"ActivatePillars");
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivatePillars(AHazeActor Actor)
	{

	}
}