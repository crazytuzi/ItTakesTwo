class AClockworkGlassBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent CableMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent WindupKeyMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent MoveDirectionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}