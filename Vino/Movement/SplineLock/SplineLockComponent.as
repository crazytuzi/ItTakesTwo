import Peanuts.Spline.SplineComponent;
import Vino.Movement.SplineLock.ConstraintHandler;

enum ESplineLockType
{
	Normal,
	Distance,
	None,
}

class USplineLockComponent : UActorComponent
{
	ESplineLockType ActiveLockType = ESplineLockType::None;

	FSplineConstraintHandler Constrainer;

	UHazeBaseMovementComponent MoveComp;

	float PlayerMaxSplineDistanceDif = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		StopLocking();
	}

	bool IsActiveltyConstraining() const
	{
		return Constrainer.IsConstrained();
	}

	void LockOwnerToSpline(FConstraintSettings ConstrainSettings, ESplineLockType LockType = ESplineLockType::Normal)
	{
		if (!ensure(ConstrainSettings.SplineToLockMovementTo != nullptr))
			return;

		Constrainer.Initialize(ConstrainSettings, Owner.ActorLocation);
		ActiveLockType = LockType;
	}

	void StopLocking()
	{
		Constrainer = FSplineConstraintHandler();
		ActiveLockType = ESplineLockType::None;
	}

	UHazeSplineComponentBase GetSpline() const property
	{
		if (Constrainer.CurrentSplineLocation.Spline != nullptr)
			return Constrainer.CurrentSplineLocation.Spline;

		return Constrainer.SplineToLockMovementTo;
	}

	bool IsWithinSplineBounds() const
	{
		if (!Constrainer.IsConstrained())
			return false;

		return Constrainer.IsInsideSplineBounds();
	}
}
