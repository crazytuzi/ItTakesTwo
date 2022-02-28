import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;

event void FGardenEnemySpawnerAllEnemiesLost(AGardenEnemySpawnerActor EnemySpawner);

class AGardenEnemySpawnerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USickleEnemySpawnManagerComponent EnemySpawnManagerComp;

	FGardenEnemySpawnerAllEnemiesLost EnemySpawnerAllEnemiesLost;


	bool bAllEnemiesHaveLost = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		EnemySpawnManagerComp.OnEnemyLost.AddUFunction(this, n"OnLostEnemy");
	}


	UFUNCTION()
	void OnLostEnemy(int EnemiesLeft)
	{
		if(EnemiesLeft <= 0)
		{
			bAllEnemiesHaveLost = true;
			EnemySpawnerAllEnemiesLost.Broadcast(this);
		}

	}
}