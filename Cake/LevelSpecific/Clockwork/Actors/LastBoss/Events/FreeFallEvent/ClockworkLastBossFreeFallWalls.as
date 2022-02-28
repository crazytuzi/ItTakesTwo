class AClockworkFreeFallWalls : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BarMesh01Root;

	UPROPERTY(DefaultComponent, Attach = BarMesh01Root)
	UStaticMeshComponent BarMesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BarMesh02Root;

	UPROPERTY(DefaultComponent, Attach = BarMesh02Root)
	UStaticMeshComponent BarMesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformMeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	FHazeTimeLike MovePlatformTimeline;
	default MovePlatformTimeline.Duration = 1.f;

	float WallSpeed;

	bool bActive = false;

	FVector Mesh01StartLoc = FVector::ZeroVector;
	FVector Mesh01TargetLoc = FVector::ZeroVector;
	FVector Mesh02StartLoc = FVector(1600.f, 0.f, 1100.f);
	FVector Mesh02TargetLoc = FVector(0.f, 0.f, 2000.f);
	FVector PlatformMeshStartLoc = FVector(0.f, 0.f, 2300.f);
	FVector PlatformMeshTargetLoc = FVector(0.f, 0.f, 4000.f);

	FRotator Mesh01StartRot = FRotator(-55.f, 0.f, 0.f);
	FRotator Mesh01TargetRot = FRotator::ZeroRotator;
	FRotator Mesh02StartRot = FRotator(55.f, 0.f, 0.f);
	FRotator Mesh02TargetRot = FRotator::ZeroRotator;
	FRotator PlatformMeshStartRot = FRotator(90.f, 0.f, 0.f);
	FRotator PlatformMeshTargetRot = FRotator::ZeroRotator;

	UFUNCTION(CallInEditor)
	void SetToStartLocation()
	{
		BarMesh01Root.SetRelativeLocation(Mesh01StartLoc);
		BarMesh02Root.SetRelativeLocation(Mesh02StartLoc);
		PlatformMeshRoot.SetRelativeLocation(PlatformMeshStartLoc);

		BarMesh01Root.SetRelativeRotation(Mesh01StartRot);
		BarMesh02Root.SetRelativeRotation(Mesh02StartRot);
		PlatformMeshRoot.SetRelativeRotation(PlatformMeshStartRot);
	}

	UFUNCTION(CallInEditor)
	void SetToTargetLocation()
	{
		BarMesh01Root.SetRelativeLocation(Mesh01TargetLoc);
		BarMesh02Root.SetRelativeLocation(Mesh02TargetLoc);
		PlatformMeshRoot.SetRelativeLocation(PlatformMeshTargetLoc);

		BarMesh01Root.SetRelativeRotation(Mesh01TargetRot);
		BarMesh02Root.SetRelativeRotation(Mesh02TargetRot);
		PlatformMeshRoot.SetRelativeRotation(PlatformMeshTargetRot);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformTimeline.BindUpdate(this, n"MovePlatformTimelineUpdate");
		SetToStartLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		AddActorWorldOffset(FVector(0.f, 0.f, WallSpeed * DeltaTime));
	}

	UFUNCTION()
	void StartMovingPlatform()
	{
		MovePlatformTimeline.PlayFromStart();
	}

	UFUNCTION()
	void SetWallsActive(bool bShouldPlayTimeline)
	{
		bActive = true;

		// if (bShouldPlayTimeline)
		// {
		// 	StartMovingPlatform();
		// } else
		// {
		// 	SetToTargetLocation();
		// }
	}

	UFUNCTION()
	void MovePlatformTimelineUpdate(float CurrentValue)
	{
		BarMesh01Root.SetRelativeLocation(FMath::Lerp(Mesh01StartLoc, Mesh01TargetLoc, CurrentValue));
		BarMesh02Root.SetRelativeLocation(FMath::Lerp(Mesh02StartLoc, Mesh02TargetLoc, CurrentValue));
		PlatformMeshRoot.SetRelativeLocation(FMath::Lerp(PlatformMeshStartLoc, PlatformMeshTargetLoc, CurrentValue));

		BarMesh01Root.SetRelativeRotation(FMath::LerpShortestPath(Mesh01StartRot, Mesh01TargetRot, CurrentValue));
		BarMesh02Root.SetRelativeRotation(FMath::LerpShortestPath(Mesh02StartRot, Mesh02TargetRot, CurrentValue));
		PlatformMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(PlatformMeshStartRot, PlatformMeshTargetRot, CurrentValue));
	}

	UFUNCTION()
	void SetSpeed(float NewSpeed)
	{
		WallSpeed = NewSpeed;
	}
}