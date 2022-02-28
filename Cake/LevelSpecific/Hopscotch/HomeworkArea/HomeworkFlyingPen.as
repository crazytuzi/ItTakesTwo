class AHomeworkFlyingPen : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent AudioCollider;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnPenHit;

	void StartPenPhysics(FVector NewLocation)
	{
		SetActorHiddenInGame(false);
		SetActorLocation(NewLocation);
		Mesh.SetCollisionProfileName(n"PhysicsActor");
		Mesh.SetSimulatePhysics(true);

		AudioCollider.SetCollisionProfileName(n"IgnorePlayerCharacter");
		AudioCollider.OnComponentHit.AddUFunction(this, n"AudioOnHit");
	}

	UFUNCTION()
	void AudioOnHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, FHitResult& InHit)
	{
		if(NormalImpulse.Size() < 5000)
			return;

		UHazeAkComponent::HazePostEventFireForget(OnPenHit, GetActorTransform());
	}
}