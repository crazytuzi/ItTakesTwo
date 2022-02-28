import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeHarpoon;
import Peanuts.Animation.AnimationStatics;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class USnowGlobeHarpoonPlayerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeHarpoon LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector AimValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FTransform LeftHandIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector RightHandIKLocation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator RightHandIKRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FTransform IKJointOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bFire;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bRelease;

	AMagnetHarpoonActor HarpoonActor;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform HandleTransforms;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSnowGlobeHarpoon>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeHarpoon::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;

		LeftHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKRef, 0, n"Align", n"LeftHand");

		RightHandIKLocation = GetIkBoneOffset(LocomotionFeature.IKRef, 0, n"RightHand_IK", n"RightHand").Location;
		RightHandIKRotation = GetIkBoneOffset(LocomotionFeature.IKRef, 0, n"RightHand_IK", n"RightHand").Rotator();

		IKJointOffset = GetIkBoneOffset(LocomotionFeature.IKRef, 0, n"RightFoot_IK", n"RightHand_IK");
		
		HarpoonActor = Cast<AMagnetHarpoonActor>(OwningActor.GetAttachParentActor());
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		AimValues = GetAnimVectorParam(n"HarpoonAimAngles", true);
		bFire = GetAnimBoolParam(n"HarpoonFired", true);
		bRelease = GetAnimBoolParam(n"FishReleased", true);

		HandleTransforms = HarpoonActor.HarpoonBaseSkel.GetSocketTransform(n"Handle");
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}