
/* Use faster component overlap traces to get the players that are currently overlapping a specific component. */
UFUNCTION(BlueprintPure)
void TracePlayersOverlappingComponent(UPrimitiveComponent Component, TArray<AHazePlayerCharacter>&out OutOverlappingPlayers)
{
	OutOverlappingPlayers.Reset();
	for (auto Player : Game::Players)
	{
		if (Trace::ComponentOverlapComponent(
			Component,
			Player.CapsuleComponent,
			Player.ActorLocation, Player.ActorQuat
		))
		{
			OutOverlappingPlayers.Add(Player);
		}
	}
}