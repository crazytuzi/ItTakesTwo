class ATimeDimensionBuilding : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike ScaleBuildingTimeline;
	default ScaleBuildingTimeline.Duration = 0.3f;

	FVector TargetScale;

	UPROPERTY()
	bool bShouldScaleDownOnBeginPlay = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetScale = Mesh.GetWorldScale();
		ScaleBuildingTimeline.BindUpdate(this, n"ScaleBuildingTimelineUpdate");

		if (bShouldScaleDownOnBeginPlay)
			ScaleDownBuilding();
	}

	void ScaleUpBuilding()
	{
		ScaleBuildingTimeline.PlayFromStart();
	}

	void ScaleDownBuilding()
	{
		ScaleBuildingTimeline.ReverseFromEnd();
	}

	UFUNCTION()
	void ScaleBuildingTimelineUpdate(float CurrentValue)
	{
		Mesh.SetWorldScale3D(FMath::Lerp(FVector::ZeroVector, TargetScale, CurrentValue));
	}
}