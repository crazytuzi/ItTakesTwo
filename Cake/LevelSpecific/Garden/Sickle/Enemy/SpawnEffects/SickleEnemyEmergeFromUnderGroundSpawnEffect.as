import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

UCLASS(Abstract)
class USickleEnemyEmergeFromUnderGroundSpawnEffect : USickleEnemySpawningEffect
{
	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	UPROPERTY()
	float SpawnDelayUntilMovement = 0.4f;

	// Internal
	private bool bWaitingForAnimation = false;

	void OnSpawned() override
	{	
		const FVector CurrentLocation = Owner.GetActorLocation();
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(UHazeMovementComponent::Get(Owner));
		TraceParams.SetToLineTrace();
		float CollisionSize = Owner.GetCollisionSize().Y;
		TraceParams.From = CurrentLocation + FVector(0.f, 0.f, CollisionSize);
		TraceParams.To = CurrentLocation - FVector(0.f, 0.f, 1000.f);
		FHazeHitResult Hit;
		TraceParams.Trace(Hit);
		if(Owner.CanStandOn(Hit.FHitResult))
		{
			Owner.SetActorLocation(Hit.ImpactPoint + (FVector::UpVector * 2));
		}	
		else if(Owner.bLockToArea)
		{
			Owner.bInvalidSpawn = true;
		}
			
		if(SpawnEffect != nullptr)
			Niagara::SpawnSystemAtLocation(SpawnEffect, Owner.GetActorLocation(), Owner.GetActorRotation());

		bWaitingForAnimation = true;
		System::SetTimer(this, n"OnAnimationFinished", SpawnDelayUntilMovement, false);	
	}

	void OnSpawnedComplete() override
	{
		auto GroundComp = USickleEnemyGroundComponent::Get(Owner);
		if(GroundComp != nullptr)
			GroundComp.LastValidPosition = Owner.GetActorLocation();
	}

	bool IsComplete() const override
	{
		if(bWaitingForAnimation)
			return false;
		if(Owner.MeshOffsetComponent.IsActive())
			return false;
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnimationFinished()
	{
		bWaitingForAnimation = false;
	}
}