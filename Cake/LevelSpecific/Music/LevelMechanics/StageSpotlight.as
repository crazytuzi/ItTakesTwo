UCLASS(Abstract)
class AStageSpotlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpotlightRoot;

	UPROPERTY(DefaultComponent, Attach = SpotlightRoot)
	UStaticMeshComponent SpotlightBaseMesh;

	UPROPERTY(DefaultComponent, Attach = SpotlightRoot)
	UStaticMeshComponent SpotlightMesh;

	UPROPERTY(DefaultComponent, Attach = SpotlightMesh)
	USpotLightComponent Spotlight;

	UPROPERTY()
    float XYRange = 7000.f;

	UPROPERTY()
    float Speed = 300.f;

	FVector OriginalPosition;
    FVector TargetPosition;

	bool bMoving = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        OriginalPosition = ActorLocation;
        TargetPosition = OriginalPosition;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;

        ActorLocation = FMath::VInterpConstantTo(ActorLocation, TargetPosition, DeltaTime, Speed);
        if (ActorLocation.Distance(TargetPosition) < 1.f)
        {
            FVector RandomPos = FMath::VRand();
            RandomPos.X *= XYRange;
            RandomPos.Y *= XYRange;
            RandomPos.Z = 0.f;

            TargetPosition = OriginalPosition + RandomPos;
        }
	}

	UFUNCTION()
	void StartMoving()
	{
		bMoving = true;
	}
}