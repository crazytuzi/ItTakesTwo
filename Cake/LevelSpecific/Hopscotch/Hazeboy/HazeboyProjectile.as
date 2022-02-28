import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboySettings;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyExplosion;

import void HazeboyRegisterVisibleActor(AActor Actor, int ExclusivePlayer) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyUnregisterVisibleActor(AActor Actor) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';

class AHazeboyProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinRoot;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<AHazeboyExplosion> ExplosionType;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	UCurveFloat SpinCurve;

	AHazePlayerCharacter OwnerPlayer;
	FVector Target;
	FVector Velocity;

	bool bHasHit = false;
	float DestroyTimer = 2.f;

	float LifeTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeboyRegisterVisibleActor(this, -1);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		HazeboyUnregisterVisibleActor(this);
	}

	void InitProjectile(AHazePlayerCharacter InOwnerPlayer, FVector InOrigin, FVector InTarget)
	{
		SetActorLocation(InOrigin);
		OwnerPlayer = InOwnerPlayer;
		Velocity = CalculateHazeboyProjectileVelocity(InOrigin, InTarget);
		Target = InTarget;

		BP_OnInit(InOwnerPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasHit)
		{
			Velocity.Z -= Hazeboy::ProjectileGravity * DeltaTime;

			FVector DeltaMove = Velocity * DeltaTime;
			AddActorWorldOffset(DeltaMove);

			if (ActorLocation.Z < Target.Z)
			{
				auto Explosion = Cast<AHazeboyExplosion>(SpawnActor(ExplosionType, GetActorLocation(), bDeferredSpawn = true));
				Explosion.OwnerPlayer = OwnerPlayer;
				Explosion.FinishSpawningActor();

				bHasHit = true;
				BP_OnHit();
			}

			// Update spinning
			LifeTime += DeltaTime;
			float SpinAmount = SpinCurve.GetFloatValue(LifeTime);

			SpinRoot.RelativeLocation =
			FVector(0.f, 0.f, 100.f) + 
			FVector(
				0.f,
				FMath::Sin(SpinAmount * TAU),
				-FMath::Cos(SpinAmount * TAU)
			) * 80.f;
		}
		else
		{
			DestroyTimer -= DeltaTime;
			if (DestroyTimer < 0.f)
				DestroyActor();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInit(AHazePlayerCharacter OwnerPlayer) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnHit() {}
}