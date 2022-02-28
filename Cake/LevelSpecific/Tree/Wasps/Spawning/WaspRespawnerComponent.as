event void FWaspRespawnable(AHazeActor Wasp);
event void FWaspRespawnReset();

class UWaspRespawnerComponent : UActorComponent
{
	bool bUnSpawned = false;

	UFUNCTION()
	void UnSpawn(AHazeActor Wasp)
	{
		// Only once until reset
		if (bUnSpawned)
			return;

		bUnSpawned = true;
		if (Wasp != nullptr)
			OnRespawnable.Broadcast(Wasp);
	}

	UFUNCTION()
	void Reset()
	{
		bUnSpawned = false;
		OnReset.Broadcast();
		AHazeActor Wasp = Cast<AHazeActor>(Owner);
		if ((Wasp != nullptr) && (UHazeCrumbComponent::Get(Wasp) != nullptr))
			Wasp.CleanupCurrentMovementTrail();
	}

    // Triggers when we are available for respawning
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspRespawnable OnRespawnable;

	// Triggers when we want to reset an actor for reuse
	UPROPERTY(meta = (NotBlueprintCallable))
	FWaspRespawnReset OnReset;
}