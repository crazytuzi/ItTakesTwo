import Peanuts.Animation.Features.LocomotionFeatureGrindTransfer;
import Peanuts.Animation.AnimationStatics;
import Vino.Movement.Grinding.UserGrindComponent;

class UGrindTransferAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureGrindTransfer LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator RootRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bIsJumpingRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bLanded;

	UUserGrindComponent GrindingComponent;
	bool bReInitialize;
	bool bUpsideDownTransfer; 

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureGrindTransfer>(GetFeatureAsClass(ULocomotionFeatureGrindTransfer::StaticClass()));
		GrindingComponent = Cast<UUserGrindComponent>(OwningActor.GetComponentByClass(UUserGrindComponent::StaticClass()));
		if (GrindingComponent == nullptr)
			return;

		bIsJumpingRight = IsPlayerJumpingRight();
		const FVector RootRotationAnimVector = GetAnimVectorParam(n"RootRotation", true);
		RootRotation = FRotator(RootRotationAnimVector.X, RootRotationAnimVector.Y, RootRotationAnimVector.Z);

		const FRotator RootDeltaRotation = (RootRotation - OwningActor.ActorRotation).Normalized;
		bUpsideDownTransfer = FMath::Abs(RootDeltaRotation.Roll) > 100.f;

		bReInitialize = false;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (GrindingComponent == nullptr)
            return;

		// Re-Init ABP
		if (LocomotionAnimationTag == "GrindTransfer" && PreviousAnimationUpdateParams.LocomotionTag == "Grind" && bReInitialize)
		{
			SetAnimVectorParam(n"RootRotation", FVector(RootRotation.Pitch, RootRotation.Yaw, RootRotation.Roll));
			BlueprintInitializeAnimation();
		}
			
		bReInitialize = true;

		bLanded = LocomotionAnimationTag == n"Grind";

		FRotator WantedRootRotation;
		if (bLanded)
		{
			WantedRootRotation = Math::MakeRotFromXZ(GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldForwardVector, GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldUpVector);			
		}
		else
		{
			WantedRootRotation = Math::MakeRotFromXZ(GrindingComponent.TargetGrindSplineData.SystemPosition.WorldForwardVector, GrindingComponent.TargetGrindSplineData.SystemPosition.WorldUpVector);
		}


		float InterpSpeed = bLanded ? 7.f : 5.f;
		if (bUpsideDownTransfer)
			InterpSpeed = bLanded ? 7.f : 0.1f;
		RootRotation = FMath::RInterpTo(RootRotation, WantedRootRotation, DeltaTime, InterpSpeed);

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        if (LocomotionAnimationTag != "Grind")
			return true;
		
		else if (LocomotionSubAnimationTag != "None")
			return true;

		return (TopLevelGraphRelevantStateName == "Landing" && TopLevelGraphRelevantAnimTimeRemaining < 0.1f);
    }

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Grind")
		{
			SetAnimBoolParam(n"SkipGrindEnter", true);
			if (LocomotionSubAnimationTag != n"None")
			{
				SetAnimFloatParam(n"BlendToGrind", 0.f);
			}
		}
	}

	UFUNCTION()
	bool IsPlayerJumpingRight()
	{
		const FVector TargetDeltaLocation = OwningActor.ActorRotation.UnrotateVector(GrindingComponent.TargetGrindSplineData.SystemPosition.WorldLocation - OwningActor.ActorLocation);
		return TargetDeltaLocation.Y > 0.f;
	}

}