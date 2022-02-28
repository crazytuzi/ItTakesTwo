import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;

class UClockWorkPedalBoatAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData PedalProgress;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator WheelRotationMay;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator WheelRotationCody;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PedalProgressTimeMay;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PedalProgressTimeCody;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PedalBoatVelocity;

	ASplineBoatActor BoatActor;
	float MayWheelRotationSpeed,
	CodyWheelRotationSpeed,
	MayPedalSpeed,
	CodyPedalSpeed;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
		BoatActor = Cast<ASplineBoatActor>(OwningActor);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (BoatActor == nullptr)
            return;

		PedalBoatVelocity = FMath::Abs(BoatActor.BoatSpeed / 540.f);
		

		if (BoatActor.PlayerCompMay != nullptr)
		{
			float WheelTargetSpeed = (BoatActor.PlayerCompMay.TargetSpeed / -2.f);
			if (PedalBoatVelocity > .5f)
				WheelTargetSpeed * 2.f;
			CalculateWheelRotation(WheelRotationMay.Pitch, MayWheelRotationSpeed, WheelTargetSpeed, 0.3f, 0.f, 360.f, DeltaTime);
			CalculateWheelRotation(PedalProgressTimeMay, MayPedalSpeed, BoatActor.PlayerCompMay.TargetSpeed / 210.f, 2.f, 0.f, 1.f, DeltaTime);
		}

		if (BoatActor.PlayerCompCody != nullptr)
		{
			CalculateWheelRotation(WheelRotationCody.Pitch, CodyWheelRotationSpeed, BoatActor.PlayerCompCody.TargetSpeed / -2.f, 0.3f, 0.f, 360.f, DeltaTime);
			CalculateWheelRotation(PedalProgressTimeCody, CodyPedalSpeed, BoatActor.PlayerCompCody.TargetSpeed / 210.f, 2.f, 0.f, 1.f, DeltaTime);
		}
    }

	// Calculate the wheel rotation based on the input from the player
	UFUNCTION()
	void CalculateWheelRotation(float& CurrentValue, float& Speed, float MoveSpeed, float InterpSpeedInput, float Min, float Max, float DeltaTime)
	{
		float InterpSpeed = InterpSpeedInput;
		if (FMath::Abs(MoveSpeed) > 100.f)
			InterpSpeed *= 3.f;
		Speed = FMath::FInterpTo(Speed, MoveSpeed, DeltaTime, InterpSpeed);
		CurrentValue = Math::FWrap(CurrentValue + (Speed * DeltaTime), Min, Max);
	}
    

}