import Peanuts.Spline.SplineComponent;

event void FPigPlatformEvent();

UCLASS(Abstract)
class AClockTownPigPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase Pig;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike EatTimeLike;
	default EatTimeLike.Duration = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh PigMesh;

	UPROPERTY()
	FPigPlatformEvent OnEaten;

	UPROPERTY()
	bool bPigOnPlatform = true;

	UPROPERTY()
	AHazeActor SplineActor;
	
	UPROPERTY()
	bool bFollowingSpline = false;

	UHazeSplineComponent CurrentSplineComp;

	float CurrentDistanceAlongSpline = 0.f;
	float SpeedAlongSpline = 500.f;

	bool bEaten = true;
	float EatDuration = 2.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPigOnPlatform)
		{
			Pig.SetHiddenInGame(false);
		}
		else
		{
			Pig.SetHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(SplineActor);
			if (SplineComp != nullptr)
			{
				CurrentSplineComp = SplineComp;
			}
		}

		EatTimeLike.BindUpdate(this, n"UpdateEat");
		EatTimeLike.BindFinished(this, n"FinishEat");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentSplineComp != nullptr && bFollowingSpline)
		{
			CurrentDistanceAlongSpline += SpeedAlongSpline * DeltaTime;
			FTransform CurTransform = CurrentSplineComp.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotator());

			if (CurrentDistanceAlongSpline >= CurrentSplineComp.SplineLength)
				StartEating();
		}
	}

	UFUNCTION()
	void StartEating()
	{
		bFollowingSpline = false;
		bEaten = false;
		EatTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateEat(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, -90.f, CurValue);
		PlatformRoot.SetRelativeRotation(FRotator(0.f, CurRot, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishEat()
	{
		if (bEaten)
		{
			CurrentDistanceAlongSpline = 0.f;
			bFollowingSpline = true;
		}
		else
		{
			bEaten = true;
			System::SetTimer(this, n"StopEating", EatDuration, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StopEating()
	{
		EatTimeLike.ReverseFromEnd();
		OnEaten.Broadcast();
	}

	UFUNCTION()
	void PutPigOnPlatform()
	{
		CurrentDistanceAlongSpline = CurrentSplineComp.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		bFollowingSpline = true;
		Pig.SetHiddenInGame(false);
	}
}