class AClockworkLastBossFreeFallElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BarMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MidCube;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopLeftMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TopLeftMeshRoot)
	UStaticMeshComponent TopLeftMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopMidMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TopMidMeshRoot)
	UStaticMeshComponent TopMidMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopRightMeshRoot;

	UPROPERTY(DefaultComponent, Attach = TopRightMeshRoot)
	UStaticMeshComponent TopRightMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MidLeftMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MidLeftMeshRoot)	
	UStaticMeshComponent MidLeftMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MidRightMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MidRightMeshRoot)
	UStaticMeshComponent MidRightMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LowerLeftMeshRoot;

	UPROPERTY(DefaultComponent, Attach = LowerLeftMeshRoot)
	UStaticMeshComponent LowerLeftMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LowerMidMeshRoot;

	UPROPERTY(DefaultComponent, Attach = LowerMidMeshRoot)
	UStaticMeshComponent LowerMidMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LowerRightMeshRoot;

	UPROPERTY(DefaultComponent, Attach = LowerRightMeshRoot)
	UStaticMeshComponent LowerRightMesh;

	FHazeTimeLike FoldPlatformTimeline;
	default FoldPlatformTimeline.Duration = 2.f;

	float RotationAmount = 90.f;

	FVector StartingLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FoldPlatformTimeline.BindUpdate(this, n"FoldPlatformTimelineUpdate");

		StartingLocation = GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void FoldPlatformTimelineUpdate(float CurrentValue)
	{
		TopLeftMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(RotationAmount, 0.f, -RotationAmount), CurrentValue));
		TopMidMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(0.f, 0.f, -RotationAmount), CurrentValue));
		TopRightMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(-RotationAmount, 0.f, -RotationAmount), CurrentValue));
		MidLeftMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(RotationAmount, 0.f, 0.f), CurrentValue));
		MidRightMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(-RotationAmount, 0.f, 0.f), CurrentValue));
		LowerLeftMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(RotationAmount, 0.f, RotationAmount), CurrentValue));
		LowerMidMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(0.f, 0.f, RotationAmount), CurrentValue));
		LowerRightMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(-RotationAmount, 0.f, RotationAmount), CurrentValue));
	}

	UFUNCTION()
	void StartFoldingPlatform()
	{
		FoldPlatformTimeline.PlayFromStart();
	}

	UFUNCTION()
	void InstantFoldElevator()
	{
		TopLeftMeshRoot.SetRelativeRotation(FRotator(RotationAmount, 0.f, -RotationAmount));
		TopMidMeshRoot.SetRelativeRotation(FRotator(0.f, 0.f, -RotationAmount));
		TopRightMeshRoot.SetRelativeRotation(FRotator(-RotationAmount, 0.f, -RotationAmount));
		MidLeftMeshRoot.SetRelativeRotation(FRotator(RotationAmount, 0.f, 0.f));
		MidRightMeshRoot.SetRelativeRotation(FRotator(-RotationAmount, 0.f, 0.f));
		LowerLeftMeshRoot.SetRelativeRotation(FRotator(RotationAmount, 0.f, RotationAmount));
		LowerMidMeshRoot.SetRelativeRotation(FRotator(0.f, 0.f, RotationAmount));
		LowerRightMeshRoot.SetRelativeRotation(FRotator(-RotationAmount, 0.f, RotationAmount));
	}

	UFUNCTION()
	void SetElevatorToFinalLocation()
	{
		SetActorLocation(StartingLocation + FVector(-40.f, 0.f, 8550.f));
		SetActorHiddenInGame(false);
	}
}