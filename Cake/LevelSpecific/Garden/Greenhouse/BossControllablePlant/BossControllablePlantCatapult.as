import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlant;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantPlayerComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PlantCatapultProjectileSpawner;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PlantCatapultProjectile;

UCLASS(Abstract)
class ABossControllablePlantCatapult : ABossControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent ProjectileAttachPoint;

	UPROPERTY(Category="Catapult")
	bool bLaunchingProjectiles = true;

	UPROPERTY(Category="Catapult")
	bool bShootAtPlayer;

	UPROPERTY(Category="Catapult")
	float AttackRange = 5000.0f;

	UPROPERTY(Category="Catapult")
	APlantCatapultProjectileSpawner ProjectileSpawner;

	UPROPERTY(Category="Catapult")
	APlantCatapultProjectile CurrentProjectile;

	UPROPERTY(Category="Catapult")
	float ProjectileSpeed = 10000.0f;

	UPROPERTY(Category="Catapult")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AddCapability(n"BossControllablePlantCatapultAttackCapability");
		ProjectileSpawner.OnSpawnerWitheredAway.AddUFunction(this, n"StopLaunchingProjectiles");
	}

	UFUNCTION()
	void StopLaunchingProjectiles()
	{
		bLaunchingProjectiles = false;
	}
}