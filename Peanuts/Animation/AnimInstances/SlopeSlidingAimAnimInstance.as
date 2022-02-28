import Peanuts.Animation.Features.LocomotionFeatureInSlopeSlidingAim;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Cake.Weapons.Match.MatchWielderComponent;
import Peanuts.Animation.AnimationStatics;

class USlopeSlidingAimAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSlopeSlidingAim LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	WeaponType Weapon;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform LeftHandIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D AimAngles;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bShotThisTick;

	// Sap gun spesific variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SapGunFireRate;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayHitReaction;

	USapWeaponWielderComponent SapWeaponComp;
	UMatchWielderComponent MatchWeaponComp;
	bool bUpdateSapAimValues = true;
	bool bInterpAimValues = false;
	

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSlopeSlidingAim>(GetFeatureAsClass(ULocomotionFeatureSlopeSlidingAim::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;

		Weapon = LocomotionFeature.Weapon;
		if (Weapon == WeaponType::SapGun)
			SapWeaponComp = USapWeaponWielderComponent::Get(OwningActor);
			
		else if (Weapon == WeaponType::MatchWeapon)
			MatchWeaponComp = UMatchWielderComponent::Get(OwningActor);


		// IK Ref
		if (Animation::IsSequencePlayerDataValid(LocomotionFeature.IKReference))
			LeftHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKReference, 0.f, n"RightAttach", n"LeftHand");


		bIsShooting = false;

		// Consume the hitreaction boolean
		SetAnimBoolParam(n"HitReaction", false);
		if (PreviousAnimationUpdateParams.LocomotionTag != n"SlopeSliding")
		{
			bPlayHitReaction = false;
			bUpdateSapAimValues = true;
		}
		bInterpAimValues = false;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		if (GetAnimBoolParam(n"HitReaction", true))
		{
			bPlayHitReaction = true;
			if (Weapon == WeaponType::SapGun)
			{
				bUpdateSapAimValues = false;
				System::SetTimer(this, n"StartUpdatingSapAimValues", 0.5f, false);
			}
				
		}

		if (Weapon == WeaponType::SapGun)
		{
			if (bUpdateSapAimValues)
			{
				if (bInterpAimValues)
				{
					AimAngles.X = FMath::FInterpTo(AimAngles.X, SapWeaponComp.AimAngles.X, DeltaTime, 10.f);
					AimAngles.Y = FMath::FInterpTo(AimAngles.Y, SapWeaponComp.AimAngles.Y, DeltaTime, 10.f);
					if (FMath::Abs(AimAngles.X - SapWeaponComp.AimAngles.X) < 5.f && FMath::Abs(AimAngles.Y - SapWeaponComp.AimAngles.Y) < 5.f)
						bInterpAimValues = false;
				}
				else
					AimAngles = SapWeaponComp.AimAngles;
			}
				
			bIsShooting = SapWeaponComp.bAnimIsShooting;
			bShotThisTick = SapWeaponComp.bAnimShotThisFrame;
			SapGunFireRate = FMath::Clamp(SapWeaponComp.Pressure / 4.5f, 0.f, 1.f);
		}

		else if (Weapon == WeaponType::MatchWeapon)
		{
			AimAngles = MatchWeaponComp.AimAngles;
			bShotThisTick = GetAnimBoolParam(n"SniperShoot",true);
			if (bShotThisTick)
				bIsShooting = true;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubFeature)
	{
		if (LocomotionAnimationTag == n"SlopeSliding")
			SetAnimBoolParam(n"SlopeSlidingSkipEnter", true);
	}

	UFUNCTION()
    void StartUpdatingSapAimValues()
    {
        bUpdateSapAimValues = true;
		bInterpAimValues = true;
    }

	UFUNCTION()
    void AnimNotify_StopMatchFire()
    {
        bIsShooting = false;
    }

	UFUNCTION()
	void AnimNotify_StopPlayingHitReaction()
	{
		bPlayHitReaction = false;
	}

}