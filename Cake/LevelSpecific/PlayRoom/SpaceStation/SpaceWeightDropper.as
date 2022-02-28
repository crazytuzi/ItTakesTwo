UCLASS(Abstract)
class ASpaceWeightDropper : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DropperMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Weight;

	bool bWeightDropperOpen = false;

	FVector StartLoc;

	UPROPERTY()
	bool bPreviewEndLocation = false;

	UPROPERTY()
	FVector EndLocation;

	UPROPERTY()
	FHazeTimeLike DropWeightTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = Weight.RelativeLocation;

		DropWeightTimeLike.BindUpdate(this, n"UpdateDropWeight");
		DropWeightTimeLike.BindFinished(this, n"FinishDropWeight");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndLocation)
		{
			Weight.SetRelativeLocation(EndLocation);
		}
		else
		{
			Weight.SetRelativeLocation(FVector(0.f, 0.f, -120.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWeightDropperOpen)
		{
			Weight.AddRelativeLocation(FVector(0.f, 0.f, -4000.f * DeltaTime));
		}
	}

	UFUNCTION()
	void UpdateDropWeight(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLoc, EndLocation, CurValue);
		Weight.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishDropWeight()
	{
		System::SetTimer(this, n"DropWeight", 2.f, false);
	}

	UFUNCTION()
	void DropWeight()
	{
		DropWeightTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void OpenWeightDropper()
	{
		// bWeightDropperOpen = true;
		DropWeight();
	}

	void ResetWeight()
	{
		bWeightDropperOpen = false;
		Weight.SetRelativeLocation(FVector::ZeroVector);
		System::SetTimer(this, n"DropWeight", 2.f, false);
	}
}