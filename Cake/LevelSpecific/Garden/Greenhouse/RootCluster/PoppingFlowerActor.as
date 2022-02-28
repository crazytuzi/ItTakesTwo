event void FOnPoppingFlowerPop();

class APoppingFlowerActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UStaticMeshComponent FlowerMesh;

	UPROPERTY()
	FHazeTimeLike ScalingTimeLike;

	UPROPERTY()
	FOnPoppingFlowerPop OnPoppingFlowerPop;

	// UPROPERTY(DefaultComponent, Attach = ShieldMesh)
	// UGardenUnwitherComponent UnwitherComp;

	UPROPERTY()
	UNiagaraSystem PopEffect;

	float FinalScale = 1.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScalingTimeLike.BindUpdate(this, n"UpdateTimeLike");
		FlowerMesh.SetHiddenInGame(true, false);
		FlowerMesh.SetRelativeScale3D(FVector::ZeroVector);

		if(FlowerMesh.WorldScale.Z != 1.0f)
			FinalScale = FlowerMesh.WorldScale.Z; 
	}

	UFUNCTION()
	void PopUp()
	{
		FlowerMesh.SetHiddenInGame(false, false);
		
		if(PopEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PopEffect, ActorLocation);
		
		OnPoppingFlowerPop.Broadcast();
		ScalingTimeLike.Play();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		float NewScale = FMath::Lerp(0.0f, FinalScale, ScalingTimeLike.Value);
		FlowerMesh.SetRelativeScale3D(FVector(NewScale, NewScale, NewScale));
	}
}
