UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AHazeActor GetClosestActorToLocation(TArray<AHazeActor> ActorArray, FVector Position)
{
    AHazeActor ClosestCandidate = nullptr;
    float ClosestcandidateDist = BIG_NUMBER;

    for (AHazeActor Actor : ActorArray)
	{
		if (Actor.ActorLocation.Distance(Position) < ClosestcandidateDist)
        {
            ClosestcandidateDist = Actor.ActorLocation.Distance(Position);
            ClosestCandidate = Actor;
        }
	}

    return ClosestCandidate;
}