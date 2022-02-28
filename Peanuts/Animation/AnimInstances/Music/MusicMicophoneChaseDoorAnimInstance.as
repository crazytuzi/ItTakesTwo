import Peanuts.Animation.Features.Music.LocomotionFeatureMusicMicrophoneChaseDoor;
import Peanuts.Animation.AnimationStatics;

class UMusicMicophoneChaseDoorAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureMusicMicrophoneChaseDoor LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bTakeStep;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bBeginPush;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureMusicMicrophoneChaseDoor>(GetFeatureAsClass(ULocomotionFeatureMusicMicrophoneChaseDoor::StaticClass()));
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		bBeginPush =  GetAnimBoolParam(n"IsButtonMashing", true);
		bTakeStep = GetAnimBoolParam(n"PushDoor", true);
		
    }

}