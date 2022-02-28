import Cake.SteeringBehaviors.SteeringBehaviorComponent;

UFUNCTION()
void BlockAllSteeringBehaviorsForClass(TSubclassOf<AHazeActor> ActorClass, UObject Instigator)
{
	TArray<AActor> OutActors;
	Gameplay::GetAllActorsOfClass(ActorClass, OutActors);

	for(AActor Actor : OutActors)
	{
		AHazeActor HazeActor = Cast<AHazeActor>(Actor);
		HazeActor.BlockCapabilities(n"SteeringBehavior", Instigator);
	}
}

UFUNCTION()
void UnblockAllSteeringBehaviorsForClass(TSubclassOf<AHazeActor> ActorClass, UObject Instigator)
{
	TArray<AActor> OutActors;
	Gameplay::GetAllActorsOfClass(ActorClass, OutActors);

	for(AActor Actor : OutActors)
	{
		AHazeActor HazeActor = Cast<AHazeActor>(Actor);
		HazeActor.UnblockCapabilities(n"SteeringBehavior", Instigator);
	}
}

