UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AHazeActor GetFurthestActorFromPlayers(TArray<AHazeActor> ActorArray)
{
    float LongestDistance = -1;
    AHazeActor CurrentLongestDistanceCandidate;

    for(AHazeActor i : ActorArray)
    {
        float ActorTotalDistance = Game::GetCody().ActorLocation.Distance(i.ActorLocation) + 
        Game::GetMay().ActorLocation.Distance(i.ActorLocation);

        if (ActorTotalDistance > LongestDistance)
        {
            LongestDistance = ActorTotalDistance;
            CurrentLongestDistanceCandidate = i;
        }
    }
    
    return CurrentLongestDistanceCandidate;
}