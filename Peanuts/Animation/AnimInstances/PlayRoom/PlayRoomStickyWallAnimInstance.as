import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureStickyWall;

class UPlayRoomStickyWallAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureStickyWall LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float BlendspaceValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPlayExit;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureStickyWall>(GetFeatureAsClass(ULocomotionFeatureStickyWall::StaticClass()));
		bPlayExit = false;
    }
    

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		BlendspaceValue = GetAnimFloatParam(n"StruggleAmount", true);
		
    }

    // Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		bPlayExit = true;
		if (LocomotionAnimationTag != FeatureName::AirMovement)
			return true;
        return TopLevelGraphRelevantStateName == n"Exit" && TopLevelGraphRelevantAnimTimeRemaining < 0.1;
    }

}