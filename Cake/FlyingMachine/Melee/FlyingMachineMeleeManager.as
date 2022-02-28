


struct FMeleeAiSettings
{
	/* How fast the 'LevelChangeSpeed' moves up or down when this setting becomes the active one
	 * Going up means that eventually the ai level will increase (Reacing over 1)
	 * Going down means that eventually the ai level will decrease (Reaching below 0)
	 * Every new level starts at 0.5
	*/
	UPROPERTY()
	float InitialSpeedAmount = 0;

	/* When the player hits the ai, the current 'LevelChangeSpeed'
	 * will be modified with this value.
	*/
	UPROPERTY()
	float ImpactToAiLevelSpeedChangeAmount = 0;

	/* When the ai hits the player, the current 'LevelChangeSpeed'
	 * will be modified with this value.
	*/
	UPROPERTY()
	float ImpactToPlayerLevelSpeedChangeAmount = 0;

	/* How long time with doing noting until we start changing the 'LevelChangeSpeed'
	*/
	UPROPERTY()
	float IdleTimeToIdleLevelChangeSpeedBonusAmount = 0;

	/* How fast we change the 'LevelChangeSpeed'
	 * Delta time is multiplied with this value
	*/
	UPROPERTY()
	float IdleLevelChangeSpeedBonusAmount = 0;

	/* How fast we as max and min can change the curent level change value
	*/
	UPROPERTY()
	FHazeMinMax LevelChangeSpeedClamps = FHazeMinMax(-1.f, 1.f);

	/* How long time until the ai will do something to the player */
	UPROPERTY()
	float DelayToFirstAttack = 0;

	/* How long time until the ai will attack again */
	UPROPERTY()
	float DelayBetweenAttacks = 0;

	/* How long until the ai starts moving towards the player 
	 * use -1 to never move
	*/
	UPROPERTY()
	float MaxStandingStillTime = 0;


	// /* How big is the chance that the ai will react
	//  * correctly to what the player is doing 
	// */
	// UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	// float ChanceToTriggerCorrectCounter = 0.f;

	// /* If the attack was not wath was needed to attack the player,
	//  * we can increase with this amount so eventually we will do a vaild move
	// */
	// UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	// float IncorrectAttackBonusAmount = 0.f;
}

// Settings for the fight
class UFlyingMachineMeleeSettings : UHazeMeleeSettingsAsset
{
	UPROPERTY(Category = "Ai")
	FMeleeAiSettings AiSettings;
}

// Meleemanager that stores the settings and is used by all the melee components
class AFlyingMachineMeleeManager : AHazeMelee2DManager
{
	// Display the players debug settings
	UFUNCTION(BlueprintOverride)
	bool ShowPlayerDebug()const
	{
		return false;
	}

	// Display the players debug settings
	UFUNCTION(BlueprintOverride)
	bool ShowAiDebug()const
	{
		return false;
	}

	// Display all the collision
	UFUNCTION(BlueprintOverride)
	bool AlwaysShowCollision()const
	{
		return false;
	}

	UFUNCTION()
	AActor SpawnDebugSquirrel(TSubclassOf<AHazeCharacter> SquirrelType, int& NetworkIndex)
	{
		auto SpawnedSuirrel = SpawnActor(SquirrelType, bDeferredSpawn = true, Level = GetLevel());
		SpawnedSuirrel.MakeNetworked(NetworkIndex);
		FinishSpawningActor(SpawnedSuirrel);
		NetworkIndex += 1;
		return SpawnedSuirrel;
	}
}