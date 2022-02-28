import Peanuts.Animation.Features.LocomotionFeatureGrindButton;
import Vino.Movement.Grinding.GrindingInteractionRegion;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.MovementSystemTags;

class UGrindButtonAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureGrindButton LocomotionFeature;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator RootRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTriggerButtonHit;

	UUserGrindComponent GrindingComponent;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureGrindButton>(GetFeatureAsClass(ULocomotionFeatureGrindButton::StaticClass()));
		GrindingComponent = UUserGrindComponent::Get(OwningActor);
		

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (GrindingComponent == nullptr)
            return;

		RootRotation = Math::MakeRotFromXZ(GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldForwardVector, GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldUpVector);

		bTriggerButtonHit = GetAnimBoolParam(GrindInteractAnim::TriggerButtonHit, true);
		const float DistanceToButton = GetAnimFloatParam(GrindInteractAnim::DistanceToButton, true);
		if (DistanceToButton < LocomotionFeature.TriggerDistance)
			bTriggerButtonHit = true;
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		if (LocomotionAnimationTag != n"Grind")
			return true;

        return (TopLevelGraphRelevantAnimTimeRemaining < 0.1f && TopLevelGraphRelevantStateName == n"PressBtn");
    }

}