class ACastleBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent BrazierMesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagraFire;

	UFUNCTION()
	void IgniteBrazier()
	{
		NiagraFire.Activate();
	}
}