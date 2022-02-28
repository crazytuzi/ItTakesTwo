class AFakeMarbleBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX;
}