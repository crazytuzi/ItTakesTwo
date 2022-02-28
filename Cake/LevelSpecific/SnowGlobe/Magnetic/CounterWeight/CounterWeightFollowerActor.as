import Cake.LevelSpecific.SnowGlobe.Magnetic.CounterWeight.CounterWeightActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;
import Peanuts.Spline.SplineComponent;


class ACounterWeightFollower : AHazeActor
{
	UPROPERTY()
	ACounterWeightActor ActorToFollow;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	AMagneticWheelActor WheelToFollow; 

	bool bIsAtEnd;
	float Progress = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline.DetachFromParent(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetProgress();
	}

	UFUNCTION()
	void SetProgress()
	{
		if(ActorToFollow != nullptr)
			Progress = ActorToFollow.Progress;
		else if(WheelToFollow != nullptr)
			Progress = WheelToFollow.Progress;
		else
			return;

		float DistanceAlongSpline = Spline.GetSplineLength() * Progress;
		FVector LocationAlongSpline = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		Mesh.SetWorldLocation(LocationAlongSpline);

	}
}