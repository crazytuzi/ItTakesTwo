import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomPullBackCar;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarWindupCharacterAnimComponent;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;

class UPlayRoomPullBackCarAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeaturePlayRoomPullBackCar Feature;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    USceneComponent BounceRoot;

    UPROPERTY(BlueprintReadOnly, NotEditable)
    UPullbackCarWindupCharacterAnimComponent PullbackCarAnimComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeaturePlayRoomPullBackCar>(GetFeatureAsClass(ULocomotionFeaturePlayRoomPullBackCar::StaticClass()));

        InitializePullBackCar();

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (PullbackCarAnimComp == nullptr)
		{
			InitializePullBackCar();
			return;	
		}
            
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }


    	UFUNCTION()
	void InitializePullBackCar()
	{
		PullbackCarAnimComp = Cast<UPullbackCarWindupCharacterAnimComponent>(OwningActor.GetComponentByClass(UPullbackCarWindupCharacterAnimComponent::StaticClass()));
	    if (PullbackCarAnimComp == nullptr)
			return;
    	const APullbackCar PullbackCar = Cast<APullbackCar>(OwningActor.GetAttachParentActor());
		BounceRoot = PullbackCar.BounceRoot;
	}

}