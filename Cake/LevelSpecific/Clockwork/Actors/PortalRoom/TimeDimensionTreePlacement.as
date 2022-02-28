class ATimeDimensionTreePlacement : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision; 

	bool bTreePlaced = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"SphereBeginOverlap");
		SphereCollision.OnComponentEndOverlap.AddUFunction(this, n"SphereEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bTreePlaced)
			return;	
			
	}

	UFUNCTION()
	void SphereBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		// ATimeDimensionTree Tree = Cast<ATimeDimensionTree>(OtherActor);

		// if (Tree != nullptr)
		// {
		// 	Tree.PickupableComponent.bPlayerIsAllowedToPutDown = true;
		// }
	}

	UFUNCTION()
	void SphereEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		// ATimeDimensionTree Tree = Cast<ATimeDimensionTree>(OtherActor);

		// if (Tree != nullptr)
		// {
		// 	Tree.PickupableComponent.bPlayerIsAllowedToPutDown = false;
		// }
	}
}