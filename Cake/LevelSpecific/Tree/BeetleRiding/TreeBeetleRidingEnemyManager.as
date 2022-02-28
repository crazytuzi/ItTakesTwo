import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingEnemy;

class ATreeBeetleRidingEnemyManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.SetWorldScale3D(20.f);

	UPROPERTY()
	int PoolSize = 10;

	UPROPERTY()
	TSubclassOf<ATreeBeetleRidingEnemy> EnemyClass;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		return;

		// for (int i = 0; i < PoolSize; i++)
		// {
		// 	ATreeBeetleRidingEnemy Enemy = Cast<ATreeBeetleRidingEnemy>(SpawnActor(EnemyClass, bDeferredSpawn = false, Level = this.Level));
		// }
	}

}