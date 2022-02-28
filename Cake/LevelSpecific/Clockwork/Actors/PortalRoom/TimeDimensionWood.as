class ATimeDimensionWood : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	FVector StartingScale;

	UPROPERTY()
	FHazeTimeLike ScaleMeshTimeline;
	default ScaleMeshTimeline.Duration = 0.3f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleMeshTimeline.BindUpdate(this, n"ScaleMeshTimelineUpdate");

		StartingScale = Mesh.GetWorldScale();
	}

	UFUNCTION()
	void ScaleWood()
	{
		ScaleMeshTimeline.PlayFromStart();
	}

	UFUNCTION()
	void ScaleMeshTimelineUpdate(float CurrentValue)
	{
		Mesh.SetWorldScale3D(FMath::Lerp(StartingScale, FVector::ZeroVector, CurrentValue));
	}
}