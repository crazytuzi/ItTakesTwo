import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Vino.AI.ScenePoints.ScenePointComponent;
import Peanuts.Spline.SplineComponent;

namespace WaspSpawnPoolStatics
{
	UWaspSpawnPoolComponent GetOrCreateSpawnPool(TSubclassOf<AHazeActor> SpawnClass, AActor User)
	{
		if (!SpawnClass.IsValid() || (User == nullptr))
			return nullptr;

		// User.LevelScriptActor will only accept HazeLevelScriptActors, which might not work in test levels
		AActor PoolOwner = User.Level.LevelScriptActor; 
		if (!ensure(PoolOwner != nullptr))
			return nullptr;

		// We create separate pools for users which are remotely and locally controlled
		bool bRemoteControlled = (User.HasControl() != PoolOwner.HasControl());
		FName PoolName = GetSpawnPoolName(SpawnClass, bRemoteControlled);
		UWaspSpawnPoolComponent SpawnPool = Cast<UWaspSpawnPoolComponent>(PoolOwner.GetComponent(UWaspSpawnPoolComponent::StaticClass(), PoolName));
		if (SpawnPool == nullptr)
		{
			SpawnPool = Cast<UWaspSpawnPoolComponent>(PoolOwner.GetOrCreateComponent(UWaspSpawnPoolComponent::StaticClass(), PoolName));
			SpawnPool.SpawnClass = SpawnClass;
			SpawnPool.MakeNetworked(PoolName);
			SpawnPool.bRemoteControlled = bRemoteControlled;
		}
		return SpawnPool;
	}

	FName GetSpawnPoolName(TSubclassOf<AHazeActor> SpawnClass, bool bRemoteControlled)
	{
		if (!SpawnClass.IsValid())
			return bRemoteControlled ? n"DefaultSpawnPoolRemote" : n"DefaultSpawnPool";

		return FName("SpawnPool_" + (bRemoteControlled ? "Remote_" : "") + SpawnClass.Get().GetFullName());
	}
}

struct FWaspSpawnParameters
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;

	UPROPERTY()
	UScenepointComponent Scenepoint = nullptr;

	UPROPERTY()
	UHazeSplineComponent Spline = nullptr;
}

event void FOnSpawned(UObject Spawner, AHazeActor Enemy, FWaspSpawnParameters Params);

class UWaspSpawnPoolComponent : UActorComponent
{
	UPROPERTY(Transient)
	TSubclassOf<AHazeActor> SpawnClass = nullptr;

	// This will notify every spawner using this pool whenever something is 
	// spawned, but delegates are habsch with TMaps or TArrays.
	UPROPERTY(Transient)
	FOnSpawned OnSpawned;	

	TArray<AHazeActor> RespawnableWasps;
	TSet<AHazeActor> ControlRespawnables;  // Actors that are only respawnable on control side 
	TSet<AHazeActor> RemoteRespawnables;   // Actors that have been reported respawnable on remote side
	int SpawnCounter = 0;
	bool bRemoteControlled = false;

	bool IsMatchingControl(UObject Other)
	{
		if (bRemoteControlled)
			return Other.HasControl() != HasControl();
		return Other.HasControl() == HasControl();
	}

	UFUNCTION()
	AHazeActor SpawnWasp(UObject Spawner, FWaspSpawnParameters Params)
	{
		if (HasControl() == bRemoteControlled)
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
			NetRespawnWasp(Wasp, Spawner, Params);
			return Wasp;
		}

		// Spawn wasp locally and remote (since we need to return spawned wasp we cannot use netfunction for both sides)
		NetRemoteSpawnWasp(Spawner, Params);
		return SpawnWaspLocal(Spawner, Params);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRespawnWasp(AHazeActor Wasp, UObject Spawner, FWaspSpawnParameters Params)
	{
		// Reset wasp
		UWaspRespawnerComponent Respawner = UWaspRespawnerComponent::Get(Wasp);
		Respawner.Reset();
		RegisterRespawnable(Wasp);
		Wasp.TeleportActor(Params.Location, Params.Rotation);
		if (Wasp.IsActorDisabled(Wasp))
			Wasp.EnableActor(Wasp);
		OnSpawned.Broadcast(Spawner, Wasp, Params);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRemoteSpawnWasp(UObject Spawner, FWaspSpawnParameters Params)
	{
		// Non-controlled side only, since we call local spawn on control side directly to get spawned wasp
		if (HasControl() == bRemoteControlled)
			SpawnWaspLocal(Spawner, Params);
	}

	private AHazeActor SpawnWaspLocal(UObject Spawner, FWaspSpawnParameters Params)
	{
		// Spawn a new wasp
		AActor Actor = SpawnActor(SpawnClass, Params.Location, Params.Rotation, NAME_None, true, Owner.GetLevel());
        AHazeActor Wasp = Cast<AHazeActor>(Actor);
		if (!ensure(Wasp != nullptr))
			return nullptr;
		RegisterRespawnable(Wasp);
		Wasp.MakeNetworked(this, SpawnCounter);
		FinishSpawningActor(Wasp);
		SpawnCounter++;
		OnSpawned.Broadcast(Spawner, Wasp, Params);
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
		if (!Wasp.IsA(SpawnClass))
			return; // Apartheid!

		if (Network::IsNetworked())
		{
			if (HasControl() != bRemoteControlled)
			{
				// Controlled side
				if (RemoteRespawnables.Contains(Wasp))
				{
					// Wasp has been reported respawnable on remote side, make it available straight away
					RemoteRespawnables.Remove(Wasp);
					if (ensure(!RespawnableWasps.Contains(Wasp)))
						RespawnableWasps.Add(Wasp);
				}
				else
				{
					// Wasp is respawnable on control side, but not yet on remote.
					ControlRespawnables.Add(Wasp);	
				}
			}
			else
			{ // Non-controlled side, just report that it's respawnable on this side as well
				NetReportRespawnable(Wasp);
			}
		}
		else
		{	// Non-network play, we can reuse wasp immediately
			if (ensure(!RespawnableWasps.Contains(Wasp)))
				RespawnableWasps.Add(Wasp);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetReportRespawnable(AHazeActor Wasp)
	{
		// We only care about this on controlled side
		if (HasControl() != bRemoteControlled)
		{
			if (ControlRespawnables.Contains(Wasp))
			{
				// Was respawnable on control side, it can now be respanwed
				ControlRespawnables.Remove(Wasp);				
				if (ensure(!RespawnableWasps.Contains(Wasp)))
					RespawnableWasps.Add(Wasp);
			}
			else
			{
				// Not respawnable on control side yet, remember that remote side is ok with respawn.
				RemoteRespawnables.Add(Wasp);
			}
		}
	}
}

