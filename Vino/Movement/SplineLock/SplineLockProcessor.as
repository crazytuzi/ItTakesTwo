import Peanuts.Movement.DeltaProcessor;
import Vino.Movement.SplineLock.ConstraintHandler;
import Vino.Movement.SplineLock.SplineLockComponent;

class USplineLockProcessor : UDeltaProcessor
{
	FHazeHitResult LastHit;
	USplineLockComponent SplineLockComp;

	private FSplineConstraintHandler& GetConstrainer() property
	{
		return SplineLockComp.Constrainer;
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Constrainer.MarkAsDirty();
	}

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTime) override
	{
		if (!Constrainer.IsConstrained())
			return;

		if (!Constrainer.IsInsideSplineBounds())
			return;

#if Editor
		FVector StartDelta = SolverState.RemainingDelta;
#endif

		Constrainer.CorrectDeltaToSpline(ActorState, SolverState, LastHit);
		Constrainer.UpdateExpectedData(SolverState, IterationTime);

#if EDITOR
		DebugComp.LogSplineLockIterationStart(SolverState, ActorState, StartDelta, Constrainer.CurrentSplineLocation, Constrainer.ExpectedSplineLocation);
#endif

		// Velocity should always point along the spline.
		FVector SplineDirection = Constrainer.CurrentSplineLocation.WorldForwardVector;
		float SplineVelocityDot = SplineDirection.DotProduct(SolverState.CurrentVelocity.SafeNormal);

		if (!SolverState.CurrentVelocity.IsNearlyZero() && (FMath::Abs(SplineVelocityDot) < 0.95f))
		{
			FVector HorizontalVel = SolverState.CurrentVelocity.ConstrainToPlane(ActorState.WorldUp);
			FVector VerticalVel = SolverState.CurrentVelocity - HorizontalVel;
			SolverState.CurrentVelocity = SplineDirection * HorizontalVel.Size() * FMath::Sign(SolverState.CurrentVelocity.DotProduct(Constrainer.CurrentSplineLocation.WorldForwardVector));
			SolverState.CurrentVelocity += VerticalVel;
		}
	
		LastHit = FHazeHitResult();
	}

	void ImpactCorrection(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult& Impact) override
	{
		if (!Constrainer.IsConstrained())
			return;

		if (!Constrainer.IsInsideSplineBounds())
			return;

		LastHit = Impact;

		// If we are constrained, we want to manipulate the normals of the hit so that we always get redirected _along_ the horizontal direction of the spline
		//	(or more accurately, the horizontal direction of our delta)
		// If we go purely on the spline-tangent, sometimes a little bit of horizontal delta will still be left after the redirect, and we get stuck against a wall
		FVector ConstrainForward = SolverState.RemainingDelta.ConstrainToPlane(ActorState.WorldUp);
		FVector ConstrainRight = ConstrainForward.CrossProduct(ActorState.WorldUp);
		ConstrainRight.Normalize();

		if (ConstrainRight.IsNearlyZero())
		{
			// If we dont have any horizontal delta though, constrain along the spline! It should be fine!
			ConstrainRight = Constrainer.GetCurrentRightVector();
		}

		FHitResult ConvertedResult = Impact.FHitResult;

		ConvertedResult.Normal = ConvertedResult.Normal.ConstrainToPlane(ConstrainRight);
		ConvertedResult.Normal.Normalize();

		ConvertedResult.ImpactNormal = ConvertedResult.ImpactNormal.ConstrainToPlane(ConstrainRight);
		ConvertedResult.ImpactNormal.Normalize();

		Impact.OverrideFHitResult(ConvertedResult);
	}

	void PostIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState) override
	{
		if (!Constrainer.IsConstrained())
			return;

		if (!Constrainer.IsInsideSplineBounds())
			return;

#if EDITOR
		FHazeSplineSystemPosition StartPos = Constrainer.CurrentSplineLocation;
#endif

		Constrainer.UpdatePositionOnSpline(SolverState.LastMovedDelta, ActorState.WorldUp);
#if Editor
		DebugComp.LogSplineLockIterationEnd(SolverState, ActorState, StartPos, Constrainer.CurrentSplineLocation);
#endif
	}

	bool HandleDepenetration(FCollisionSolverActorState ActorState, FCollisionSolverState SolverState, UHazeShapeTracer Shapetracer, FHazeHitResult Hit, FDepenetrationOutput& Output)
	{
		if (!Constrainer.IsConstrained())
			return false;

		if (!Constrainer.IsInsideSplineBounds())
			return false;

		FVector RightVector = Constrainer.CurrentSplineLocation.WorldRightVector;
		FVector MTDDir = Hit.Normal.ConstrainToPlane(RightVector).Normalize;

#if Editor
		DebugComp.LogSplineLockDepentrate(SolverState, Hit.FHitResult, MTDDir, Constrainer.CurrentSplineLocation);
#endif
		return false;
	}

	void OnDepentrated(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FDepenetrationOutput DepenetrationOutput) 
	{
		if (!Constrainer.IsConstrained())
			return;

		if (!Constrainer.IsInsideSplineBounds())
			return;

		Constrainer.MarkAsDirty();
	}
}
