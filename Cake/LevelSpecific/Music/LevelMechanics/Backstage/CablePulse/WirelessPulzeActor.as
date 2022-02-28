
event void FOnWirelessPulseReachedEnd();
class AWirelessPulseActor : AHazeActor
{
	UPROPERTY()
	AHazeActor StartActor;

	UPROPERTY()
	AHazeActor EndActor;

	UPROPERTY()
	float TravelTime;

	UPROPERTY()
	FOnWirelessPulseReachedEnd OnReachedEnd;

	UPROPERTY()
	FRuntimeFloatCurve Curve;

	bool bIsMoving;
	float Alpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsMoving)
		{
			Alpha += DeltaTime / TravelTime;
			ActorLocation = FMath::Lerp(StartActor.ActorLocation, EndActor.ActorLocation, Curve.GetFloatValue(Alpha));

			if (Alpha > 1)
			{
				OnReachedtarget();
			}
		}
	}

	UFUNCTION()
	void StartMovingToTarget()
	{
		Alpha = 0;
		bIsMoving = true;
		SetActorHiddenInGame(false);
	}

	void OnReachedtarget()
	{
		SetActorHiddenInGame(true);
		bIsMoving = false;
		OnReachedEnd.Broadcast();
	}
}