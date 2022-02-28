
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.LevelSpecific.Tree.Swarm.Builder.SwarmBuilderActor;

UFUNCTION(Category = "Swarm")
void KillAllSwarms(const bool bIgnoreDisabledSwarms = true, const bool bIgnoreSwarmsBeingBuilt = true)
{
	TArray<AActor> SwarmList;
	Gameplay::GetAllActorsOfClass(ASwarmActor::StaticClass(), SwarmList);

	TArray<AActor> SwarmBuilders;
	if(bIgnoreSwarmsBeingBuilt)
		Gameplay::GetAllActorsOfClass(ASwarmBuilderActor::StaticClass(), SwarmBuilders);
	
	for (AActor Actor : SwarmList)
	{
		ASwarmActor SwarmActor = Cast<ASwarmActor>(Actor);
		if(!bIgnoreDisabledSwarms || bIgnoreDisabledSwarms && !SwarmActor.IsActorDisabled())
		{
			if(!bIgnoreSwarmsBeingBuilt && bIgnoreSwarmsBeingBuilt && !SwarmBuilders.Contains(SwarmActor))
			{
				SwarmActor.KillSwarm();
			}
		}
	}
}

UFUNCTION(Category = "Swarm")
void ParkAllSwarms(AQueenActor Queen, const bool bIgnoreDisabledSwarms = true, const bool bIgnoreSwarmsBeingBuilt = true)
{
	TArray<AActor> SwarmActorList;
	Gameplay::GetAllActorsOfClass(ASwarmActor::StaticClass(), SwarmActorList);
	TArray<ASwarmActor> Swarmlist;

	TArray<AActor> SwarmBuilders;
	if(bIgnoreSwarmsBeingBuilt)
		Gameplay::GetAllActorsOfClass(ASwarmBuilderActor::StaticClass(), SwarmBuilders);

	for (AActor Actor : SwarmActorList)
	{
		ASwarmActor SwarmActor = Cast<ASwarmActor>(Actor);

		if(bIgnoreDisabledSwarms && SwarmActor.IsActorDisabled())
			continue;

		if(bIgnoreSwarmsBeingBuilt && SwarmBuilders.Contains(SwarmActor))
			continue;

		Swarmlist.Add(SwarmActor);
	}
	
	Queen.ParkingSpotComp.ParkSwarms(Swarmlist);
}

UFUNCTION(Category = "Swarm")
void UnparkAllSwarms(AQueenActor Queen, const bool bIgnoreDisabledSwarms = true, const bool bIgnoreSwarmsBeingBuilt = true)
{
	TArray<AActor> SwarmActorList;
	Gameplay::GetAllActorsOfClass(ASwarmActor::StaticClass(), SwarmActorList);

	TArray<AActor> SwarmBuilders;
	if(bIgnoreSwarmsBeingBuilt)
		Gameplay::GetAllActorsOfClass(ASwarmBuilderActor::StaticClass(), SwarmBuilders);

	TArray<ASwarmActor> Swarmlist;
	for (AActor Actor : SwarmActorList)
	{
		ASwarmActor SwarmActor = Cast<ASwarmActor>(Actor);

		if(bIgnoreDisabledSwarms && SwarmActor.IsActorDisabled())
			continue;

		if(bIgnoreSwarmsBeingBuilt && SwarmBuilders.Contains(SwarmActor))
			continue;

		if(Queen.ParkingSpotComp.IsParked(SwarmActor))
			Swarmlist.Add(SwarmActor);
	}
	
	Queen.ParkingSpotComp.UnparkSwarms(Swarmlist);
}

UFUNCTION(Category = "Swarm")
void DisableAllSwarms(UObject Disabler)
{
	TArray<AActor> SwarmList;
	Gameplay::GetAllActorsOfClass(ASwarmActor::StaticClass(), SwarmList);
	
	for (AActor Actor : SwarmList)
	{
		ASwarmActor SwarmActor = Cast<ASwarmActor>(Actor);
		if(!SwarmActor.IsActorDisabled(Disabler))
		{
			SwarmActor.DisableActor(Disabler);
		}
	}
}

UFUNCTION(Category = "Swarm")
void EnableAllSwarms(UObject Disabler)
{
	TArray<AActor> SwarmList;
	Gameplay::GetAllActorsOfClass(ASwarmActor::StaticClass(), SwarmList);
	
	for (AActor Actor : SwarmList)
	{
		ASwarmActor SwarmActor = Cast<ASwarmActor>(Actor);
		
		if (SwarmActor.IsActorDisabled(Disabler))
		{
			SwarmActor.EnableActor(Disabler);
		}
	}
}