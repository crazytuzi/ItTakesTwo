class AMoonDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DestroyEffectOrigin;

	UPROPERTY()
	UNiagaraSystem DestroyEffect;

	bool bDestroyed = false;

	void DestroyObject()
	{
		if (bDestroyed)
			return;
			
		bDestroyed = true;
		Niagara::SpawnSystemAtLocation(DestroyEffect, DestroyEffectOrigin.WorldLocation, DestroyEffectOrigin.WorldRotation);
		DisableActor(this);
	}
}