
class AClassicFallingSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY()
	float MoveDistanceZ = -1000;
	UPROPERTY()
	float Stiffness = 10;
	UPROPERTY()
	float Dampness = 0.6f;

	FVector StartLocation;
	FHazeAcceleratedFloat AcceleratedFloat;
	bool bHasBeenTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasBeenTriggered)
		{
			AcceleratedFloat.SpringTo(MoveDistanceZ, Stiffness, Dampness, DeltaSeconds);
			SetActorLocation(FVector(StartLocation.X, StartLocation.Y, AcceleratedFloat.Value + StartLocation.Z));
		}
	}

	UFUNCTION()
	void StartFalling()
	{
		bHasBeenTriggered = true;
	}
	UFUNCTION()
	void StopFallingDown()
	{
		bHasBeenTriggered = false;
	}

	UFUNCTION()
	void InstantlyCompelete()
	{
		SetActorLocation(FVector(StartLocation.X, StartLocation.Y, MoveDistanceZ + StartLocation.Z));
	}
}

