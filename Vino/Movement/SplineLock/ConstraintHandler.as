import Peanuts.Movement.CollisionData;
import Peanuts.Spline.SplineComponent;

struct FConstraintSettings
{
	UPROPERTY()
	UHazeSplineComponentBase SplineToLockMovementTo = nullptr;

	UPROPERTY()
	bool bLockToEnds = true;

	UPROPERTY()
	EConstrainCollisionHandlingType ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
};

struct FSplineConstraintHandler
{
	UHazeSplineComponentBase SplineToLockMovementTo = nullptr;
	bool bLockToEnds = true;

	FHazeSplineSystemPosition CurrentSplineLocation;
	bool bIsDirty = true;

	FHazeSplineSystemPosition ExpectedSplineLocation;
	FVector ExpectedIterationDelta = FVector::ZeroVector;
	float ExpectedIterationDistance = 0.f;

	float OvershotAmount = 0.f;

	bool IsSameAs(FConstraintSettings Settings) const
	{
		if (SplineToLockMovementTo != Settings.SplineToLockMovementTo)
			return false;

		if (Settings.ConstrainType == EConstrainCollisionHandlingType::FreeVertical)
			return false;

		if (bLockToEnds != Settings.bLockToEnds)
			return false;

		return true;
	}

	void Initialize(FConstraintSettings Settings, FVector OwnerLocation)
	{
		SplineToLockMovementTo = Settings.SplineToLockMovementTo;
		bLockToEnds = Settings.bLockToEnds;
		OvershotAmount = 0.f;
		MarkAsDirty();		
		
		CurrentSplineLocation = SplineToLockMovementTo.FindSystemPositionClosestToWorldLocation(OwnerLocation);
	}

	void RecalculateDistance(FCollisionSolverState& SolverState, FVector WorldUp)
	{
		CurrentSplineLocation = SplineToLockMovementTo.FindSystemPositionClosestToWorldLocation(SolverState.CurrentLocation);
		const FVector WantedHorizontalLocation = CurrentSplineLocation.WorldLocation.ConstrainToPlane(WorldUp);
		const FVector CurrentVerticalLocation = SolverState.CurrentLocation.ConstrainToDirection(WorldUp);
		SolverState.CurrentLocation = WantedHorizontalLocation + CurrentVerticalLocation;

		bIsDirty = false;
	}

	// Based on an input world delta in any direction, calculates;
	//	The delta the user SHOULD move to be constrained to the spline, and
	//	The calculated distance the user moves along the spline with returned delta
	void CorrectDeltaToSpline(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult Hit)
	{
		// // If we are dirty then our current saved distance on spline is no longer relevant and we need to recalculate it.
		float DistanceDif = (CurrentSplineLocation.WorldLocation - SolverState.CurrentLocation).ConstrainToPlane(ActorState.WorldUp).Size();
		if (bIsDirty || DistanceDif > 10.f)
			RecalculateDistance(SolverState, ActorState.WorldUp);

		ExpectedSplineLocation = CurrentSplineLocation;
		ExpectedIterationDistance = 0.f;
		ExpectedIterationDelta = FVector::ZeroVector;

		if (SolverState.RemainingDelta.IsNearlyZero())
		 	return;

		// Spline locking works for the most part on the horizontal-plane (vertical is free), so split now
		FVector HoriDelta;
		FVector VertDelta;
		Math::DecomposeVector(VertDelta, HoriDelta, SolverState.RemainingDelta, ActorState.WorldUp);

		// // We want to _pretend_ the spline is completely flat, so get the flat tangent
		FVector SplineTangent = CurrentSplineLocation.WorldForwardVector;
		SplineTangent = SplineTangent.ConstrainToPlane(ActorState.WorldUp);
		SplineTangent.Normalize();

		// // Calculate where we _want_ to end up on the spline, based on the speed we're moving.
		ExpectedIterationDistance = HoriDelta.Size() * FMath::Sign(SplineTangent.DotProduct(HoriDelta));
		//ExpectedIterationDistance = SplineTangent.DotProduct(HoriDelta);

		if (FMath::IsNearlyZero(ExpectedIterationDistance))
		 	return;

		float OverShoot = 0.f;
		ExpectedSplineLocation.Move(ExpectedIterationDistance, OverShoot);

		FVector LocDif = ExpectedSplineLocation.WorldLocation - SolverState.CurrentLocation;
		FVector HorizontalDelta = LocDif.ConstrainToPlane(ActorState.WorldUp);

		FVector SplineDelta = ExpectedSplineLocation.WorldLocation - CurrentSplineLocation.WorldLocation;
		if (SplineDelta.DotProduct(HorizontalDelta) < 0.f)
		{
			HorizontalDelta = SplineDelta;
			bIsDirty = true;
		}

		if (!bLockToEnds)
			HorizontalDelta += SplineTangent * OverShoot;
		
		SolverState.RemainingDelta = HorizontalDelta + VertDelta;

		// // If last sweep we hit a surface that points a little up or down then we allow the delta to go away from the spline to allow the character to keep moving along the surface and not get stuck.
		if (Hit.bBlockingHit)
		{
			if (SolverState.RemainingDelta.DotProduct(Hit.Normal) < 0.f && !FMath::IsNearlyZero(Hit.Normal.DotProduct(ActorState.WorldUp), 0.1f))
				SolverState.RemainingDelta = Math::ConstrainVectorToSlope(SolverState.RemainingDelta, Hit.Normal, ActorState.WorldUp).GetSafeNormal() * SolverState.RemainingDelta.Size();
		}
	}

	void UpdateExpectedData(FCollisionSolverState SolverState, float IterationTime)
	{
		ExpectedIterationDelta = SolverState.PeekDelta(IterationTime);
		ExpectedIterationDistance = ExpectedIterationDistance * (IterationTime / SolverState.RemainingTime);
	}

	// Updates distance on spline based on how much we actually moved after collision checking, compared to how much we expected to move
	//	This is called with the outputs of CalculateSplineMovementFromWorldDelta, it makes little sense on its own.
	//	The reason is that you cant really make conclusions about what distance along the spline we've traveled strictly on the delta,
	//		which is why the first function is needed.
	void UpdatePositionOnSpline(FVector MovedDelta, FVector WorldUp)
	{
		FVector MovedHoriDelta = MovedDelta.ConstrainToPlane(WorldUp);
		FVector ExpectedHoriDelta = ExpectedIterationDelta.ConstrainToPlane(WorldUp);

		if (ExpectedHoriDelta.IsNearlyZero())
		 	return;

		//If we hit something during the move, move a percentage of the way along the spline instead. It is not perfect, but good enough.
		const float PercentageMoved = MovedHoriDelta.Size() / ExpectedHoriDelta.Size();
		CurrentSplineLocation.Move(ExpectedIterationDistance * PercentageMoved, OvershotAmount);
		if (bLockToEnds)
			OvershotAmount = 0.f;
	}

	bool IsInsideSplineBounds() const
	{
		return FMath::IsNearlyZero(OvershotAmount);
	}

	void MarkAsDirty()
	{
		bIsDirty = true;
	}

	bool IsConstrained() const
	{
		return SplineToLockMovementTo != nullptr && IsInsideSplineBounds();
	}

	FVector GetCurrentRightVector() const
	{
		return CurrentSplineLocation.WorldRightVector;
	}
}
