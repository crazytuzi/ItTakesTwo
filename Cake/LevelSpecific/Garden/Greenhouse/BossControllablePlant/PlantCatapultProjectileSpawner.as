import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PlantCatapultProjectile;
import Cake.LevelSpecific.Garden.Greenhouse.BossRoomRootBulb;

event void FOnProjectilePickedUpFromSpawner();
event void FOnSpawnerWitheredAway();

UCLASS(Abstract)
class APlantCatapultProjectileSpawner : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnLocation;

	UPROPERTY()
	TArray<APlantCatapultProjectile> ProjectileCointainer;

	UPROPERTY()
	APlantCatapultProjectile CurrentlyHeldProjectile;

	UPROPERTY()
	int NumberOfContainedProjectiles = 3;

	UPROPERTY()
	TSubclassOf<APlantCatapultProjectile> ProjectileClass;

	UPROPERTY()
	FOnProjectilePickedUpFromSpawner OnProjectilePickedUpFromSpawner;

	UPROPERTY()
	ABossRoomRootBulb RootBulb;

	bool bHoldingProjectile = false;

	UPROPERTY()
	FOnSpawnerWitheredAway OnSpawnerWitheredAway;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"PlantCatapultProjectileSpawnerSpawnCapability");
		// AddCapability(n"BossControllablePlantHammerMovementCapability");
		// AddCapability(n"BossControllablePlantHammerSmashingCapability");

		// BoxCollider.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionBeginOverlap");
		// BoxCollider.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionExitOverlap");

		if(RootBulb != nullptr)
		{
			RootBulb.OnBulbExploded.AddUFunction(this, n"WitherAway");
		}
	}

	UFUNCTION()
	void WitherAway()
	{
		OnSpawnerWitheredAway.Broadcast();
		DestroyActor();
	}
}