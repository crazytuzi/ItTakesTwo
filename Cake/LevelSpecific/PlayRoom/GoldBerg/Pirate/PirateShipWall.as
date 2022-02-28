class APirateShipWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Wall;

	FVector StartingLoc;

	FVector MoveTarget;

	float ZOffsetTarget = -1850.f;

	bool bCanMove;

	FHazeAcceleratedVector AccelVector;

	float Difference;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanMove)
		{
			AccelVector.AccelerateTo(MoveTarget, 2.f, DeltaTime);
			SetActorLocation(AccelVector.Value);

			Difference = (AccelVector.Value - MoveTarget).Size();
			Difference = FMath::Abs(Difference);

			if (Difference <= 2.f)
				bCanMove = false;
		}
	}

	UFUNCTION()
	void SetMovementTarget(bool bIsMovingDown)
	{
		bCanMove = true;
		AccelVector.SnapTo(ActorLocation);

		if (bIsMovingDown)
			MoveTarget = StartingLoc + FVector(0.f, 0.f, ZOffsetTarget);
		else
			MoveTarget = StartingLoc;
	}
}