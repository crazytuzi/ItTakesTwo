import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;

class UPlayRoomTractorBeamAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureZeroGravity LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float RotationPlayRateRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float RotationPlayRateFwd;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator HipsWorldRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator HipsWorldRotation2;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator HipsLocalRotation;

	FVector PreviousWorldLocation;
    AHazePlayerCharacter Player;
	AHazePlayerCharacter OtherPlayer;

	bool bIsCharacterWorldUpOriented;
	bool bTryingToExit;

	float RollSpeed;
	float Roll;
	float PitchSpeed;
	float Pitch;
	float YawSpeed;
	float Yaw;
	FRotator PreviousActorRotation;

	const float SIDE_SPEED = 10.f;
	const float MIN_SIDE_SPEED_PERCENTAGE = 0.1f;
	const float PITCH_SPEED = 4.f;
	const float MIN_PITCH_SPEED_PERCENTAGE = 0.3f;
	const float YAW_SPEED = 5.f;
	const float MIN_YAW_SPEED_PERCENTAGE = 0.1f;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureZeroGravity>(GetFeatureAsClass(ULocomotionFeatureZeroGravity::StaticClass()));
		Player = Cast<AHazePlayerCharacter>(OwningActor);

		SetAnimFloatParam(n"BlendToInAir", 0.7f);
		PreviousWorldLocation = OwningActor.GetActorLocation();
		
		OtherPlayer = Game::GetCody() == OwningActor ? Game::GetMay() : Game::GetCody();

		bIsCharacterWorldUpOriented = OwningActor.ActorUpVector.Z == 1;
		bTryingToExit = false;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Player == nullptr)
            return;

		if (DeltaTime == 0.f)
			return;

		FVector DeltaVector = OwningActor.ActorLocation - OtherPlayer.ActorLocation;
		FRotator DeltaVectorRotation = Math::MakeRotFromXZ(DeltaVector, OtherPlayer.ActorUpVector);

		FRotator DeltaTickRotation = (DeltaVectorRotation - PreviousActorRotation).Normalized;
		PreviousActorRotation = DeltaVectorRotation;

		if (bIsCharacterWorldUpOriented)
		{
			// Pitch
			HipsWorldRotation2 = DeltaVectorRotation;
			HipsWorldRotation2.Pitch += CalculateRotation(Pitch, PitchSpeed, DeltaTickRotation.Pitch, MIN_PITCH_SPEED_PERCENTAGE, PITCH_SPEED, DeltaTime);

			// Roll
			HipsWorldRotation = DeltaVectorRotation;
			HipsWorldRotation.Roll += CalculateRotation(Roll, RollSpeed, DeltaTickRotation.Yaw, MIN_SIDE_SPEED_PERCENTAGE, SIDE_SPEED, DeltaTime, true);
			HipsWorldRotation = SetRotationRelativeToRotation(HipsWorldRotation, HipsWorldRotation2);
			
			
			// Yaw (Local)
			HipsLocalRotation.Yaw = CalculateRotation(Yaw, YawSpeed, (DeltaTickRotation.Pitch + DeltaTickRotation.Yaw) / 2.f, MIN_YAW_SPEED_PERCENTAGE, YAW_SPEED, DeltaTime, true);

		}
		else
		{
			// Pitch
			HipsWorldRotation2 = DeltaVectorRotation;
			HipsWorldRotation2.Pitch += CalculateRotation(Pitch, PitchSpeed, DeltaTickRotation.Yaw, MIN_PITCH_SPEED_PERCENTAGE, PITCH_SPEED, DeltaTime);

			// Roll
			HipsWorldRotation = DeltaVectorRotation;
			HipsWorldRotation.Roll += CalculateRotation(Roll, RollSpeed, DeltaTickRotation.Pitch, MIN_SIDE_SPEED_PERCENTAGE, SIDE_SPEED, DeltaTime, true);
			HipsWorldRotation = SetRotationRelativeToRotation(HipsWorldRotation, HipsWorldRotation2);
			
			// Yaw (Local)
			HipsLocalRotation.Yaw = Roll / 2.f;
		}

		// Blendspace values
		if (bTryingToExit)
			BlendspaceValues.Y = FMath::FInterpTo(BlendspaceValues.Y, 1000.f, DeltaTime, 7.f);
		else
			BlendspaceValues.Y = FMath::FInterpTo(BlendspaceValues.Y, (DeltaTickRotation.Pitch + DeltaTickRotation.Yaw) * 1000.f, DeltaTime, 5.f);

    }


	UFUNCTION()
	float CalculateRotation(float &Rotation, float &Speed, float RotationRate, float MinSpeed, float MaxSpeed, float DeltaTime, bool bExitLerp = false)
	{

		if (bTryingToExit && bExitLerp)
		{
			const float RotationTarget = (Speed < 0) ? 0.f : 360.f;
			Rotation = FMath::FInterpTo(Rotation, RotationTarget, DeltaTime, 3.f);
			return Rotation;
		}
		float SpeedTarget = FMath::Clamp((RotationRate / DeltaTime) / 30.f, -1.f, 1.f);

		if (FMath::Abs(SpeedTarget) < MinSpeed)
			SpeedTarget = (Speed < 0) ? -MinSpeed : MinSpeed;

		const float InterpSpeed = (FMath::Abs(Speed) < FMath::Abs(SpeedTarget) || bTryingToExit) ? 5.f : 1.f;

		Speed = FMath::FInterpTo(Speed, SpeedTarget, DeltaTime, InterpSpeed);
		
		Rotation += Speed * MaxSpeed;
		Rotation = Math::FWrap(Rotation, 0.f, 360.f);
		return Rotation;
	}


	UFUNCTION()
	FRotator SetRotationRelativeToRotation(FRotator Rotation, FRotator ParentRotator)
	{
		FTransform Transform1;
		Transform1.Rotation = ParentRotator.Quaternion();
		FTransform Transform2;
		Transform2.Rotation = Rotation.Inverse.Quaternion();
		Transform1.SetToRelativeTransform(Transform2);
		return Transform1.Rotator();
	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return LocomotionFeature.BlendTime;
	}
	

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		bTryingToExit = true;
		
        if (LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"SkyDive")
			return true;

		
		const FRotator DeltaHipsRotation = (OwningActor.ActorRotation - Player.Mesh.GetSocketRotation(n"Hips")).Normalized;
		
		if (FMath::Abs(DeltaHipsRotation.Roll) < 10.f)
			return true;

		RotationPlayRateFwd = 2.f;

		return false;
    }

}