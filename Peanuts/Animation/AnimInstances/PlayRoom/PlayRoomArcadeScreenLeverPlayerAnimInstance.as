import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureArcadeScreenLever;
import Peanuts.Animation.AnimationStatics;

class UPlayRoomArcadeScreenLeverPlayerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureArcadeScreenLever LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform LeftHandIKOfsset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform RightHandIKOfsset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform IKTriggerHandOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUseTrigger;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRightHandOnTrigger;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayTriggerAnimation;



    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureArcadeScreenLever>(GetFeatureAsClass(ULocomotionFeatureArcadeScreenLever::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;
		
		LeftHandIKOfsset = GetIkBoneOffset(LocomotionFeature.IKReferencePose, 0.f, n"LeftHand_IK", n"LeftHand");
		RightHandIKOfsset = GetIkBoneOffset(LocomotionFeature.IKReferencePose, 0.f, n"RightHand_IK", n"RightHand");

		bRightHandOnTrigger = (OwningActor == Game::GetCody());
		if (bRightHandOnTrigger)
			IKTriggerHandOffset = GetIkBoneOffset(LocomotionFeature.IKReferencePose, 0.f, n"LeftHand_IK", n"RightHand_IK");
		else
			IKTriggerHandOffset = GetIkBoneOffset(LocomotionFeature.IKReferencePose, 0.f, n"RightHand_IK", n"LeftHand_IK");

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		BlendspaceValues.X = FMath::FInterpTo(BlendspaceValues.X, GetAnimFloatParam(n"JoystickInputX", true), DeltaTime, 5.f);
		BlendspaceValues.Y = FMath::FInterpTo(BlendspaceValues.Y, GetAnimFloatParam(n"JoystickInputY", true), DeltaTime, 5.f);

		bUseTrigger = GetAnimBoolParam(n"JoystickTrigger", true);
		if (bUseTrigger)
			bPlayTriggerAnimation = true;

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

	UFUNCTION()
	void StopPlayingTriggerAnimation()
	{
		bPlayTriggerAnimation = false;
	}

}