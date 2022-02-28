class AWindupCassetteRotatingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	float RotatingSpeed = 40.f;
	
	bool bShouldRotate = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldRotate)
			return;

		MeshRoot.AddLocalRotation(FRotator(0.f, RotatingSpeed * DeltaTime, 0.f));

	}

	UFUNCTION()
	void StartRotatingActor(bool bNewShouldRotate)
	{
		bShouldRotate = bNewShouldRotate;
	}
}