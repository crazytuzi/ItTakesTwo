UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AActor GetFurthestActorOfClassToLocation(TSubclassOf<AHazeActor> ActorClass, FVector Position)
{
    AActor ClosestCandidate = nullptr;
    float ClosestcandidateDist = -1;

    TArray<AActor> ActorsOfClass;

     Gameplay::GetAllActorsOfClass(ActorClass, ActorsOfClass);

    for (AActor Actor : ActorsOfClass)
	{
		if (Actor.ActorLocation.Distance(Position) > ClosestcandidateDist)
        {
            ClosestcandidateDist = Actor.ActorLocation.Distance(Position);
            ClosestCandidate = Actor;
        }
	}

    return ClosestCandidate;
}