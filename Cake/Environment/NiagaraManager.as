
class ANiagaraManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	TArray<AHazeNiagaraActor> NiagaraActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION()
	void ActivateNiagaraEffect()
	{	
		for(AHazeNiagaraActor Actor : NiagaraActors)
		{
			Actor.NiagaraComponent.Activate();
		}
	}

	UFUNCTION()
	void DeactivateNiagaraEffect()
	{	
		for(AHazeNiagaraActor Actor : NiagaraActors)
		{
			Actor.NiagaraComponent.Deactivate();
		}
	}
}

