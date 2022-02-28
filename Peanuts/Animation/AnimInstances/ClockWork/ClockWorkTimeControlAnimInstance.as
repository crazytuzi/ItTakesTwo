import Peanuts.Animation.Features.ClockWork.LocomotionFeatureTimeControl;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;

class UClockWorkTimeControlAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureTimeControl LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float TurnProgress;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsTimeScrubbing;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float Angle;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float TurnRate;

	UTimeControlComponent TimeControlComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureTimeControl>(GetFeatureAsClass(ULocomotionFeatureTimeControl::StaticClass()));
		TimeControlComp = UTimeControlComponent::Get(OwningActor);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (TimeControlComp == nullptr)
            return;

		bIsTimeScrubbing = TimeControlComp.IsActiveTimeControlMoving();
		if (bIsTimeScrubbing)
		{
			TurnProgress = Math::FWrap(TimeControlComp.GetActiveTimeControlProgress() / TimeControlComp.GetLockedOnComponent().TimeStepMultiplier, 0.f, 1.f);
			if (DeltaTime != 0)
				TurnRate = GetAnimationUpdateParams().YawAngleSpeed / DeltaTime;
		}
		Angle = TimeControlComp.GetPitchAngleTowardsActiveTimeControl();
		

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}