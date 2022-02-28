import Vino.PlayerHealth.PlayerHealthStatics;
class InflatableSpinningObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UCapsuleComponent KillCollision;

	UPROPERTY()
	float RotationSpeed = 100.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"KillCollisionOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.AddLocalRotation(FRotator(0.f, RotationSpeed * DeltaTime, 0.f));
	}
	
	UFUNCTION()
	void KillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		// AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		// if (Player == nullptr)
		// 	return;

		// if (!Player.HasControl())
		// 	return;

		// KillPlayer(Player);
	}
}