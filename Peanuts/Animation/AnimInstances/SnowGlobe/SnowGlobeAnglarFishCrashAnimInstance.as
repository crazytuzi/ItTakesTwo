import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimmingTumble;

class USwimmingTumbleAnimInstance : USwimmingAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeSwimmingTumble LocomotionFeature;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		if (OwningActor == nullptr)
			return;

        LocomotionFeature = Cast<ULocomotionFeatureSnowGlobeSwimmingTumble>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimmingTumble::StaticClass()));
		bCalculateHipsRotation = false;
		SetSwimmingBlendTime(0.2f);
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LocomotionFeature == nullptr)
            return;
		Super::BlueprintUpdateAnimation(DeltaTime);


    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		return (LocomotionAnimationTag != FeatureName::AirMovement);
    }

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewAnimInstance)
	{
		SetSwimmingBlendTime(1.f);
	}

}