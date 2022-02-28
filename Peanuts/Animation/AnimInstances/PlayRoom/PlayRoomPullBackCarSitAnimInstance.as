import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomPullBackCarSit;

class UPlayRoomPullBackCarSitAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeaturePlayRoomPullBackCarSit LocomotionFeature;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeaturePlayRoomPullBackCarSit>(GetFeatureAsClass(ULocomotionFeaturePlayRoomPullBackCarSit::StaticClass()));

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}