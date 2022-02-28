UCLASS(Abstract)
class AVacuumWallFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FanRoot;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	UStaticMeshComponent FanMesh;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	UStaticMeshComponent Platform01;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	UStaticMeshComponent Platform02;

	UPROPERTY(DefaultComponent, Attach = FanRoot)
	UStaticMeshComponent Platform03;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovementComp;
	default RotatingMovementComp.RotationRate = FRotator(0.f, 0.f, 55.f);

	FRotator PlatformRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformRotation = Platform01.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Platform01.SetWorldRotation(PlatformRotation);
		Platform02.SetWorldRotation(PlatformRotation);
		Platform03.SetWorldRotation(PlatformRotation);
	}
}