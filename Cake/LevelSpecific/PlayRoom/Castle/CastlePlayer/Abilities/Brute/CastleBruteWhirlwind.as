import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

UCLASS(Abstract)
class ACastleBruteWhirlwind : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DamageCollider;
	default DamageCollider.CollisionProfileName = n"OverlapOnlyPawn";
	default DamageCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default DamageCollider.SetRelativeLocation(FVector(0, 0, 90));
	default DamageCollider.SphereRadius = 300.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpinningVisuals;

	default SetActorHiddenInGame(true);

	AHazePlayerCharacter OwningPlayer;

	float TickInterval = 0.5f;
	float DamagePerTick = 16.f;

	TArray<FCastleHitTimer> DamageTargets;
	
	UPROPERTY()
	FHazeTimeLike StartWhirlWindGrowthTimelike;
	default StartWhirlWindGrowthTimelike.Duration = 0.5f;

	UFUNCTION()
	void ActivateWhirlwind()
	{		
		DamageCollider.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void DeactivateWhirlwind()
	{
		SetActorHiddenInGame(true);	
		DamageCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DamageTargets.Empty();	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DamageCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnDamageColliderBeginOverlap");
		DamageCollider.OnComponentEndOverlap.AddUFunction(this, n"OnDamageColliderEndOverlap");
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DamageEnemies(DeltaTime);
	}

	void DamageEnemies(float DeltaTime)
	{		
		for (FCastleHitTimer& DamageTarget : DamageTargets)
		{
			DamageTarget.Duration -= DeltaTime;

			if (DamageTarget.Duration <= 0)
			{
				if (DamageTarget.CastleEnemy != nullptr)
				{
					DamageEnemy(DamageTarget.CastleEnemy);
				}
				DamageTarget.Duration += TickInterval;
			}
		}
	}	

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		FCastleEnemyDamageEvent DamageEvent;
		DamageEvent.DamageDealt = DamagePerTick;
		DamageEvent.DamageDirection = CastleEnemy.ActorLocation - ActorLocation;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageSpeed = 900.f;
		DamageEvent.DamageSource = OwningPlayer;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);


		FCastleEnemyKnockbackEvent KnockbackEvent;
		KnockbackEvent.Source = OwningPlayer;
		KnockbackEvent.DurationMultiplier = 1.5f;
		KnockbackEvent.Direction = ActorLocation - CastleEnemy.ActorLocation;
		KnockbackEvent.HorizontalForce = 4.f;
		KnockbackEvent.VerticalForce = 6.f;
		CastleEnemy.KnockBack(KnockbackEvent);

	}

	UFUNCTION()
	void OnDamageColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(OtherActor);

		if (CastleEnemy == nullptr)
			return;

		FCastleHitTimer DamageTarget;
		DamageTarget.CastleEnemy = CastleEnemy;
		DamageTarget.Duration = TickInterval;

		DamageTargets.Add(DamageTarget);

		DamageEnemy(CastleEnemy);
	}

	UFUNCTION()
    void OnDamageColliderEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(OtherActor);

		if (CastleEnemy == nullptr)
			return;

		for (int Index = 0, Count = DamageTargets.Num(); Index < Count; ++Index)
		{
			if (CastleEnemy == DamageTargets[Index].CastleEnemy)
			{
				DamageTargets.RemoveAt(Index);
				break;
			}
		}
    }	
}