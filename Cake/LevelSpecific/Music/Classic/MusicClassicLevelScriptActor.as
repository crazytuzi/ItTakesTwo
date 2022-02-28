class AMusicClassicLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	UHazeCapabilitySheet CodySheet = Asset("/Game/Blueprints/LevelSpecific/Music/MusicCodySheet_Classic.MusicCodySheet_Classic");

	UPROPERTY()
	UHazeCapabilitySheet MaySheet = Asset("/Game/Blueprints/LevelSpecific/Music/MusicMaySheet_Classic.MusicMaySheet_Classic");

	UFUNCTION()
	void InitializeMusicLevel(bool bAddSheets)
	{
		if (bAddSheets)
		{
			if (MaySheet != nullptr)
			{
				Game::GetMay().AddCapabilitySheet(MaySheet, EHazeCapabilitySheetPriority::Normal, this);
			}

			if (CodySheet != nullptr)
			{
				Game::GetCody().AddCapabilitySheet(CodySheet, EHazeCapabilitySheetPriority::Normal, this);
			}
		}
	}
}