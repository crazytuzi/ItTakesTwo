UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AActor GetClosestActorOfClassToLocation(TSubclassOf<AHazeActor> ActorClass, FVector Position)
{
    AActor ClosestCandidate = nullptr;
    float ClosestcandidateDist = BIG_NUMBER;

    TArray<AActor> ActorsOfClass;

     Gameplay::GetAllActorsOfClass(ActorClass, ActorsOfClass);

    for (AActor Actor : ActorsOfClass)
	{
		if (Actor.ActorLocation.Distance(Position) < ClosestcandidateDist)
        {
            ClosestcandidateDist = Actor.ActorLocation.Distance(Position);
            ClosestCandidate = Actor;
        }
	}

    return ClosestCandidate;
}