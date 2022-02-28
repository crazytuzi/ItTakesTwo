import Vino.StickControlledLever.StickControlledLever;
import Peanuts.Animation.AnimationStatics;

class UStickControlledLeverAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    UStickControlledLeverFeature LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float LeverPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float LeverDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator HandRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform LeftHandIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform RightHandIKOffset;

	float LeverDirectionHandRotation;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
		LocomotionFeature = Cast<UStickControlledLeverFeature>(GetFeatureAsClass(UStickControlledLeverFeature::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;
		RightHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKReference, 0.f, n"Align", n"RightHand");
		LeftHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKReference, 0.f, n"Align", n"LeftHand");

		SetAnimFloatParam(AnimationFloats::BlendToMovement, 0.2f);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		LeverPosition = GetAnimFloatParam(n"LeverPosition", true);
		LeverPosition = 1.f - (LeverPosition * 2.f);

		LeverDirection = GetAnimFloatParam(n"LeverDirection", true) * -2.f;
		LeverDirectionHandRotation = FMath::FInterpTo(LeverDirectionHandRotation, LeverDirection, DeltaTime, 10.f);
		
		HandRotation.Yaw = LeverPosition * 40.f + (LeverDirectionHandRotation * 20.f);

    }

}