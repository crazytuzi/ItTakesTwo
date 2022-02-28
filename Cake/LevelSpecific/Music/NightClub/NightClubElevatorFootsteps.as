

class ANightClubElevatorFootsteps : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// pool of staticmeshes
	UPROPERTY()
	TArray<UStaticMeshComponent> Footsteps;

	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	int MaxFootsteps = 32;

	int Counter = 0;
	
	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		for (int i = 0; i < MaxFootsteps; i++)
		{
			UStaticMeshComponent NewMesh = Cast<UStaticMeshComponent>(this.CreateComponent(UStaticMeshComponent::StaticClass())); 
			NewMesh.SetStaticMesh(Mesh);
			Footsteps.Add(NewMesh);
			NewMesh.SetCollisionProfileName(n"NoCollision");
			NewMesh.SetWorldScale3D(FVector(0.5f, 0.5f, 1.f));
		}
	}

	UFUNCTION()
	void SpawnFootstep(FVector ActorPosition, FVector Location, FRotator Rotation)
	{
		Footsteps[Counter].SetScalarParameterValueOnMaterials(n"SpawnTime", Time::GetGameTimeSeconds());
		Footsteps[Counter].SetWorldLocation(FVector(Location.X, Location.Y, ActorPosition.Z));
		Footsteps[Counter].SetWorldRotation(FRotator(0, Rotation.Yaw, 0));

		// Loop
		Counter++;
		Counter %= MaxFootsteps;
	}
}