
class AGardenLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	UHazeCapabilitySheet CodySheet = Asset("/Game/Blueprints/LevelSpecific/Garden/GardenCodySheet.GardenCodySheet");

	UPROPERTY()
	UHazeCapabilitySheet MaySheet = Asset("/Game/Blueprints/LevelSpecific/Garden/GardenMaySheet.GardenMaySheet");

	UPROPERTY()
	TSubclassOf<UHazeCapability> SickleEnemyAreaCapability;

	UFUNCTION()
	void InitializeGardenLevel()
	{
		if (MaySheet != nullptr)
		{
			Game::May.AddCapabilitySheet(MaySheet, EHazeCapabilitySheetPriority::Level, this);
		}

		if (CodySheet != nullptr)
		{
			Game::Cody.AddCapabilitySheet(CodySheet, EHazeCapabilitySheetPriority::Level, this);
		}

		if (SickleEnemyAreaCapability.IsValid())
		{
			Game::May.AddCapability(SickleEnemyAreaCapability);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(MaySheet != nullptr)
			Game::May.RemoveCapabilitySheet(MaySheet, this);
		
		if(CodySheet != nullptr)
			Game::Cody.RemoveCapabilitySheet(CodySheet, this);

		if (SickleEnemyAreaCapability.IsValid())
		{
			Game::May.RemoveCapability(SickleEnemyAreaCapability);
		}

		OnPlayEndedGarden();
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayEndedGarden()
	{

	}
}

