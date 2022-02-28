import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

UCLASS(Abstract)
class USickleEnemyEmergeFromParentEffect : USickleEnemySpawningEffect
{
	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	UPROPERTY()
	FHazePlaySlotAnimationParams SpawnAnimation;

	UPROPERTY()
	FRuntimeFloatCurve ScaleWidthCurve; 

	UPROPERTY()
	FRuntimeFloatCurve ScaleHeightCurve; 

	// Internal
	private bool bWaitingForAnimation = false;
	private float CurrentActiveTime = 0;

	private FVector OriginalScale;

	void OnSpawned() override
	{
		if(SpawnEffect != nullptr)
			Niagara::SpawnSystemAtLocation(SpawnEffect, Owner.GetActorLocation(), Owner.GetActorRotation());

		float EmergeTime = 0.5f;
		if(SpawnAnimation.Animation != nullptr)
		{
			EmergeTime = SpawnAnimation.GetPlayLength() * 0.8f;
			bWaitingForAnimation = true;
			FHazeAnimationDelegate BlendOut;
			BlendOut.BindUFunction(this, n"OnAnimationFinished");
			Owner.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOut, SpawnAnimation);
		}

		OriginalScale = Owner.GetActorScale3D();
		Owner.SetActorScale3D(FVector(KINDA_SMALL_NUMBER));		
	}

	void Tick(float DeltaTime) override
	{
		CurrentActiveTime += DeltaTime;
		
		const float WidthScale = ScaleWidthCurve.GetFloatValue(CurrentActiveTime, OriginalScale.Size2D());
		const float HeightScale = ScaleHeightCurve.GetFloatValue(CurrentActiveTime, OriginalScale.Z);
		const FVector NewScale = FVector(WidthScale, WidthScale, HeightScale);
		Owner.SetActorScale3D(NewScale);
	}

	bool IsComplete() const override
	{
		if(bWaitingForAnimation)
			return false;

		float WidthTimeMin = 0, WidthTimeMax = 0;
		ScaleWidthCurve.GetTimeRange(WidthTimeMin, WidthTimeMax);
		if(CurrentActiveTime < WidthTimeMax)
			return false;

		float HeightTimeMin = 0, HeightTimeMax = 0;
		ScaleHeightCurve.GetTimeRange(WidthTimeMin, WidthTimeMax);
		if(CurrentActiveTime < HeightTimeMax)
			return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnimationFinished()
	{
		bWaitingForAnimation = false;
	}
}