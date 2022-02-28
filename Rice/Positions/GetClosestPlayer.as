UFUNCTION(Category = "Utilities|Location", BlueprintPure)
AHazePlayerCharacter GetClosestPlayer(FVector Location)
{
    if (Game::GetCody().ActorLocation.DistSquared(Location) < Game::GetMay().ActorLocation.DistSquared(Location))
    {
        return Game::GetCody();
    }

    else
    {
        return Game::GetMay();
    }
}