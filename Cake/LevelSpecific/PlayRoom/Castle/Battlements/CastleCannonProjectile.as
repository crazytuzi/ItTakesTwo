import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

UCLASS(Abstract)
class ACastleCannonProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent SphereComp;

	UPROPERTY()
	float ProjectileSpeed = 6000;

	UPROPERTY()
	float ProjectileHitRadius = 250;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		MoveProjectile(DeltaTime);
	}

	void MoveProjectile(float DeltaTime)
	{
		FVector DeltaMove = ActorForwardVector * ProjectileSpeed * DeltaTime;
		FHitResult Hit = TraceDeltaMove(DeltaMove);

		if (Hit.bBlockingHit)
		{
			SetActorLocation(Hit.Location);
			DamageNearbyEnemies();	
			DestroyActor();		
		}
		else
			AddActorWorldOffset(DeltaMove);		
	}

	UFUNCTION(BlueprintEvent)
	void DamageNearbyEnemies()	
	{
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesInCone(ActorLocation, ActorRotation, ProjectileHitRadius, 360, false);	

		for (ACastleEnemy HitEnemy : HitEnemies)
		{
			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageDealt = FMath::RandRange(20.f, 25.f);
			DamageEvent.DamageSource = Game::GetCody();
			DamageEvent.DamageLocation = HitEnemy.ActorLocation;
			

			HitEnemy.TakeDamage(DamageEvent);
			//UCastleComponent::GetOrCreate(Game::GetCody()).PlayerDamagedEnemy(Enemy, DamageEvent);
			//HitEnemy.TakeDamage()
		}
	}
	
	FHitResult TraceDeltaMove(FVector DeltaMove)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Owner);
		FHitResult HitResult;

		System::SphereTraceSingle(	ActorLocation, ActorLocation + DeltaMove, SphereComp.SphereRadius,
									ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

		return HitResult;
	}
}