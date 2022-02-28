UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AHazeActor GetFurthestActorToLocation(TArray<AHazeActor> ActorArray, FVector Position)
{
    AHazeActor ClosestCandidate = nullptr;
    float ClosestcandidateDist = -1;

    for (AHazeActor Actor : ActorArray)
	{
		if (Actor.ActorLocation.Distance(Position) > ClosestcandidateDist)
        {
            ClosestcandidateDist = Actor.ActorLocation.Distance(Position);
            ClosestCandidate = Actor;
        }
	}

    return ClosestCandidate;
}