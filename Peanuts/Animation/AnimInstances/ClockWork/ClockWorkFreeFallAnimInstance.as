import Peanuts.Animation.Features.Music.LocomotionFeatureFreeFall;

class UClockWorkFreeFallAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureFreeFall LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCollide;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bReverse;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator HipsFwdRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator HipsSideRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector StickInput;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PlayRate;

	float SideRotationSpeed = 200.f; //200
	float FwdRotationSpeed = 500.f; //500

	const float MIN_STICK_INPUT = .4f;

	bool bCollisionRotation;
	float FwdRotationInput;
	float SideRotationInput;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureFreeFall>(GetFeatureAsClass(ULocomotionFeatureFreeFall::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;

		SideRotationSpeed = LocomotionFeature.SideRotationSpeed;
		FwdRotationSpeed = LocomotionFeature.FwdRotationSpeed;

		SideRotationInput = LocomotionFeature.InitialSideRotation;
		FwdRotationInput = LocomotionFeature.InitialSideRotation;

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LocomotionFeature == nullptr)
            return;

		
		if (GetAnimBoolParam(n"FreeFallRewind"))
		{
			// Rewinding time
			PlayRate = -2.5f;
			HipsSideRotation.Yaw += CalculateHipsRotation(2.f, SideRotationInput, SideRotationSpeed, DeltaTime, 0.7f);
			HipsFwdRotation.Pitch += CalculateHipsRotation(5.f, FwdRotationInput, FwdRotationSpeed, DeltaTime);
			return;
		}

		// Check if player collides with something
		bCollide = GetAnimBoolParam(n"FreeFallCollidedCog", true) || GetAnimBoolParam(n"FreeFallCollidedBar", true);
		if (bCollide)
		{
			// Enable a special collision rotation for a short period
			bCollisionRotation = true;
			System::SetTimer(this, n"DisableCollisionRotation", 1.f, false);
		}

		StickInput = GetAnimVectorParam(n"FreeFallBlendspace", true);

		// Make the playrate of the animation faster if the user is holding down the stick
		PlayRate = FMath::Clamp(StickInput.Size(), 0.7f, 50.f) + .2f;

		// Calculate the hips rotation
		HipsSideRotation.Yaw -= CalculateHipsRotation(StickInput.Y, SideRotationInput, SideRotationSpeed, DeltaTime, 0.7f);
		HipsFwdRotation.Pitch -= CalculateHipsRotation(StickInput.X, FwdRotationInput, FwdRotationSpeed, DeltaTime);

    }

	UFUNCTION()
	float CalculateHipsRotation(float StickInput, float &RotationInput, float &RotationSpeed, float DeltaTime, float CollisionMultiplier = 1.f)
	{
		float TargetSpeed;
		float InterpSpeed;
		if (bCollisionRotation)
		{
			// Collision rotation
			if (bCollide)
			{
				// Flip the rotation direction & give it an impulse
				RotationInput = 5.f * (RotationInput > 0.f ? -1.f : 1.f) * CollisionMultiplier;
			}
			TargetSpeed = 1.f * (RotationInput > 0.f ? 1.f : -1.f) * CollisionMultiplier;
			InterpSpeed = 5.f;
		}
		else if (FMath::Abs(StickInput) > MIN_STICK_INPUT)
		{
			// If stick input is above a certain threshold, use it as a target for the rotation speed
			TargetSpeed = StickInput;
			InterpSpeed = 15.f;
		}
		else
		{
			// If there are no stick input or below a threshold, keep some of the rotation going
			TargetSpeed = MIN_STICK_INPUT * (RotationInput > 0.f ? 1.f : -1.f);
			InterpSpeed = 1.f;
		}
		RotationInput = FMath::FInterpTo(RotationInput, TargetSpeed, DeltaTime, InterpSpeed);
		return (RotationInput * RotationSpeed) * DeltaTime;
	}

	UFUNCTION()
	void DisableCollisionRotation()
	{
		bCollisionRotation = false;
	}

}