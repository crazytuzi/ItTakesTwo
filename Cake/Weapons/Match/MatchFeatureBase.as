import Cake.Weapons.Match.MatchWielderComponent;
import Peanuts.Animation.AnimationStatics;
import Vino.Movement.Components.MovementComponent;

class ULocomotionFeatureWeaponUtils : UHazeLocomotionFeatureBase
{
	UPROPERTY()
	FHazePlaySequenceData IKReference;
}

class USniperFeatureBase : UHazeFeatureSubAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	UMatchWielderComponent SniperWielderComp;

	//UPROPERTY(BlueprintReadOnly)
	//UHazeMovementComponent MoveComp = nullptr;

	UPROPERTY()
	FHazePlaySequenceData IKReference;

	UPROPERTY(BlueprintReadOnly)
	FVector2D AimValues;

	UPROPERTY(BlueprintReadOnly)
	FTransform IKTarget;

	UPROPERTY(BlueprintReadOnly)
	bool bIsShooting = false;

	UPROPERTY(BlueprintReadOnly)
	bool bIsAiming = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFinalShot = false;

	// How fast the player is rotating, while aiming 
	UPROPERTY(BlueprintReadOnly)
	float AimRotationSpeed = 0.f;

	UPROPERTY(BlueprintReadOnly)
	float ShuffleRotation = 0.f;

	UPROPERTY(BlueprintReadOnly)
	bool bIsMoving = false;

	UPROPERTY(BlueprintReadOnly)
	FRotator LookAtRot;

	// Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{		
		if(OwningActor == nullptr)
			return;

		SniperWielderComp = UMatchWielderComponent::GetOrCreate(OwningActor);
		//MoveComp = UHazeMovementComponent::GetOrCreate(OwningActor);

		IKTarget = GetIkBoneOffset(IKReference,0.f,n"RightAttach",n"LeftHand");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

		bIsShooting = GetAnimBoolParam(n"SniperShoot",true);
		AimValues = SniperWielderComp.AimAngles;
		bIsAiming = SniperWielderComp.bAiming;
		ShuffleRotation = SniperWielderComp.ShuffleRotation;
		
		// change it so it matches leos animation
		ShuffleRotation = Math::NormalizeToRange(ShuffleRotation, 0.f, 360.f);
		ShuffleRotation = 1.f - ShuffleRotation;
		ShuffleRotation = ShuffleRotation * 12.f;

		//bIsMoving = MoveComp.GetVelocity().Size() <= 2;
		//PrintToScreenScaled("Ismoving: " + bIsMoving, Scale = 3.f);

		AimRotationSpeed = GetAnimFloatParam(n"AimRotationSpeed", true);

		LookAtRot = SniperWielderComp.LookAtRot.Value;
		
		bFinalShot = false;
		if(bIsShooting)
		{
			bFinalShot = SniperWielderComp.Charges <= 1.f;
		}
	}
	
}