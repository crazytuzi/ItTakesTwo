import Peanuts.Spline.SplineComponent;

event void FOnReachedEnd();

UCLASS(Abstract)
class AVacuumElectricityBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ElectricityBallComp;
	default ElectricityBallComp.bAutoActivate = false;

	UPROPERTY()
	AHazeActor SplineActor;
	USplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = ElectricityBallComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	UPROPERTY(NotEditable)
	bool bActive = false;

	UPROPERTY()
	bool bFlipDirection = false;

	float DistanceAlongSpline = 0.f;

	UPROPERTY()
	float MovementSpeed = 1500.f;

	UPROPERTY()
	FOnReachedEnd OnReachedEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor == nullptr)
			return;

		SplineComp = USplineComponent::Get(SplineActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		if (SplineComp == nullptr)
			return;

		float Direction = bFlipDirection ? -1.f : 1.f;
		DistanceAlongSpline += MovementSpeed * Direction * DeltaTime;

		FVector CurLoc = SplineComp.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocation(CurLoc);

		if ((!bFlipDirection && DistanceAlongSpline >= SplineComp.SplineLength) ||
			(bFlipDirection && DistanceAlongSpline <= 0.f))
		{
			ReachedEnd();
		}
	}

	UFUNCTION()
	void ActivateElectricityBall()
	{
		DistanceAlongSpline = bFlipDirection ? SplineComp.SplineLength : 0.f;
		ElectricityBallComp.Activate(true);
		bActive = true;
		HazeAkComp.HazePostEvent(StartAudioEvent);
		SetActorTickEnabled(true);
	}

	void ReachedEnd()
	{
		SetActorTickEnabled(false);
		bActive = false;
		ElectricityBallComp.Deactivate();
		OnReachedEnd.Broadcast();
		BP_ReachedEnd();
		HazeAkComp.HazePostEvent(StopAudioEvent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEnd()
	{}

	UFUNCTION()
	void UpdateSpline(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return;

		SplineActor = Actor;
		SplineComp = USplineComponent::Get(Actor);
	}
}