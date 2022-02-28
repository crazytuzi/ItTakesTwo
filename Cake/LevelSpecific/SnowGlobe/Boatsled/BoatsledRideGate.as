class ABoatsledRideGate : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftGate;
	default LeftGate.SetRelativeLocation(FVector(0.f, 260.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightGate;
	default RightGate.SetRelativeLocation(FVector(0.f, -260.f, 0.f));

	UPROPERTY()
	FHazeTimeLike GateTimeLike;

	UPROPERTY()
	const float YawAngleGoal = 300.f;
	float YawAngleGoalRad;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GateTimeLike.BindUpdate(this, n"TickGate");
		GateTimeLike.BindFinished(this, n"Finish");

		YawAngleGoalRad = FMath::DegreesToRadians(YawAngleGoal);

		LeftGate.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		RightGate.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	void Open()
	{
		GateTimeLike.PlayFromStart();

		LeftGate.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		RightGate.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(NotBlueprintCallable)
	void TickGate(float Value)
	{
		LeftGate.SetRelativeRotation(FQuat::FastLerp(FQuat::Identity, FQuat(FVector::UpVector, -YawAngleGoalRad), Value));
		RightGate.SetRelativeRotation(FQuat::FastLerp(FQuat::Identity, FQuat(FVector::UpVector, YawAngleGoalRad), Value));
	}

	UFUNCTION(NotBlueprintCallable)
	void Finish()
	{

	}
}