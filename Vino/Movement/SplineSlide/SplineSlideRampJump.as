import Vino.Movement.SplineSlide.SplineSlideComponent;

event void FOnRampJumpActivated();

class ASplineSlideRampJump : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent JumpTrigger;
	default JumpTrigger.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(Category = "Spline Snapping")
	ASplineSlideSpline SnapToSpline;

	UPROPERTY(Category = "Spline Snapping")
	float HeightOffset = 0.f;

	UPROPERTY(Category = "Spline Snapping")
	bool bSnapRotation = false;
	
	UPROPERTY(Category = "Spline Snapping", meta = (EditCondition = "bSnapRotation", EditConditionHides))
	FRotator RotationOffset = FRotator::ZeroRotator;

	UPROPERTY()
	FOnRampJumpActivated OnJumpActivated;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SnapToSpline == nullptr)
			return;

		float Distance = SnapToSpline.Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		FTransform SplineTransform = SnapToSpline.Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		
		FVector Location = ActorLocation;
		Location = SplineTransform.InverseTransformPosition(Location);
		Location.Z = HeightOffset;
		Location = SplineTransform.TransformPosition(Location);

		SetActorLocation(Location);

		if (bSnapRotation)
		{
			FRotator Rotation = SplineTransform.TransformRotation(RotationOffset.Quaternion()).Rotator();
			SetActorRotation(Rotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JumpTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		JumpTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");

	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		USplineSlideComponent SplineSlideComp = USplineSlideComponent::Get(OtherActor);
		
		if (SplineSlideComp == nullptr)
			return;

		SplineSlideComp.ActiveRampJumps.Add(Cast<UObject>(this));
	}

	UFUNCTION()
    void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		USplineSlideComponent SplineSlideComp = USplineSlideComponent::Get(OtherActor);
		
		if (SplineSlideComp == nullptr)
			return;

		SplineSlideComp.ActiveRampJumps.Remove(Cast<UObject>(this));
    }	
}