class ARailCartBomb : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collsion;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ExplosionFX;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ExplosionAudioEvent;

	bool bHasExploded;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (!bHasExploded)
		{
			Explode();	
		}
    }

	void Explode()
	{
		ExplosionFX.Activate(true);
		HazeAkComp.SetStopWhenOwnerDestroyed(false);
		HazeAkComp.HazePostEvent(ExplosionAudioEvent);
		System::SetTimer(this, n"HideMesh", 0.75, false);
	}

	void HideMesh()
	{
		Mesh.SetHiddenInGame(true);
	}
}