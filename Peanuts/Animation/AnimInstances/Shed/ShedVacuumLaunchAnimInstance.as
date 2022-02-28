import Peanuts.Animation.Features.Shed.LocomotionFeatureShedVacuumLaunch;
import Peanuts.Animation.AnimationStatics;

class UShedVacuumLaunchAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureShedVacuumLaunch LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator ForwardRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator SideRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PlayRate;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIntoSkyDive;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	bool bTryingToLeave;
	float FwdRotationOffset;
	

	float FwdSpeed;
	float SideSpeed;

	float FWD_TARGET_SPEED = 2.f;
	float SIDE_TARGET_SPEED = 1.f;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
        LocomotionFeature = Cast<ULocomotionFeatureShedVacuumLaunch>(GetFeatureAsClass(ULocomotionFeatureShedVacuumLaunch::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;

		FWD_TARGET_SPEED = GetAnimFloatParam(n"ForwardRotationSpeed", true);
		SIDE_TARGET_SPEED = GetAnimFloatParam(n"SideRotationSpeed", true);
		bSkipStart = GetAnimBoolParam(n"SkipStart", true);

		bTryingToLeave = false;
		float StopSpinningTime = GetAnimFloatParam(n"StopSpinningTime", true);

		bIntoSkyDive = GetAnimBoolParam(n"LaunchIntoSkydive", true);

		FwdRotationOffset = bIntoSkyDive ? 90.f : 0.f;
		
		if (StopSpinningTime > 0.f)
		{
			System::SetTimer(this, n"PrepareToLeave", StopSpinningTime, false);
		}	
		else
		{
			PrepareToLeave();
		}
			
		
		ForwardRotation.Pitch = OwningActor.ActorRotation.UnrotateVector(GetLocomotionWantedVelocity()).Rotation().Pitch - 90.f;
		FwdSpeed = 0.f;
		SideSpeed = 0.f;
		PlayRate = 1.f;

		SideRotation.Yaw = 0.f;
		SideRotation.Roll = 0.f;
    }

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.f;
	}
    

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{

        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		ForwardRotation.Pitch = CalculateHipsRotation(ForwardRotation.Pitch, FwdSpeed, FWD_TARGET_SPEED, DeltaTime, false, FwdRotationOffset);
		ForwardRotation.Pitch = Math::FWrap(ForwardRotation.Pitch, 0.f, 360.f);
		SideRotation.Yaw = CalculateHipsRotation(SideRotation.Yaw, SideSpeed, SIDE_TARGET_SPEED, DeltaTime, true);
		SideRotation.Yaw = Math::FWrap(SideRotation.Yaw, 0.f, 360.f);

		if (bTryingToLeave)
		{
			SideRotation.Roll = FMath::FInterpTo(SideRotation.Roll, 0.f, DeltaTime, 1.f);
			PlayRate = FMath::FInterpTo(PlayRate, 0.5f, DeltaTime, 0.5f);
		}
		else
		{
			SideRotation.Roll = FMath::FInterpTo(SideRotation.Roll, 0.f, DeltaTime, 1.f);
		}
		
    }

    // Can Transition From
    UFUNCTION()
    float CalculateHipsRotation(float CurrentRotation, float &Speed, float SpeedTarget, float DeltaTime, bool bAdd, float Offset = 0)
    {
		float lSpeedTarget = SpeedTarget;
		float InterpSpeed = 1.5f;
		if (bTryingToLeave)
		{
			float RotationDifference = Math::FWrap((CurrentRotation  / 360.f) + (Offset / 360.f), 0.f, 1.f);
			if (bAdd)
				RotationDifference = 1.f - RotationDifference;
			const float Multiply = bAdd ? 7.f : 3.f;
			lSpeedTarget = RotationDifference * SpeedTarget * Multiply;
			InterpSpeed = 20.f * (1.f - RotationDifference);
		}
	
		Speed = FMath::FInterpTo(Speed, lSpeedTarget, DeltaTime, InterpSpeed);

		const float DeltaRotationChange = Speed * DeltaTime * 100.f;
		if (bAdd)
			return CurrentRotation + DeltaRotationChange;
		else
			return CurrentRotation - DeltaRotationChange;
    }

    // Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		if (LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"SkyDive")
			return true;

		if (!bTryingToLeave)
			return false;

		if (SideRotation.Yaw > 330.f && ((ForwardRotation.Pitch < 30.f && FwdRotationOffset == 0.f) || (ForwardRotation.Pitch > 30.f && FwdRotationOffset != 0.f)) )
			return true;

        return false;
    }

	// On Transition From
	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"AirMovement")
			SetAnimFloatParam(n"BlendToInAir", 0.7f);
		else if (LocomotionAnimationTag == n"SkyDive")
		{
			SetAnimBoolParam(n"SkydiveSkipEnter", true);
			SetAnimFloatParam(n"SkyDiveBlendTime", 0.6f);
		}

		System::ClearTimer(this, n"PrepareToLeave");
	}


	// Unrotate the character to prepare for blending out of this ABP
	UFUNCTION()
	void PrepareToLeave()
	{
		bTryingToLeave = true;
	}

}