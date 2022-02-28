import Cake.LevelSpecific.Hopscotch.TiltingPlatform;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Hopscotch.MarbleMazeBridge;
class AMarableMazeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	AActor FakeBall;

	UPROPERTY()
	FHazeTimeLike MoveBridgeTimeline;
	default MoveBridgeTimeline.Duration = 2.f;

	UPROPERTY()
	FHazeTimeLike MoveBallOnRailTimeline;
	default MoveBallOnRailTimeline.Duration = 3.f;

	UHazeSplineComponent SplineComponent;

	FRotator BridgeInitialRotation;
	FRotator BridgeTargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBallOnRailTimeline.BindUpdate(this, n"MoveBallOnRailTimelineUpdate");
		MoveBallOnRailTimeline.BindFinished(this, n"MoveBallOnRailTimelineFinished");
		MoveBridgeTimeline.BindUpdate(this, n"MoveBridgeTimelineUpdate");
	}

	UFUNCTION()
	void MoveBallOnRailTimelineUpdate(float CurrentValue)
	{
		FVector NewLocation;
		NewLocation = SplineComponent.GetLocationAtDistanceAlongSpline(SplineComponent.GetSplineLength() * CurrentValue, ESplineCoordinateSpace::World) + FVector(0.f, 0.f, 50.f);
		FakeBall.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void MoveBallOnRailTimelineFinished(float CurrentValue)
	{
		MoveBridgeTimeline.Play();
	}

	UFUNCTION()
	void GoalReached()
	{
		FakeBall.SetActorHiddenInGame(false);
		MoveBallOnRailTimeline.Play();
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}