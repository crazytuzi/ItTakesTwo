
class AKeyBirdKey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshComponent;
	default MeshComponent.SetCollisionProfileName(n"NoCollision");
	default MeshComponent.RelativeLocation = FVector(0.0f, 0.0f, 300.0f);
	default MeshComponent.bAbsoluteRotation = true;

	float YawRotation = 0.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetLifeSpan(6.0f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		YawRotation += 150.0f * DeltaTime;
		FHitResult Hit;
		SetActorRelativeRotation(FRotator(0.0f, YawRotation, 0.0f), false, Hit, true);
	}
}
