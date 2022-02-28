class ACourtyardBallista : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TurretRoot;

	// UPROPERTY()
	// TSubclassOf
	
	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerSheet == nullptr)
			return;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.AddCapabilitySheet(PlayerSheet, Instigator = this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (PlayerSheet == nullptr)
			return;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.RemoveCapabilitySheet(PlayerSheet, Instigator = this);
		}
	}
}