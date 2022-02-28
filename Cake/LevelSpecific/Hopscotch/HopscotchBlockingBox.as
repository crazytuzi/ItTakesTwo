class AHopscotchBlockingBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BoxMesh;

	UPROPERTY()
	FHazeTimeLike MoveBoxTimeline;
	default MoveBoxTimeline.Duration = 0.5f;

	FVector StartingLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, -1000.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBoxTimeline.BindUpdate(this, n"MoveBoxTimelineUpdate");
	}

	UFUNCTION()
	void MoveBoxTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartingLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void StartMovingBox()
	{
		MoveBoxTimeline.PlayFromStart();
	}
}