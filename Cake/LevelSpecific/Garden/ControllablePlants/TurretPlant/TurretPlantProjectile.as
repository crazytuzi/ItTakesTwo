import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.TurretPlant.TurretPlantImpactComponent;
import Cake.Weapons.RangedWeapon.RangedWeaponProjectile;

UCLASS(Abstract)
class ATurretPlantProjectile : ARangedWeaponProjectile
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ProjectileMesh;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	bool bMoving = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMoving)
		{
			FVector DeltaMove = ActorForwardVector * 7000.f * DeltaTime;

			FHitResult Hit;
			TArray<AActor> ActorsToIgnore;
			System::LineTraceSingle(ActorLocation, ActorLocation + DeltaMove, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

			if (Hit.bBlockingHit)
			{
				UTurretPlantImpactComponent TurretPlantImpact = UTurretPlantImpactComponent::Get(Hit.Actor);

				if(TurretPlantImpact != nullptr)
				{
					FTurretPlantHitInfo TurretPlantHitInfo;
					TurretPlantHitInfo.HitActor = Hit.Actor;
					TurretPlantHitInfo.HitComponent = Hit.Component;
					TurretPlantHitInfo.HitLocation = Hit.ImpactPoint;

					TurretPlantImpact.HandleTurretPlantImpact(TurretPlantHitInfo);
				}

				Explode(Hit);
				bMoving = false;
				return;
			}
			
			AddActorWorldOffset(DeltaMove);
		}
	}

	void Explode(FHitResult HitResult)
	{
		Niagara::SpawnSystemAtLocation(ExplosionEffect, HitResult.Location);

		TArray<AHazeActor> ValidActors;

		TArray<AActor> HitActors;
		TArray<AActor> ActorsToIgnore;
		Trace::SphereOverlapActorsMultiByChannel(HitActors, ActorLocation, 200.f, ETraceTypeQuery::Visibility, ActorsToIgnore);

		for (AActor CurActor : HitActors)
		{
			AHazeActor HazeActor;
			HazeActor = Cast<AHazeActor>(CurActor);
			
			if (HazeActor == nullptr)
				continue;

			ValidActors.AddUnique(HazeActor);
		}

		/*
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(ValidActors);

		for (ACastleEnemy CurEnemy : HitEnemies)
		{
			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageDealt = 4.f;
			DamageEvent.DamageLocation = ActorLocation;
			DamageEvent.DamageSource = this;
			CurEnemy.TakeDamage(DamageEvent);
		}
		*/
		DestroyActor();
	}
}