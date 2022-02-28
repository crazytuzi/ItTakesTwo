import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeHalfPipe;

class USnowGlobeHalfPipeAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeHalfPipe LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator RootRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float BlendspaceValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bInAir;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPerformTrick;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bRotateSled;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bMovingFwd;

	float TrickSpeedThreshold = 3000.f;
	float RotationSpeedThreshold = 2800.f;
	FRotator TargetedRootRotaion;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSnowGlobeHalfPipe>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeHalfPipe::StaticClass()));
		RootRotation = FRotator::ZeroRotator;
		TargetedRootRotaion = FRotator::ZeroRotator;
		bRotateSled = false;

		if (GetAnimBoolParam(n"SledIsRotated", true))
		{
			RootRotation.Yaw += 180.f;
			TargetedRootRotaion.Yaw += 180.f;
		}
    }
    
	
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		const float Speed = GetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, true);

		const bool bSledIsRotated = RootRotation.Yaw > 90.f;
		bMovingFwd = Speed > 0.f && !bSledIsRotated || Speed < 0.f && bSledIsRotated;

		BlendspaceValue = FMath::Clamp(Speed / 1500.f, -1.f, 1.f);
		if (bSledIsRotated)
			BlendspaceValue *= -1;
		

		if (GetAnimBoolParam(n"InAir", true))
		{
			if (!bInAir)
			{
				// The sled just entered in air
				if (FMath::Abs(Speed) > TrickSpeedThreshold)
					bPerformTrick = true;
				if (FMath::Abs(Speed) > RotationSpeedThreshold && bMovingFwd)
				{
					TargetedRootRotaion.Yaw += 180.f;
					TargetedRootRotaion.Yaw = Math::FWrap(TargetedRootRotaion.Yaw, 0.f, 360.f);
					bRotateSled = true;
				}
			}
			bInAir = true;
		}
		else
		{
			bInAir = false;
			bPerformTrick = false;
		}

		if (bRotateSled)
		{
			const float InterpSpeed = bInAir ? 1.5f : 5.f;
			RootRotation.Yaw = FMath::FInterpTo(RootRotation.Yaw, TargetedRootRotaion.Yaw, DeltaTime, InterpSpeed);
			if (FMath::Abs(RootRotation.Yaw - TargetedRootRotaion.Yaw) < 1.f)
			{
				RootRotation.Yaw = TargetedRootRotaion.Yaw;
				bRotateSled = false;
			}
		}
    }
}