import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomHoldingUFO;

class UPlayRoomHoldingUFOAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeaturePlayRoomHoldingUFO LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ButtonMashAmount;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeaturePlayRoomHoldingUFO>(GetFeatureAsClass(ULocomotionFeaturePlayRoomHoldingUFO::StaticClass()));

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		ButtonMashAmount = GetAnimFloatParam(n"ButtonMashAmount", true);

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}