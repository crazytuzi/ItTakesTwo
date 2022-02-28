import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;
import Vino.Movement.Components.MovementComponent;

event void FBasementRoseEvent();

class ABasementRose : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY()
	FBasementRoseEvent OnReachedEndOfSpline;

	float CurrentDistanceAlongSpline = 0.f;
	UHazeSplineComponent CurrentSplineComp;
	bool bMovingAlongSpline = false;
	float CurrentSpeedAlongSpline = 500.f;

	UAnimSequence CurrentMh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"CharacterJumpToCapability");
		MoveComp.Setup(CapsuleComponent);
	}

	UFUNCTION()
	void StartMovingAlongSpline(ASplineActor SplineActor)
	{
		CurrentSplineComp = SplineActor.Spline;
		if (CurrentSplineComp == nullptr)
			return;

		FTransform ClosestTransform = CurrentSplineComp.FindTransformClosestToWorldLocation(ActorLocation, ESplineCoordinateSpace::World);
		SmoothSetLocationAndRotation(ClosestTransform.Location, ClosestTransform.Rotator());
		CurrentDistanceAlongSpline = 0.f;
		bMovingAlongSpline = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentSplineComp == nullptr)
			return;

		if (!bMovingAlongSpline)
			return;

		CurrentDistanceAlongSpline += CurrentSpeedAlongSpline * DeltaTime;
		CurrentDistanceAlongSpline = FMath::Clamp(CurrentDistanceAlongSpline, 0.f, CurrentSplineComp.SplineLength);
		FTransform CurTransform = CurrentSplineComp.GetTransformAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocationAndRotation(CurTransform.Location, CurTransform.Rotator());

		if (CurrentDistanceAlongSpline >= CurrentSplineComp.SplineLength)
		{
			bMovingAlongSpline = false;
			OnReachedEndOfSpline.Broadcast();
		}
	}

	UFUNCTION()
	void PlayTransitionAnimation(UAnimSequence Anim, UAnimSequence Mh, AActor StartTransform, float Blend = 0.2f)
	{
		if (StartTransform != nullptr)
			SmoothSetLocationAndRotation(StartTransform.ActorLocation, StartTransform.ActorRotation);

		FHazeAnimationDelegate BlendingOut;
		BlendingOut.BindUFunction(this, n"TransitionAnimationBlendingOut");
		PlayEventAnimation(OnBlendingOut = BlendingOut, Animation = Anim, BlendTime = Blend);

		CurrentMh = Mh;
	}

	UFUNCTION()
	void TransitionAnimationBlendingOut()
	{
		PlayEventAnimation(Animation = CurrentMh, bLoop = true, BlendTime = 0.f);
	}

	UFUNCTION()
	void PlayMhAnimation(UAnimSequence Anim, float Blend = 0.f)
	{
		PlayEventAnimation(Animation = Anim, bLoop = true, BlendTime = Blend);
	}
}