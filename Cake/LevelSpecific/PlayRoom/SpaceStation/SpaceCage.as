UCLASS(Abstract)
class ASpaceCage : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CageMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent LifterMesh;

	bool bElectricityConnected = false;
	FVector BottomLocation;
	FVector TopLocation = FVector(0.f, 0.f, 820.f);
	FVector CurrentLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BottomLocation = CageMesh.RelativeLocation;
		CurrentLocation = CageMesh.RelativeLocation;
		TargetLocation = CurrentLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bElectricityConnected)
		{
			TargetLocation = TopLocation;
		}
		else
		{
			TargetLocation = BottomLocation;
		}

		CurrentLocation = FMath::VInterpTo(CurrentLocation, TargetLocation, DeltaTime, 2.f);
		CageMesh.SetRelativeLocation(CurrentLocation);
	}

	UFUNCTION()
	void ConnectElectricity()
	{
		bElectricityConnected = true;
	}

	UFUNCTION()
	void DisconnectElectricty()
	{
		bElectricityConnected = false;
	}
}