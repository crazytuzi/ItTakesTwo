UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AHazePlayerCharacter GetFurthestPlayer(FVector Location)
{
    if (Game::GetCody().ActorLocation.Distance(Location) > Game::GetMay().ActorLocation.Distance(Location))
    {
        return Game::GetCody();
    }

    else
    {
        return Game::GetMay();
    }
}