import Peanuts.Spline.SplineComponent;
class AGrindSplineElectricShock : AHazeActor
{
	UPROPERTY(RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UPointLightComponent Light;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY()
	float Speed = 1000;

	UPROPERTY()
	AActor SplineActor;

	UPROPERTY()
	float StartOffsetFraction;

	UPROPERTY()
	FHazeTimeLike Timelike;

	float DistanceAlongSpline;

	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = UHazeSplineComponent::Get(SplineActor);
		DistanceAlongSpline = Spline.GetSplineLength() * StartOffsetFraction;

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		float PlayRate = 1 / (Spline.SplineLength / Speed);

		Timelike.BindUpdate(this, n"TimelikeTick");
		Timelike.SetNewTime(StartOffsetFraction);
		Timelike.bLoop = true;
		Timelike.SetPlayRate(PlayRate);
		Timelike.Play();
	}

	UFUNCTION()
	void OnOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.SetCapabilityActionState(n"HitByElectricShock", EHazeActionState::Active);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TimelikeTick(float CurValue)
	{
		DistanceAlongSpline = CurValue * Spline.GetSplineLength();
		SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World));
	}
}