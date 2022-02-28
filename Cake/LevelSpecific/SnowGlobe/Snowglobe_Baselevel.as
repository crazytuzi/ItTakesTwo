class ASnowglobe_Baselevel : AHazeLevelScriptActor
{
	UPROPERTY()
	UHazeCapabilitySheet MayMagnetSheet;

	UPROPERTY()
	UHazeCapabilitySheet CodyMagnetSheet;

	UPROPERTY()
	UHazeCapabilitySheet IceSkatingSheet;

	UPROPERTY()
	TArray<UHazeCapabilitySheet> MayCapabilitySheets;

	UPROPERTY()
	TArray<UHazeCapabilitySheet> CodyCapabilitySheets;

	UPROPERTY()
	TArray<UHazeCapabilitySheet> CommonCapabilitySheets;

	UFUNCTION()
	void SetupPlayersForSnowGlobe()
	{
		/*
		Game::GetCody().AddCapabilitySheet(CodyMagnetSheet);
		Game::GetMay().AddCapabilitySheet(MayMagnetSheet);

		Game::GetCody().AddCapabilitySheet(IceSkatingSheet);
		Game::GetMay().AddCapabilitySheet(IceSkatingSheet);
		*/

		// Add Sheets for May
		for (UHazeCapabilitySheet MayCapabilitySheet : MayCapabilitySheets)
		{
			Game::GetMay().AddCapabilitySheet(MayCapabilitySheet, Instigator = this);
		}

		// Add Sheets for Cody
		for (UHazeCapabilitySheet CodyCapabilitySheet : CodyCapabilitySheets)
		{
			Game::GetCody().AddCapabilitySheet(CodyCapabilitySheet, Instigator = this);
		}

		// Add Common Sheets
		for (UHazeCapabilitySheet CommonCapabilitySheet : CommonCapabilitySheets)
		{
			Game::GetCody().AddCapabilitySheet(CommonCapabilitySheet, Instigator = this);
			Game::GetMay().AddCapabilitySheet(CommonCapabilitySheet, Instigator = this);
		}
	}
}