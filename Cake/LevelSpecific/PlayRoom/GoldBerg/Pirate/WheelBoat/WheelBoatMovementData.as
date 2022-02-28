
class UBoatSettingsDataAsset : UDataAsset
{
	UPROPERTY(Category = "Speed")
	float AccelerationSpeed = 1000;

	UPROPERTY(Category = "Speed")
	float AngularAcceleration = 50.0f;

	UPROPERTY(Category = "Drag")
	float ForwardDrag = 0.75f;

	UPROPERTY(Category = "Drag")
	float RightDrag = 8.2;

	UPROPERTY(Category = "Drag")
	float AngularDrag = 2.2f;


	// The extra speed we have when moving forward in the stream
	UPROPERTY(Category = "Stream")
	float StreamMovementBonusSpeed = 350;

	/* If 0, non of the input is used and 100% if the stream is used
	 * If 1, 100% of the input is used and 0 of the stream is used
	*/
	UPROPERTY(Category = "Stream", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StreamForwardMaxIngore = 0.8f;

	/* If 0, non of the input is used and 100% if the stream is used
	 * If 1, 100% of the input is used and 0 of the stream is used
	*/
	UPROPERTY(Category = "Stream", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StreamBackwardMaxIngore = 0.5f;

	// How fast we reach the forward speed
	UPROPERTY(Category = "Stream")
	float StreamAccelerationSpeed = 5;

	// How fast the boat will turn while in the boss stream
	UPROPERTY(Category = "Stream")
	float BossStreamAutoRotationSpeed = 10;

	// How fast we reached the break speed
	UPROPERTY(Category = "Stream")
	float StreamDecelerationSpeed = 3;

	// How fast we reach the streams speed when not giving input
	UPROPERTY(Category = "Stream")
	float StreamNormalizeSpeed = 3;

	// How fast the stream forces the rotation to align with the current stream
	UPROPERTY(Category = "Stream")
	FHazeMinMax StreamForceRotationSpeed = FHazeMinMax(0.1f, 1.5f);

	UPROPERTY(Category = "Impact")
	FWheelBoatImpactData RegularImpact;
	default RegularImpact.ImpactForce = 500.f;

	UPROPERTY(Category = "Impact")
	FWheelBoatImpactData StreamImpact;
	default StreamImpact.ImpactForce = 900.f;
}

struct FWheelBoatMovementData
{
	const float WheelSpeed = 200.0f;
	const float AccelerationDurationWithInput = 0.7f;
	const float AccelerationDurationNoInput = 0.5f;
	const float InputDeadzoneLimit = 0.8f;

	bool bIsLeftActor = false;
	private bool bHasUpdatedMovement = false;

	private float CurrentAnimationSpeed;
	private float AnimationRange;

	private float CurrentWheelSpeed;
	private float WheelRange;
	private float WheelDeltaVelocity;

	FVector BoatVelocity;
	FRotator BoatAngularVelocity;

	FVector RequestedDeltaMovement;
	float RequestedDeltaRotationYaw;

	FVector CurrentSteering = FVector::ZeroVector;
	FVector PendingSteering = FVector::ZeroVector;

	void UpdateMovement(float DeltaTime, float MovementInput, float AnimationInput)
	{
		// Update the movement
		UpdateSpeed(DeltaTime, MovementInput, CurrentWheelSpeed);
		const float LastWheelRange = WheelRange;
		WheelRange = CurrentWheelSpeed / WheelSpeed;
		WheelDeltaVelocity = WheelRange - LastWheelRange;

		// Update the AnimationInput
		UpdateSpeed(DeltaTime, AnimationInput, CurrentAnimationSpeed);
		AnimationRange = CurrentAnimationSpeed / WheelSpeed;
	}

	private void UpdateSpeed(float DeltaTime, float InputValue, float& OutSpeed) const
	{
		FHazeAcceleratedFloat AccelerateSpeed;		
		AccelerateSpeed.Value = OutSpeed;

		float FinalInputValue;
		if(InputValue > 0)
		{
			if(InputValue <= InputDeadzoneLimit)
			{
				FinalInputValue = InputValue/InputDeadzoneLimit;
			}
			else
			{
				FinalInputValue = 1.0f;
			}
		}
		else
		{
			if(InputValue >= -InputDeadzoneLimit)
			{
				FinalInputValue = InputValue/InputDeadzoneLimit;
			}
			else
			{
				FinalInputValue = -1.0f;
			}
		}

		float TargetSpeed = FinalInputValue * WheelSpeed;
		float AccelerationDuration = AccelerationDurationWithInput;

		AccelerateSpeed.AccelerateTo(TargetSpeed, AccelerationDuration, DeltaTime);
		OutSpeed = AccelerateSpeed.Value;
	}

	void Finalize(float DeltaTime)
	{
		FVector WantedDelta = BoatVelocity * DeltaTime;
		RequestedDeltaMovement = WantedDelta.ConstrainToPlane(FVector::UpVector);
		
		FRotator DeltaRotation = (BoatAngularVelocity * DeltaTime);
		RequestedDeltaRotationYaw = DeltaRotation.Yaw;

		CurrentSteering = PendingSteering;
		PendingSteering = FVector::ZeroVector;
		bHasUpdatedMovement = true;
	}

	void EndOfFrame(float DeltaTime)
	{
		if(!bHasUpdatedMovement)
		{
			WheelRange = FMath::FInterpTo(WheelRange, 0.f, DeltaTime, 1.0f);
		}

		bHasUpdatedMovement = false;
	}

	void StopMovement()
	{
		BoatVelocity = FVector::ZeroVector;
		BoatAngularVelocity = FRotator::ZeroRotator;
		WheelRange = 0;
		AnimationRange = 0;
		WheelDeltaVelocity = 0;
	}

	float GetWheelBoatWheelAnimationRange() const property
	{
		return AnimationRange;
	}

	float GetWheelMovementRange() const property
	{
		return WheelRange;
	}

	float GetWheelMovementVelocity() const property
	{
		return WheelDeltaVelocity;
	}

	bool HasUpdatedMovemend() const
	{
		return bHasUpdatedMovement;
	}
}

struct FWheelBoatImpactData
{
	// Applied every tick with deltatime as long as the ApplyTime as active
	UPROPERTY()
	float ImpactForce = 0.0f;

	/* The amount of the current speed that is multiplied into the force
	 * If the boatspeed is less than the min value, no impact is used.
	 * The if the boatspeed is >= to the max amount, the full 'ImpactForce' is used
	*/
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	FHazeMinMax SpeedValidation = FHazeMinMax(10.f, 500.f);

	// How long this impact should be valid
	UPROPERTY()
	float ApplyTime = 1.0f;

	// The percentage of the applytime that the input is locked
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float LockedInputPercentage = 0.0f;

	// The amount of input that is used if the input is not locked depening on the amount of ApplyTime left
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	FHazeMinMax InputAmountPercentage = FHazeMinMax(0.f, 1.f);

}

struct FWheelBoatAvoidPositionData
{
	bool IsValid() const
	{
		if(!bIsValid)
			return false;
		if(InternalAvoidRadius <= 0)
			return false;
		return true;
	}

	void Clear()
	{
		bIsValid = false;
	}

	void Setup(FVector Location, float Radius, float ForceAmount, float MinAvoidRadius = 0, float Exp = 1)
	{
		bIsValid = true;
		LocationToAvoid = Location;
		InternalAvoidRadius = Radius;
		InternalMinRadius = MinAvoidRadius;
		AvoidForceMax = ForceAmount;
		InternalExp = Exp;
	}

	FVector GetForce(FVector FromLocation) const
	{
		FVector DeltaAwayPoint = FromLocation - LocationToAvoid;

		// Fixup bad direction
		const float Distance = FMath::Max(DeltaAwayPoint.Size() - InternalMinRadius, 0.f);
		float Alpha = 1.f - FMath::Min(Distance / InternalAvoidRadius, 1.f);
		Alpha = FMath::EaseIn(0.f, 1.f, Alpha, InternalExp);
		const float ForceToApply = FMath::Lerp(0.f, AvoidForceMax, Alpha); 

		return DeltaAwayPoint.GetSafeNormal() * ForceToApply;
	}

	private FVector LocationToAvoid = FVector::ZeroVector;
	private float AvoidForceMax = 0;
	private float InternalMinRadius = 0;
	private float InternalAvoidRadius = 0;
	private float InternalExp = 1;
	private bool bIsValid = false;
}