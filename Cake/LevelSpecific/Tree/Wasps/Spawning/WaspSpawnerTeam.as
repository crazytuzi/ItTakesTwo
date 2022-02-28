import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;

UFUNCTION(Category = "Spawning", BlueprintPure)
FName GetSpawnerTeamName(TSubclassOf<AHazeActor> SpawnClass)
{
	if (!SpawnClass.IsValid())
		return n"DefaultSpawnerTeam";

	return FName("Team_" + SpawnClass.Get().GetName());
}

class UWaspSpawnerTeam : UHazeAITeam
{
	UPROPERTY(Transient)
	TSubclassOf<AHazeActor> WaspClass = nullptr;

	TArray<AHazeActor> RespawnableWasps;
	int SpawnCounter = 0;

	bool IsInitialized()
	{
		return WaspClass.IsValid();	
	}

	void Initialize(TSubclassOf<AHazeActor> SpawnClass)
	{
		WaspClass = SpawnClass;
		MakeNetworked(GetSpawnerTeamName(SpawnClass));
	}

	UFUNCTION()
	AHazeActor SpawnWasp(FVector Location, FRotator Rotation = FRotator::ZeroRotator)
	{
		if (!HasControl())
			return nullptr;

		for (int i = RespawnableWasps.Num() - 1; i >= 0; i--)
		{
			if (!System::IsValid(RespawnableWasps[i]))
				RespawnableWasps.RemoveAtSwap(i);
		}

		if (RespawnableWasps.Num() > 0)
		{	
			// Respawn existing wasp
			int LastIndex = RespawnableWasps.Num() - 1;
			AHazeActor Wasp = RespawnableWasps[LastIndex];
			RespawnableWasps.RemoveAt(LastIndex);
			NetRespawnWasp(Wasp, Location, Rotation);
			return Wasp;
		}

		// Spawn wasp locally and remote (since we need to return spawned wasp we cannot use netfunction for both sides)
		NetRemoteSpawnWasp(Location, Rotation);
		return SpawnWaspLocal(Location, Rotation);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRespawnWasp(AHazeActor Wasp, const FVector& Location, const FRotator& Rotation)
	{
		// Reset wasp
		UWaspRespawnerComponent Respawner = UWaspRespawnerComponent::Get(Wasp);
		Respawner.Reset();
		RegisterRespawnable(Wasp);
		Wasp.TeleportActor(Location, Rotation);
		if (Wasp.IsActorDisabled(Wasp))
			Wasp.EnableActor(Wasp);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRemoteSpawnWasp(const FVector& Location, const FRotator& Rotation)
	{
		// Remote side only, since we call local spawn on control side directly to get spawned wasp
		if (!HasControl())
			SpawnWaspLocal(Location, Rotation);
	}

	private AHazeActor SpawnWaspLocal(const FVector& Location, const FRotator& Rotation)
	{
		// Spawn a new wasp
		AActor Actor = SpawnActor(WaspClass, Location, Rotation, NAME_None, true);
        AHazeActor Wasp = Cast<AHazeActor>(Actor);
		if (!ensure(Wasp != nullptr))
			return nullptr;
		RegisterRespawnable(Wasp);
		Wasp.MakeNetworked(this, SpawnCounter);
		FinishSpawningActor(Wasp);
		SpawnCounter++;
		return Wasp;
	}

	void RegisterRespawnable(AHazeActor Wasp)
	{
		// Make sure wasp let's us know when it can be respawned again
		UWaspRespawnerComponent Respawner = UWaspRespawnerComponent::Get(Wasp);
		Respawner.OnRespawnable.AddUFunction(this, n"OnRespawnableWasp");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawnableWasp(AHazeActor Wasp)
	{
		if (!HasControl())
			return;

		if (!Wasp.IsA(WaspClass))
			return; // Apartheid!

		if (ensure(!RespawnableWasps.Contains(Wasp)))
			RespawnableWasps.Add(Wasp);
	}
}

