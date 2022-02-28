UCLASS(Abstract)
class AControllableLaser : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UStaticMeshComponent LaserMesh;

	float InterpSpeed = 3.f;

	FVector TargetLocation;

	void UpdateLaserTargetLocation(FVector ImpactLocation)
	{
		TargetLocation = ImpactLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		LaserMesh.SetWorldScale3D(FVector(0.25f, 0.25f, TargetLocation.Distance(ActorLocation)/100.f));
		LaserRoot.SetRelativeLocation(FVector(TargetLocation.Distance(ActorLocation), 0.f, 0.f)/2);
	}
}