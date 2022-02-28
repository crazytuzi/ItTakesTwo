import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawner;

class AWaspFleeVolume : APlayerTrigger
{
	UPROPERTY()
	TArray<AWaspEnemySpawner> Spawners;  


	void EnterTrigger(AActor Actor) override
    {
		Super::EnterTrigger(Actor);
        
		for(AWaspEnemySpawner Spawner : Spawners)
		{
			if (System::IsValid(Spawner))
			{
				Spawner.Flee();
				Spawner.DeactivateSpawner();
			}
		}
    }

}