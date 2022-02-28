class AHopscotchAudioEventsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	float CurrentSpawningTileIntensity;

	UPROPERTY()
	float SpawningFloorInterpSpeed = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentSpawningTileIntensity = FMath::FInterpTo(CurrentSpawningTileIntensity, 0.f, DeltaTime, SpawningFloorInterpSpeed);
		AudioSpawningFloorIntensity(CurrentSpawningTileIntensity);
	}

	// First drop in psycadelic tunnel right after the elevator cutscene 
	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioFirstDropStart()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioLandAfterFirstDrop()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRotatingCubesSpawnStart()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioRotatingCubesSpawnFinished()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioPlayerEnteredRotatingCubes(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioPlayerExitedRotatingCubes(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioSpawningFloorStart()
	{

	}
	
	UFUNCTION()
	void CalculateSpawningFloorIntensity()
	{
		CurrentSpawningTileIntensity += 1;
	}
	
	// The amount of floor tiles that has spawned on the weird kaleidoscope spawning floor thingy
	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioSpawningFloorIntensity(float Intensity)
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioPillowPuzzleSolved(int PuzzleNumber)
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioCurrentKaleidoscopeStrength(float Str)
	{
		
	}
}