class AXylophoneBar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike MoveBarTimeline;
	default MoveBarTimeline.Duration = 6.f;

	UPROPERTY()
	bool bShowTargetRotation = false;

	FRotator StartingRotation = FRotator::ZeroRotator;
	FRotator TargetRotation = FRotator(-90.f, 0.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBarTimeline.BindUpdate(this, n"MoveBarTimelineUpdate");
		MeshRoot.SetRelativeRotation(StartingRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshRoot.SetRelativeRotation(bShowTargetRotation ? TargetRotation : StartingRotation);
	}

	UFUNCTION()
	void MoveBarTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRotation, TargetRotation, CurrentValue));
	}

	void ActivateXylophoneBar()
	{
		MoveBarTimeline.PlayFromStart();
	}
}