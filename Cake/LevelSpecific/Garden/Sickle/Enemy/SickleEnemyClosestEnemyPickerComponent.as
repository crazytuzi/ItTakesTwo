import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

event void FOnPickClosestSickleEnemyTrigger();

class UPickClosestSickleEnemyComponent : UActorComponent
{
	default SetComponentTickInterval(0.2f);

	UPROPERTY(EditInstanceOnly)
	ASickleEnemyMovementArea ValidationArea;

	UPROPERTY()
	float TriggerProximityDistance = -1;

	UPROPERTY()
	FOnPickClosestSickleEnemyTrigger OnProximityTriggered;

	private ASickleEnemy ClosestEnemy;
	private float ClosestEnemyDistance;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		SetComponentTickEnabled(false);	
		if(ValidationArea != nullptr)
			System::SetTimer(this, n"ActivateTick", FMath::RandRange(0.f, 1.f), false);
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateTick()
	{
		SetComponentTickEnabled(true);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ClosestEnemy = nullptr;
		ClosestEnemyDistance = BIG_NUMBER;
		for(auto Enemy : ValidationArea.SickleEnemiesControlled)
		{
			const float DistSq = Enemy.GetActorLocation().DistSquared(Owner.GetActorLocation());
			if(DistSq < ClosestEnemyDistance)
			{
				ClosestEnemyDistance = DistSq;
				ClosestEnemy = Enemy;
			}
		}

		if(TriggerProximityDistance >= 0)
		{
			if(ClosestEnemy != nullptr && ClosestEnemyDistance <= FMath::Square(TriggerProximityDistance))
				OnProximityTriggered.Broadcast();
		}
		
	}

	UFUNCTION(BlueprintPure)
	bool GetClosestEnemy(ASickleEnemy& OutClosestEnemy, float& OutlosestEnemyDistance) const
	{
		OutClosestEnemy = ClosestEnemy;
		OutlosestEnemyDistance = FMath::Sqrt(ClosestEnemyDistance);
		return OutClosestEnemy != nullptr;
	}
}