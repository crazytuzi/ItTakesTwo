import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PlantCatapultProjectileSpawner;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.PlantCatapultProjectile;

class UPlantCatapultProjectileSpawnerSpawnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	APlantCatapultProjectileSpawner Spawner;

	bool bSpawnNewProjectile = false;

	int CurrentProjectileIndex = 0;

	float SpawnDelay = 3.0f;
	float SpawnTimer = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Spawner = Cast<APlantCatapultProjectileSpawner>(Owner);

		for(int i = 0; i <= Spawner.NumberOfContainedProjectiles - 1; i++)
		{
			APlantCatapultProjectile Projectile = Cast<APlantCatapultProjectile>(SpawnActor(Spawner.ProjectileClass));
			Projectile.MakeNetworked(Game::GetMay(), i);
			Projectile.SetControlSide(Game::GetMay());
	
			Projectile.DeactivateProjectile();

			//Projectile.OnSnowCannonProjectileHit.AddUFunction(this, n"ProjectileHit");
			Spawner.ProjectileCointainer.Add(Projectile);
		}

		bSpawnNewProjectile = true;
		
		Spawner.OnProjectilePickedUpFromSpawner.AddUFunction(this, n"OnProjectilePickedUpFromSpawner");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bSpawnNewProjectile)
		{
			return EHazeNetworkActivation::DontActivate; 
		}

        return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bSpawnNewProjectile)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpawnTimer = 0.0f;
		Spawner.bHoldingProjectile = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SpawnTimer += DeltaTime;

		if(SpawnTimer >= SpawnDelay)
		{
			SpawnProjectile();
		}
	}


	UFUNCTION()
	void SpawnProjectile()
	{
		CurrentProjectileIndex++;
		if(CurrentProjectileIndex >= Spawner.NumberOfContainedProjectiles)
			CurrentProjectileIndex = 0;
			
		Spawner.CurrentlyHeldProjectile = Spawner.ProjectileCointainer[CurrentProjectileIndex];

		Spawner.CurrentlyHeldProjectile.SetActorTransform(Spawner.SpawnLocation.GetWorldTransform());
		Spawner.CurrentlyHeldProjectile.ActivateProjectile();
			
		bSpawnNewProjectile = false;
	}
	

	UFUNCTION()
	void OnProjectilePickedUpFromSpawner()
	{
		Spawner.bHoldingProjectile = false;
		bSpawnNewProjectile = true;
	}

}
