
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

// Directs/Manages all swarms. 

event void FSwarmStateChanged(ASwarmActor Swarm);

UCLASS(HideCategories = "Activation Replication Input Cooking LOD Actor")
class UQueenBehaviourComponent : UActorComponent 
{
	UPROPERTY()
	TArray<ASwarmActor> Swarms;

	UPROPERTY()
	EQueenManagerState State;

	UPROPERTY()
	FSwarmStateChanged OnSwarmSpawned;

	UPROPERTY()
	FSwarmStateChanged OnSwarmDied;

	UHazeComposableSettings CurrentSettings = nullptr;
	UHazeCapabilitySheet CurrentBehaviourSheet = nullptr;

	void RecruitSwarm(ASwarmActor InSwarm)
	{
		if (Swarms.Num() >= 4)
		{
			devEnsure(false, "Trying to add more than 4 swarms! Network desync. \n Please notify Sydney about this");
			return;
		}

		Swarms.AddUnique(InSwarm);

		InSwarm.OnAboutToDie.AddUFunction(this, n"HandleSwarmDeath");

		OnSwarmSpawned.Broadcast(InSwarm);
	}

	UFUNCTION()
	void HandleSwarmDeath(ASwarmActor Swarm)
	{
		Swarms.Remove(Swarm);
		OnSwarmDied.Broadcast(Swarm);

		Swarm.OnAboutToDie.Unbind(this, n"HandleSwarmDeath");

		// @TODO: Pool the swarms: give them back to the swarm builder 
		// We disable swarm not destroy them.
		// Swarm.DestroyActor();
	}
}

enum EQueenManagerState
{
	None,
	Solo,
	Duo,
	Trio,
	Quad,
	MAX,
};

FString GetQueenDebugStateName(EQueenManagerState State)
{
	switch (State)
	{
		case EQueenManagerState::None:
			return "None";
		case EQueenManagerState::Solo:
			return "Solo";
		case EQueenManagerState::Duo:
			return "Duo";
		case EQueenManagerState::Trio:
			return "Trio";
		case EQueenManagerState::Quad:
			return "Quad";
		case EQueenManagerState::MAX:
			ensure(false);
			return "MAX";
	}
	ensure(false);
	return "None";
}





