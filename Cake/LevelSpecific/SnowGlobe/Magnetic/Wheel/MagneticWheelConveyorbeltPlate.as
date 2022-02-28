import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;

UCLASS(abstract)
class AMagneticWheelConveyorBeltPlate : AHazeActor
{
	UHazeSplineComponent Spline;
	
	UPROPERTY()
	float VelocityMultiplier = 1;

	UPROPERTY()
	AActor SplineActor;

	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	float DistanceAlongSpline;

	UPROPERTY()
	AMagneticWheelActor MagneticWheel;

	UFUNCTION(BlueprintOverride)
	void Beginplay()
	{
		Spline = UHazeSplineComponent::Get(SplineActor);

		DistanceAlongSpline = Spline.GetDistanceAlongSplineAtWorldLocation(this.GetActorLocation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick (float DeltaTime)
	{
		AdvanceOnSpline();
		SetLocationAndRotation();
	}

	void AdvanceOnSpline()
	{
		DistanceAlongSpline += MagneticWheel.CurrentVelocity * VelocityMultiplier;

		DistanceAlongSpline = FMath::Fmod(DistanceAlongSpline, Spline.SplineLength);
		
		if (DistanceAlongSpline < 0)
		{
			DistanceAlongSpline = Spline.SplineLength - DistanceAlongSpline;
		}
	}

	void SetLocationAndRotation()
	{
		FVector WorldPosition = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FRotator WorldRotation = Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		this.SetActorLocationAndRotation(WorldPosition, WorldRotation);
	}
}