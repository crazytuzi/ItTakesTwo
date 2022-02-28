import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSkiLift;

class USnowGlobeSkiLiftAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeSkiLift LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ReadyAmount;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bExit;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSnowGlobeSkiLift>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSkiLift::StaticClass()));

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		ReadyAmount = GetAnimFloatParam(n"ReadyAmount", true);
		bExit = GetAnimBoolParam(n"ExitSkiLift", true);

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		return (LocomotionAnimationTag != n"No Request Made");
    }

}