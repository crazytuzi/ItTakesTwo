import Peanuts.Movement.CollisionData;

struct FPlaneConstraintSettings
{
	// Normal of plane. Only valid if non-zero.
	UPROPERTY()
	FVector Normal = FVector::ZeroVector; 

	// Center of plane.
	UPROPERTY()
	FVector Origin = FVector::ZeroVector;

	UPROPERTY()
	USceneComponent PlaneDefiner = nullptr;

	void UpdatePlaneToComponent()
	{
		Normal = PlaneDefiner.GetRightVector();
		Origin = PlaneDefiner.WorldLocation;
	}

	bool IsValid() const
	{
		return !Normal.IsNearlyZero(SMALL_NUMBER);
	}
};


struct FPlaneConstraint
{
	FPlaneConstraintSettings Plane;

	void SetPlaneSettings(FPlaneConstraintSettings PlaneSettings)
	{
		Plane = PlaneSettings;
	}

	// Change input delta to move us onto the plane
	void CorrectDeltaToPlane(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState)
	{
		if (Plane.PlaneDefiner != nullptr)
			Plane.UpdatePlaneToComponent();

		// Need to do this even if delta is zero, since plane might be moving
		FVector TargetOnPlane = (SolverState.CurrentLocation + SolverState.RemainingDelta).PointPlaneProject(Plane.Origin, Plane.Normal);
		SolverState.RemainingDelta = (TargetOnPlane - SolverState.CurrentLocation);
	}

	bool IsConstrained() const
	{
		return Plane.IsValid();
	}
}
