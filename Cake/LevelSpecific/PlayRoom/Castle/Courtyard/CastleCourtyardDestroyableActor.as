import Cake.Environment.BreakableComponent;

class ACastleCourtyardDestroyableActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBreakableComponent BreakComp;

	UPROPERTY()
	TArray<ACastleCourtyardDestroyableActor> MutuallyDestroyed;

	UPROPERTY()
	bool bShouldTriggerCutscene;
}