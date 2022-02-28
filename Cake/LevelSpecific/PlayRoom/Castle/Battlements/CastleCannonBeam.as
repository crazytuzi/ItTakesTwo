import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

UCLASS(Abstract)
class ACastleCannonBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float BeamRange = 100000;
	float BeamRadius = 100;

	bool bActive = false;

	void ActivateBeam()
	{
		bActive = true;
	}

	void DeactivateBeam()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Print("Beam Tick Active");
		Beam(DeltaTime);
		if (!bActive)
			return;
			
	}

	void Beam(float DeltaTime)
	{
		FVector Direction = ActorForwardVector * BeamRange;
		FVector BeamEndLocation = GetBeamEndLocation(Direction);

		/*if (Hit.bBlockingHit)
		{			
			DamageNearbyEnemies();	
		}*/
	}

	FVector GetBeamEndLocation(FVector BeamDirection)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Owner);

		FHitResult HitResult;
		
		//--System::LineTraceSingleByProfile(ActorLocation, ActorLocation + BeamDirection, n"IgnoreOnlyPawn", false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, HitResult, true);

		//System::SphereTraceMulti(ActorLocation, ActorLocation + BeamDirection, BeamRadius, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, HitResults, true);
		

		return HitResult.Location;
	}

	UFUNCTION(BlueprintEvent)
	void DamageNearbyEnemies()	
	{
		/*TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesInCone(ActorLocation, ActorRotation, ProjectileHitRadius, 360, true);	

		for (ACastleEnemy HitEnemy : HitEnemies)
		{
			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageDealt = 20;
			DamageEvent.DamageSource = Game::GetCody();
			DamageEvent.DamageLocation = HitEnemy.ActorLocation;
			

			HitEnemy.TakeDamage(DamageEvent);
			//UCastleComponent::GetOrCreate(Game::GetCody()).PlayerDamagedEnemy(Enemy, DamageEvent);
			//HitEnemy.TakeDamage()
		}*/
	}
}