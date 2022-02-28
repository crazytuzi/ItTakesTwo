import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class ASnowGlobeForestRotatePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UMagnetGenericComponent Magnet;

	// Determines if Cody is pulling the catapult
	bool bIsPulling = false;

	UPROPERTY(NotVisible)
	FHazeConstrainedPhysicsValue Rotation;
	default Rotation.Value = 0.f;
	default Rotation.LowerBound = 0.f;
	default Rotation.UpperBound = 90.f;
	default Rotation.Friction = 0.4f; //Low = Constant speed
	default Rotation.LowerBounciness = 0.35f; //Less bounce = 0 against wall
	default Rotation.UpperBounciness = 0.15f; //Less bounce = 0

	UPROPERTY(Category = Physics)
	float ConstantAcceleration = -120.f;

	UPROPERTY(Category = Physics)
	float MagnetAcceleration = 370.f;

	UPROPERTY(Category = Platform)
	float RotateAngle = 90.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Rotation.UpperBound = RotateAngle;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TotalForce = 0.f;

		// Acceleration towards the beam
		TotalForce += ConstantAcceleration;

		// Pull force!
		// Make sure this is higher than the constant acceleration :^)
		FVector MagnetForceDirection = Magnet.GetDirectionalForceFromAllInfluencers();
		float PullForce = MagnetForceDirection.DotProduct(Magnet.ForwardVector);

		if (!FMath::IsNearlyZero(PullForce, KINDA_SMALL_NUMBER))
		{
			// Make the pull-force binary,
			//	it feels better than the force slowing down very fast once the platform starts rotating.
			PullForce = FMath::Sign(PullForce);
		}

		TotalForce += PullForce * MagnetAcceleration;

		Rotation.AddAcceleration(TotalForce);
		Rotation.Update(DeltaTime);
		RotationRoot.SetRelativeRotation(FRotator(0.f, Rotation.Value, 0.f));
	}
}