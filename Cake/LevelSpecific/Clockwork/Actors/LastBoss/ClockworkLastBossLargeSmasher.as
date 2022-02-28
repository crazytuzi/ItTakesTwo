import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
class AClockworkLastBossLargeSmasher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SmasherMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent BoxCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SmasherMesh.AddLocalRotation(FRotator(0.f, 0.f, 200.f * DeltaTime));
	}

	UFUNCTION()
	void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		// AClockworkLastBossMovingObject Object = Cast<AClockworkLastBossMovingObject>(OtherActor);

		// if (Object != nullptr)
		// {
		// 	Object.DestroyMovingObject();
		// }
	}
}