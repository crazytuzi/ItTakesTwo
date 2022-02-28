/*
class AMusicalFollowerKeyManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(Category = Settings)
	bool bActivateManager = true;

	// Smallest delay between attempting to locate a key to seek towards. Final value is randomized.
	UPROPERTY(Category = "Settings|SeekKey")
	float SeekKeyFrequencyMin = 2.0f;

	// Largest delay between attempting to locate a key to seek towards. Final value is randomized.
	UPROPERTY(Category = "Settings|SeekKey")
	float SeekKeyFrequencyMax = 4.0f;

	UPROPERTY(Category = "Settings|SeekKey")
	int MaxNumKeySeekers = 1;

	// The bird that is closest to this distance is the one we prefer to pick as seeker.
	UPROPERTY(Category = "Settings|SeekKey")
	float AverageDistance = 6000.0f;

	// Smallest delay between attempting to locate a key to steal. Final value is randomized.
	UPROPERTY(Category = "Settings|StealKey")
	float StealKeyFrequencyMin = 2.5f;

	// Largest delay between attempting to locate a key to steal. Final value is randomized.
	UPROPERTY(Category = "Settings|StealKey")
	float StealKeyFrequencyMax = 5.0f;

	UPROPERTY(Category = "Settings|StealKey")
	int MaxNumKeyStealers = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"MusicalKeyTriggerHostileKeyBirdCapability");
		AddCapability(n"MusicEvaluateKeyBirdSeekKeyCapability");
		AddCapability(n"KeyBirdControlSideSwitcherCapability");
	}
}
*/