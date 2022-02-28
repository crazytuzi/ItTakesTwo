import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantHammer;

class ABossRoomBlockingWall : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent BoxCollider;	

	UPROPERTY()
	UNiagaraSystem NiagaraFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");		
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(Cast<ABossControllablePlantHammer>(OtherActor) != nullptr)
		{
			Explode();
		}
	}

	UFUNCTION()
	void Explode()
	{
		Niagara::SpawnSystemAtLocation(NiagaraFX, GetActorLocation());
		DestroyActor();
	}
}
