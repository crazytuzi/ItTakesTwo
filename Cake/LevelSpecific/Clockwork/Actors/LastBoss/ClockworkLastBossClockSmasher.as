import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
class AClockworkLastBossClockSmasher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

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

	}

	UFUNCTION()
	void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AClockworkLastBossMovingObject Object = Cast<AClockworkLastBossMovingObject>(OtherActor);

		if (Object != nullptr)
		{
			Object.DestroyMovingObject();
		}
	}
}