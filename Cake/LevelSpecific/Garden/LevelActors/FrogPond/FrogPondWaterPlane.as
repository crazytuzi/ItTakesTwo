UCLASS(Abstract)
class AFrogPondWaterPlane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent TopWaterMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BottomWaterMesh;

	float CurrentWaterLevel = 0.f;

	UPROPERTY()
	bool bPreviewEndLocation = false;

	UPROPERTY()
	float EndHeight = 3500.f;
	float WaterPerPump = 1200.f;
	float CurrentHeight = 0.f;
	float TargetHeight = 0.f;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndLocation)
		{
			TopWaterMesh.SetRelativeLocation(FVector(0.f, 0.f, EndHeight));
			BottomWaterMesh.SetRelativeLocation(FVector(0.f, 0.f, EndHeight));
		}
		else
		{
			TopWaterMesh.SetRelativeLocation(FVector::ZeroVector);
			BottomWaterMesh.SetRelativeLocation(FVector::ZeroVector);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentHeight = FMath::FInterpTo(CurrentHeight, TargetHeight, DeltaTime, 2.f);
		CurrentHeight = FMath::Clamp(CurrentHeight, 0.f, EndHeight);
		SetActorLocation(StartLocation + FVector(0.f, 0.f, CurrentHeight));
	}

	void Pumped()
	{
		TargetHeight += WaterPerPump;
	}
}