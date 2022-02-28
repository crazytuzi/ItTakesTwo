import Peanuts.MeshMovement.MeshMovementObserver;

class UMeshMovementLocalObserver : UMeshMovementObserver
{
	FVector AccumulatedVelocity;
	FVector AccumulatedRotationVelocity;

	void Start(bool bIsControlSide)
	{
		UMeshMovementObserver::Start(bIsControlSide);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RotationVelocityIsZero() && VelocityIsZero())
			MeshStoppedMoving();
	}

	bool RotationVelocityIsZero()
	{
		return MeshComponent.GetPhysicsAngularVelocityInDegrees().IsNearlyZero();
	}

	bool VelocityIsZero()
	{
		return MeshComponent.GetPhysicsLinearVelocity().IsNearlyZero();
	}
}