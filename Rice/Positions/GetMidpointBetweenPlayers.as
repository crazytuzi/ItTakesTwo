UFUNCTION(Category = "Utilities|Location", Meta = (CompactNodeTitle = "Player Midpoint"), BlueprintPure)
FVector GetMidPointBetweenPlayers()
{
    return (Game::GetMay().ActorLocation + Game::GetCody().ActorLocation) * 0.5f;
}