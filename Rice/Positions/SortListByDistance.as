// This is a blublesort, dont use this with more than 10 actors in one array and NEVER ON TICK!
UFUNCTION(Category = "Utilities|Location", BlueprintPure)
TArray<AHazeActor> SortActorArrayByDistance(TArray<AHazeActor> ActorArray, FVector Location, bool ClosestAtLastIndex)
{
    bool CleanListIteration = false;
    TArray<AHazeActor> LocalActorArray = ActorArray;

    while(CleanListIteration == false)
    {
        CleanListIteration = true;

        for (int Index = 0, Count = ActorArray.Num(); Index < Count; ++Index)
        {
            if (!ClosestAtLastIndex)
            {
                if (Index < ActorArray.Num() -1 &&
                    LocalActorArray[Index].ActorLocation.Distance(Location) > LocalActorArray[Index+1].ActorLocation.Distance(Location))
                {
                    AHazeActor TempActor = LocalActorArray[Index];
                    LocalActorArray[Index] = LocalActorArray[Index+1];
                    LocalActorArray[Index+1] = TempActor;
                    CleanListIteration = false;
                }
            }

            else 
            {
                if (Index < ActorArray.Num() -1 &&
                    LocalActorArray[Index].ActorLocation.Distance(Location) < LocalActorArray[Index+1].ActorLocation.Distance(Location))
                {
                    AHazeActor TempActor = LocalActorArray[Index];
                    LocalActorArray[Index] = LocalActorArray[Index+1];
                    LocalActorArray[Index+1] = TempActor;
                    CleanListIteration = false;
                }
            }
        }
    }

    return LocalActorArray;
}