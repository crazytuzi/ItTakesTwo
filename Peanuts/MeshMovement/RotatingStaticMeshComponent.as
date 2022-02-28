
UCLASS(hidecategories="Replication Input Mobile")
class URotatingStaticMeshComponent : UStaticMeshComponent
{

	/** How fast to update roll/pitch/yaw of the component we update. */
	UPROPERTY(Category = "Default")
	FRotator RotationRate;

	/**
	 * Translation of pivot point around which we rotate, relative to current rotation.
	 * For instance, with PivotTranslation set to (X=+100, Y=0, Z=0), rotation will occur
	 * around the point +100 units along the local X axis from the center of the object,
	 * rather than around the object's origin (the default).
	 */
	UPROPERTY(Category = "Default")
	FVector PivotTranslation;

	/** Whether rotation is applied in local or world space. */
	UPROPERTY(Category = "Default")
	bool bRotationInLocalSpace = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Compute new rotation
		const FQuat OldRotation = GetComponentQuat();
		const FQuat DeltaRotation = (RotationRate * DeltaTime).Quaternion();
		const FQuat NewRotation = bRotationInLocalSpace ? (OldRotation * DeltaRotation) : (DeltaRotation * OldRotation);

		// Compute new location
		if (!PivotTranslation.IsZero())
		{
			const FVector OldPivot = OldRotation.RotateVector(PivotTranslation);
			const FVector NewPivot = NewRotation.RotateVector(PivotTranslation);
			FVector DeltaLocation = (OldPivot - NewPivot);
			FVector NewLocatio = GetWorldLocation() + DeltaLocation;
			SetWorldLocationAndRotation(NewLocatio, NewRotation);
		}
		else
		{
			SetWorldRotation(NewRotation);
		}	
	}
}