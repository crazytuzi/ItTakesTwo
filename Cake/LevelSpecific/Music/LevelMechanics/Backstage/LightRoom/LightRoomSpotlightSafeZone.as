import Vino.Checkpoints.Checkpoint;
class ALightRoomSpotlightSafeZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent FakeLight;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent Spotlight;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Sphere;

	UPROPERTY()
	ACheckpoint ConnectedCheckpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sphere.OnComponentBeginOverlap.AddUFunction(this, n"SphereOverlap");
	}

	UFUNCTION()
	void SphereOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			ConnectedCheckpoint.EnableForPlayer(Player);
		}
			
	}

	bool IsProvidingLightToPlayer(AHazePlayerCharacter Player)
	{
		return Sphere.IsOverlappingActor(Player);
	}
}