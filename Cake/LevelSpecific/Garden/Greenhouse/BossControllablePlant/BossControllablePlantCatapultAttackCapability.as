import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantCatapult;
import Vino.PlayerHealth.PlayerHealthStatics;

class UBossControllablePlantCatapultAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossControllablePlantCatapult Plant;

	FVector ProjectileVelocity;

	bool bProjectileLaunched = false;
	bool bProjectileDestroyed = false;

	float ThrowDelay = 2.0f;
	float ThrowTimer = 0.0f;

	float ProjectileLifetime = 10.0f;
	float ProjectileTimer = 0.0f;

	AHazePlayerCharacter TargettedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Plant = Cast<ABossControllablePlantCatapult>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Plant.bIsAlive)
			return EHazeNetworkActivation::DontActivate; 

		if(Plant.ProjectileSpawner == nullptr)
			return EHazeNetworkActivation::DontActivate; 

		if(!Plant.ProjectileSpawner.bHoldingProjectile)
			return EHazeNetworkActivation::DontActivate; 

		if(Plant.bBeingControlled)
			return EHazeNetworkActivation::DontActivate; 

		if(!IsAnyPlayerInAttackRange())
			return EHazeNetworkActivation::DontActivate; 

		if(!IsLastProjectileFinished())
			return EHazeNetworkActivation::DontActivate; 
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION()
	bool IsAnyPlayerInAttackRange() const
	{
		float DistanceToMay = Plant.ActorLocation.DistXY(Game::GetMay().ActorLocation);
		float DistanceToCody = Plant.ActorLocation.DistXY(Game::GetCody().ActorLocation);

		if(DistanceToMay < Plant.AttackRange)
		{
			return true;
		}
		else if(DistanceToCody < Plant.AttackRange)
		{
			UBossControllablePlantPlayerComponent BossControllablePlantComp = UBossControllablePlantPlayerComponent::Get(Game::GetCody());
 			if(BossControllablePlantComp != nullptr)
			{
				if(BossControllablePlantComp.bInSoil)
					return false;
			}
			return true;
		}

		return false;
	}

	UFUNCTION()
	bool IsLastProjectileFinished() const
	{
		if(Plant.CurrentProjectile != nullptr)
		{
			if(Plant.CurrentProjectile.bLaunched)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}	

		if(bProjectileDestroyed)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// UFUNCTION(BlueprintOverride)
	// void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	// {
	// 	Params.AddVector(n"SpawnLocation", SnowCannon.ShootLocation.WorldLocation);
	// 	Params.AddVector(n"SpawnRotation", SnowCannon.ShootLocation.WorldRotation.Euler());
	// 	Params.AddVector(n"Direction", SnowCannon.ShootLocation.ForwardVector);
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		float DistanceToMay = Plant.ActorLocation.DistXY(Game::GetMay().ActorLocation);
		float DistanceToCody = Plant.ActorLocation.DistXY(Game::GetCody().ActorLocation);
 
		if(DistanceToMay < Plant.AttackRange)
		{
			TargettedPlayer = Game::GetMay();
		}
		else if(DistanceToCody < Plant.AttackRange)
		{
			if(UBossControllablePlantPlayerComponent::Get(Game::GetCody()).bInSoil)
				return;

			TargettedPlayer = Game::GetCody();
		}

		Plant.CurrentProjectile = Plant.ProjectileSpawner.CurrentlyHeldProjectile;
		Plant.CurrentProjectile.SetActorTransform(Plant.ProjectileAttachPoint.GetWorldTransform());

		Plant.ProjectileSpawner.OnProjectilePickedUpFromSpawner.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ThrowTimer = 0.0f;
		bProjectileDestroyed = false;
		bProjectileLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Print("Catapult shooting");
		if(!bProjectileLaunched)
		{
			ThrowTimer += DeltaTime;

			if(ThrowTimer >= ThrowDelay)
			{
				LaunchProjectile();
				ThrowTimer = 0.0f;
				bProjectileLaunched = true;
			}
		}
		else
		{
			Plant.CurrentProjectile.AddActorWorldOffset(ProjectileVelocity*DeltaTime);
			Plant.CurrentProjectile.SetActorRotation(Math::MakeRotFromX(ProjectileVelocity*DeltaTime));
			TraceForHits(DeltaTime);

			ProjectileTimer += DeltaTime;

			if(ProjectileTimer >= ProjectileLifetime)
			{
				DisableProjectile();
			}
		}
	}

	void LaunchProjectile()
	{
		ProjectileVelocity = (TargettedPlayer.ActorLocation + FVector(0, 0, 176.f)) - Plant.CurrentProjectile.ActorLocation;
		ProjectileVelocity.Normalize();
		ProjectileVelocity *= Plant.ProjectileSpeed;
	}

	void TraceForHits(float DeltaTime)
	{
		FVector ProjectileDelta = ProjectileVelocity * DeltaTime;
		FVector ProjectileCurrentLocation = Plant.CurrentProjectile.ActorLocation;
	
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Plant);
		ActorsToIgnore.Add(Plant.CurrentProjectile);

		FHitResult Hit;
		System::SphereTraceSingle(ProjectileCurrentLocation, ProjectileCurrentLocation + ProjectileDelta, 100.0f, ETraceTypeQuery::WeaponTrace , true, ActorsToIgnore, EDrawDebugTrace::ForDuration, Hit, true);

		if (!Hit.bBlockingHit)
		{
			return;
		}
		else
		{
			OnCollision(Hit);
		}
	}

	void OnCollision(FHitResult CollisionHit)
	{
		Plant.CurrentProjectile.OnPlantCatapultProjectileHit.Broadcast(CollisionHit);
		Plant.CurrentProjectile.DeactivateProjectile();
		
		if(Cast<AHazePlayerCharacter>(CollisionHit.Actor) != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CollisionHit.Actor);
			KillPlayer(Player, Plant.DeathEffect);
		}

		Niagara::SpawnSystemAtLocation(Plant.CurrentProjectile.NiagaraFX, CollisionHit.ImpactPoint);		

		bProjectileDestroyed = true;
	}

	void DisableProjectile()
	{
		Plant.CurrentProjectile.DeactivateProjectile();
		bProjectileDestroyed = true;
	}

}
