import Peanuts.Spline.SplineComponent;

class AConnectedSplineFollower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	default Billboard.bHiddenInGame = false;

	FHazeSplineSystemPosition Position;

	UPROPERTY()
	AActor StartOnSpline;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = UHazeSplineComponent::Get(StartOnSpline);
		Position = Spline.GetPositionAtStart(bForward = true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Position.Move(DeltaTime * 500.f);
		if (Position.IsOnValidSpline())
			SetActorLocation(Position.WorldLocation);
	}
}