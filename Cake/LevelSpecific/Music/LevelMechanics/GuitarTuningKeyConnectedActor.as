class AGuitarTuningKeyConnectedActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;

	float CurrentProgress = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = StartLocation + EndLocation;
	}

	void UpdateProgress(float NewProgress)
	{
		CurrentProgress = NewProgress;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurrentProgress);
		SetActorLocation(CurLoc);
	}
}