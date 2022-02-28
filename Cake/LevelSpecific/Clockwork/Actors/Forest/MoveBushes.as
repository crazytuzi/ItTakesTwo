class AMoveBushes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	FHazeTimeLike MoveBushesTimeline;
	default MoveBushesTimeline.Duration = 2.f;

	UPROPERTY()
	TArray<AStaticMeshActor> BushArray;

	UPROPERTY(Meta = (MakeEditWidget = true))
	TArray<FVector> BushTargetLocationArray;

	TArray<FVector> StartingLocationArray;

	bool bHasPlayerTimeline = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBushesTimeline.BindUpdate(this, n"MoveBushesTimelineUpdate");	

		for (AStaticMeshActor Bush : BushArray)
		{
			StartingLocationArray.Add(Bush.GetActorLocation());
		}	
	}

	UFUNCTION()
	void StartMovingBushes()
	{
		if (bHasPlayerTimeline)
			return;

		bHasPlayerTimeline = true;
		MoveBushesTimeline.PlayFromStart();
	}

	UFUNCTION()
	void MoveBushesTimelineUpdate(float CurrentValue)
	{
		for (int i = 0; i < BushArray.Num(); i++)
		{
			BushArray[i].SetActorLocation(FMath::VLerp(StartingLocationArray[i], GetActorTransform().TransformPosition(BushTargetLocationArray[i]), FVector(CurrentValue, CurrentValue, CurrentValue)));
		}

		Print("CurrentValue: " + CurrentValue);
	}
}