import Vino.Movement.PlaneLock.PlaneConstraint;

class UPlaneLockUserComponent : UActorComponent
{
	FPlaneConstraint Constraint;
	UHazeBaseMovementComponent MoveComp;

	bool bWasReset = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);
	}

	bool IsActiveltyConstraining() const
	{
		return Constraint.Plane.IsValid();
	}

	void UpdatePlane(FVector Origin, FVector PlaneNormal)
	{
		if (!ensure(Constraint.Plane.IsValid()))
			return;

		Constraint.Plane.Origin = Origin;
		Constraint.Plane.Normal = PlaneNormal.SafeNormal;
	}

	void LockOwnerToPlane(FPlaneConstraintSettings ConstraintSettings)
	{
		bWasReset = false;
		if (!ensure(ConstraintSettings.IsValid()))
			return;

		FPlaneConstraintSettings Settings = ConstraintSettings;
		Settings.Normal = ConstraintSettings.Normal.GetSafeNormal();
		Constraint.Plane = Settings;
	}

	void StopLocking()
	{
	 	Constraint.Plane = FPlaneConstraintSettings();
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
	 	Constraint.Plane = FPlaneConstraintSettings();
		 bWasReset = true;
	}
}
