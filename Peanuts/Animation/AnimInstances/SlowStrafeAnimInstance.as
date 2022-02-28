import Peanuts.Animation.Features.LocomotionFeatureSlowStrafe;
import Peanuts.Animation.Components.AnimationLookAtComponent;

class USlowStrafeAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSlowStrafe LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStructLookAtAnimationData LookAtData;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float TurnRate;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float WalkingAlpha;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float LookAtAlpha = 1.f;

	UAnimationLookAtComponent LookAtComp;
	FRotator ActorRotation;
	float InterpTime;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSlowStrafe>(GetFeatureAsClass(ULocomotionFeatureSlowStrafe::StaticClass()));
		LookAtComp = UAnimationLookAtComponent::Get(OwningActor);
		if (LookAtComp != nullptr)
		{
			if (!LocomotionFeature.bUseLookAt)
				return;
			LookAtData = LookAtComp.GetInitialLookAtAnimationData();
			LookAtData.bLookAtEnabled = false;
			System::SetTimer(this, n"EnableLookAt", 1.f, false);
		}
		LookAtAlpha = 1.f;
    }


    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LookAtComp == nullptr)
            return;


		// Turn in place
		const float WalkingAlphaTarget = FMath::Clamp(FVector2D(GetAnimFloatParam(n"SlowStrafeX"), GetAnimFloatParam(n"SlowStrafeY")).Size() / 300.f, 0.f, 1.f);
		float AlphaInterpTime = 10.f;
		if (WalkingAlphaTarget == 0)
		{
			
			if (TurnRate > .5f)
				AlphaInterpTime = 7.f;
			else
				AlphaInterpTime = 3.f;
		}
		
		WalkingAlpha = FMath::FInterpTo(WalkingAlpha, WalkingAlphaTarget, DeltaTime, AlphaInterpTime);

		

		TurnRate = -(ActorRotation - OwningActor.ActorRotation).Normalized.Yaw;
		TurnRate /= DeltaTime;
		TurnRate = FMath::Clamp(TurnRate/180.f, -1.f, 1.f);
		
		ActorRotation = OwningActor.ActorRotation;
		
		float LookAtAlphaTarget = 1;
		if (WalkingAlphaTarget < .1f && FMath::Abs(TurnRate) > .6f)
		{
			LookAtAlphaTarget = 0.1f;
		}
		LookAtAlpha = FMath::FInterpTo(LookAtAlpha, LookAtAlphaTarget, DeltaTime, 3.f);
		

		if (!LocomotionFeature.bUseLookAt)
			return;

		FStructLookAtAnimationData TargetData = LookAtComp.GetLookAtAnimationData();
		if (!LookAtComp.HasCustomLookAtLocation())
		{
			TargetData.LookAtLocation.Z -= 200;
			InterpTime = FMath::FInterpTo(InterpTime, 10.f, DeltaTime, 1.f);
		}
		else
		{
			InterpTime = 2.f;
		}

		LookAtData.LookAtLocation = FMath::VInterpTo(LookAtData.LookAtLocation, TargetData.LookAtLocation, DeltaTime, InterpTime);

    }

    UFUNCTION()
    void EnableLookAt()
    {
        LookAtData.bLookAtEnabled = true;
    }
	

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}