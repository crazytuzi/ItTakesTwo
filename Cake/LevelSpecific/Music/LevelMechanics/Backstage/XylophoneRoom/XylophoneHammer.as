class AXylophoneHammer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike MoveHammerTimeline;
	default MoveHammerTimeline.Duration = 1.5f;

	FRotator StartingRotation = FRotator::ZeroRotator;
	FRotator TargetRotation = FRotator(-85.f, 0.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveHammerTimeline.BindUpdate(this, n"MoveHammerTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void MoveHammerTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRotation, TargetRotation, CurrentValue));
	}

	void ActivateXylophoneHammer()
	{
		MoveHammerTimeline.PlayFromStart();
	}		
}