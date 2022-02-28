import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawner;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.WaspTypes;

namespace TreeCombatStatics
{
	// When called this will deactivate any active spawners in tree, cause any wasps to flee and kill any larva
	UFUNCTION(Category = "Combat")
	void ClearTreeCombat()
	{
		UHazeAITeam SpawnersTeam = HazeAIBlueprintHelper::GetTeam(n"AllSpawnersTeam");
		if (SpawnersTeam != nullptr)
		{
			for (AHazeActor Member : SpawnersTeam.GetMembers())
			{
				AWaspEnemySpawner Spawner = Cast<AWaspEnemySpawner>(Member);
				if (Spawner != nullptr)
					Spawner.DeactivateSpawner();
			}
		}

		UHazeAITeam WaspsTeam = HazeAIBlueprintHelper::GetTeam(Wasp::TeamName);
		if (WaspsTeam != nullptr)
		{
			for (AHazeActor Member : WaspsTeam.GetMembers())
			{
				UWaspBehaviourComponent BehaviourComp = UWaspBehaviourComponent::Get(Member);
				if ((BehaviourComp != nullptr) && !BehaviourComp.HealthComp.bIsDead)
					BehaviourComp.Flee();
			}
		}

		UHazeAITeam LarvaTeam = HazeAIBlueprintHelper::GetTeam(n"LarvaTeam");
		if (LarvaTeam != nullptr)
		{
			for (AHazeActor Member : LarvaTeam.GetMembers())
			{
				ULarvaBehaviourComponent BehaviourComp = ULarvaBehaviourComponent::Get(Member);
				if ((BehaviourComp != nullptr) && !BehaviourComp.bIsDead)
					BehaviourComp.Explode();
			}
		}
	}
}