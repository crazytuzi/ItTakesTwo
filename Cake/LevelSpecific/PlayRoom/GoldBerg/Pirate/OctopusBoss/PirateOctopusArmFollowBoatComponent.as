class UPirateOctopusArmFollowBoatComponent : UHazeSplineFollowComponent
{
	UPROPERTY()
	float DistanceOffset = 4500.0f;

	UPROPERTY()
	float ZOffset = 100.0f;

	bool bFollowBoat = true;
	bool bFaceBoat = true;

	FRotator FindRotationTowardsTarget(FVector FromLocation, AHazeActor Target) const
	{
		FVector DirToTarget = (Target.GetActorLocation() - FromLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		if(DirToTarget.IsNearlyZero())
			return Owner.GetActorRotation();
		
		return DirToTarget.Rotation();
	}
}
