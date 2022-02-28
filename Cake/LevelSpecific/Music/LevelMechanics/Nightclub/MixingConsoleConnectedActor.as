class AMixingConsoleConnectedActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation = FVector(0.f, 0.f, 1000.f);

	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		TargetLocation = StartLocation;
	}

	void UpdateTargetLocation(bool bGoToEnd)
	{
		if (bGoToEnd)
			TargetLocation = StartLocation + EndLocation;
		else
			TargetLocation = StartLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector CurLoc = FMath::VInterpTo(ActorLocation, TargetLocation, DeltaTime, 1.f);
		SetActorLocation(CurLoc);
	}
}