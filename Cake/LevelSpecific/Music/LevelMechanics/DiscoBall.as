UCLASS(Abstract)
class ADiscoBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RopeBase;

	UPROPERTY(DefaultComponent, Attach = RopeBase)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = RopeBase)
	UStaticMeshComponent Ballmesh;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AddActorLocalRotation(FRotator(0.f, 50.f * DeltaTime, 0.f));
	}
}