import Peanuts.Movement.DeltaProcessor;
import Vino.Movement.PlaneLock.PlaneConstraint;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;

class UPlaneLockProcessor : UDeltaProcessor
{
	UPlaneLockUserComponent PlaneLockComp;

	bool bDontForceToPlane = false;

	private FPlaneConstraint& GetConstraint() property
	{
		return PlaneLockComp.Constraint;
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		bDontForceToPlane = false;
	}

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTime) override
	{
		if (bDontForceToPlane)
		{
			bDontForceToPlane = false;
			return;
		}

		if (!ensure(Constraint.IsConstrained()))
			return;

		Constraint.CorrectDeltaToPlane(ActorState, SolverState);
	}

	void ImpactCorrection(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, FHazeHitResult& Impact) override
	{
		if (!ensure(Constraint.IsConstrained()))
			return;

		FHitResult ConvertedImpact = Impact.FHitResult;
		float DotDifference = FMath::Abs(ConvertedImpact.ImpactNormal.DotProduct(Constraint.Plane.Normal));
		if (FMath::IsNearlyEqual(DotDifference, 1.f, 0.1f))
		{
			bDontForceToPlane = true;
			return;
		}

		ConvertedImpact.Normal = ConvertedImpact.Normal.ConstrainToPlane(Constraint.Plane.Normal);
		ConvertedImpact.Normal.Normalize();

		ConvertedImpact.ImpactNormal = ConvertedImpact.ImpactNormal.ConstrainToPlane(Constraint.Plane.Normal);
		ConvertedImpact.ImpactNormal.Normalize();

		Impact.OverrideFHitResult(ConvertedImpact);
	}
}
