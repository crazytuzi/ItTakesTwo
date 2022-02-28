enum ECardboardColors
{  
    Yellow,
    Green,
    Blue,
    Red
};

class AMovingCardboardBoxes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike MoveTimeline;
	default MoveTimeline.Duration = 0.3f;

	UPROPERTY()
	float MoveAmount;
	default MoveAmount = 200.f;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialArray;

	UPROPERTY()
	ECardboardColors CardboardColors;

	UPROPERTY()
	bool bIsMoved;
	
	FVector InitialLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetMaterial(0, MaterialArray[CardboardColors]);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTimeline.BindUpdate(this, n"MoveTimelineUpdate");
		MoveTimeline.BindFinished(this, n"MoveTimelineFinished");

		InitialLocation = Mesh.GetWorldLocation();
		TargetLocation = FVector(InitialLocation + FVector(Mesh.GetRightVector() * -MoveAmount));
	}

	UFUNCTION()
	void MoveTimelineUpdate(float CurrentValue)
	{
		Mesh.SetWorldLocation(FMath::VLerp(InitialLocation, TargetLocation, FVector(CurrentValue, CurrentValue, CurrentValue)));
	}

	UFUNCTION()
	void MoveTimelineFinished(float CurrentValue)
	{

	}

	UFUNCTION()
	void MoveBox()
	{
		if (!bIsMoved)
		{
			MoveTimeline.PlayFromStart();
			bIsMoved = true;
		}
	}

	UFUNCTION()
	void ReverseBox()
	{
		if (bIsMoved)
		{
			MoveTimeline.ReverseFromEnd();
			bIsMoved = false;
		}
	}
}