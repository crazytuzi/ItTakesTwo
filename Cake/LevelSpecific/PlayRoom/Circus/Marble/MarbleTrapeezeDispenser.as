import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeMarbleActor;
import Peanuts.Spline.SplineComponent;

class AMarbleTrapeezeDispenser : AHazeActor
{
	UPROPERTY()
	ATrapezeMarbleActor TrapeezeMarble;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;

	UPROPERTY()
	UCurveFloat SpeedCurve;

	float CurveProgress;

	bool bMarbleOnFloor = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void ActivateMarble()
	{
		SetActorTickEnabled(true);
		CurveProgress = 0;

		TrapeezeMarble.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurvePercent = CurveProgress / Spline.SplineLength;
		CurveProgress += DeltaTime * SpeedCurve.GetFloatValue(CurvePercent);

		if (CurveProgress > Spline.SplineLength)
		{
			AnimationReachedEnd();
		}
		else
		{
			TrapeezeMarble.SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(CurveProgress, ESplineCoordinateSpace::World));
		}

	}

	void AnimationReachedEnd()
	{
		TrapeezeMarble.SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(Spline.SplineLength, ESplineCoordinateSpace::World));
		TrapeezeMarble.SetReadyForPickup();
		SetActorTickEnabled(false);
	}
}