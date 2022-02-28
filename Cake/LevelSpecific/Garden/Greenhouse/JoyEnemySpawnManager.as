import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;

event void FOnEnemyLost(int EnemiesLeft);
event void FOnEnemySpawned(ASickleEnemy Enemy);

class AJoyEnemySpawnManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)
	USickleEnemySpawnManagerComponent SickleEnemySpawnManagerComponent;

	UPROPERTY()
	FOnEnemyLost OnEnemyLost;
	UPROPERTY()
	FOnEnemySpawned OnEnemySpawned;

	UPROPERTY()
	bool bOnStartActive = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleEnemySpawnManagerComponent.OnEnemyLost.AddUFunction(this, n"EnemyLost");
		SickleEnemySpawnManagerComponent.OnEnemySpawned.AddUFunction(this, n"EnemySpawned");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds){}

	UFUNCTION()
	void EnemySpawned(ASickleEnemy Enemy)
	{
		OnEnemySpawned.Broadcast(Enemy);
	}

	UFUNCTION()
	void EnemyLost(int EnemiesLeft)
	{
		OnEnemyLost.Broadcast(EnemiesLeft);
	}

	UFUNCTION()
	void EnableSpawnActor()
	{
		EnableActor(nullptr);
	}

	UFUNCTION()
	void DisableSpawnActor()
	{	
		if(!IsActorDisabled())
			DisableActor(nullptr);
	}
}

