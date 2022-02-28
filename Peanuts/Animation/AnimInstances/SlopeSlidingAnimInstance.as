import Peanuts.Animation.Features.LocomotionFeatureInSlopeSliding;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Peanuts.Animation.Features.LocomotionFeatureInSlopeSlidingAim;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Cake.Weapons.Match.MatchWielderComponent;

class USlopeSlidingAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSlopeSliding LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeAnimationSlopeSlidingEnterType EnterType;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeAnimationSlopeSlidingExitType ExitType;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayEnter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator RootRotation;


	float CustomBlendTime;
	UCharacterSlidingComponent SlidingComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureSlopeSliding>(GetFeatureAsClass(ULocomotionFeatureSlopeSliding::StaticClass()));
		SlidingComp = UCharacterSlidingComponent::Get(OwningActor);
		if (SlidingComp == nullptr)
			return;

		bPlayExit = false;
		bPlayEnter = !GetAnimBoolParam(n"SlopeSlidingSkipEnter", true);
		if (!bPlayEnter)
			CustomBlendTime = 0.25f;

		SetAnimFloatParam(n"BlendToMovement", 0.f);
		SetAnimBoolParam(n"GoToStop", false);

		// Consume the hitreaction boolean
		SetAnimBoolParam(n"HitReaction", false);
		bPlayHitReaction = false;

		RootRotation = FRotator::ZeroRotator;
		
    }

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return CustomBlendTime;
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (SlidingComp == nullptr)
            return;

		BlendspaceValues = SlidingComp.BlendSpaceValues;

		if (bPlayExit)
		{
			if (LocomotionAnimationTag == FeatureName::SlopeSliding)
				bPlayExit = false;
		}

		bPlayHitReaction = GetAnimBoolParam(n"HitReaction", true);

		// Calculate root rotation
		FVector Right = SlidingComp.SlopeNormal.CrossProduct(OwningActor.ActorForwardVector);
		FVector SlopedForward = Right.CrossProduct(SlidingComp.SlopeNormal);
		RootRotation = FMath::RInterpTo(RootRotation, FRotator::MakeFromXZ(SlopedForward, SlidingComp.SlopeNormal), DeltaTime, 3.f);
		RootRotation.Yaw = 0.f;
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		if (LocomotionAnimationTag != FeatureName::Movement && LocomotionAnimationTag != FeatureName::Jump && LocomotionAnimationTag != FeatureName::AirMovement)
			return true;

		if (!bPlayExit)
		{
			bPlayExit = true;

			// Pick an exit type
			if (LocomotionAnimationTag == FeatureName::Movement)
				ExitType = EHazeAnimationSlopeSlidingExitType::Movement;

			else if (LocomotionAnimationTag == FeatureName::Jump)
				ExitType = EHazeAnimationSlopeSlidingExitType::Jump;

			else if (LocomotionAnimationTag == FeatureName::AirMovement)
				ExitType = EHazeAnimationSlopeSlidingExitType::SlideOfEdge;

			else
				return true;

			return false;
		}

		if (LocomotionFeature.bPlayerHasWeapons)
		{
			if (OwningActor == Game::GetCody())
			{
				if (USapWeaponWielderComponent::Get(OwningActor).bIsAiming)
					return true;
			}
			else
			{
				if (UMatchWielderComponent::Get(OwningActor).bAiming)
					return true;
			}
		}

        return (TopLevelGraphRelevantStateName == n"Exit" || TopLevelGraphRelevantStateName == n"HitReactionAir") && TopLevelGraphRelevantAnimTimeRemaining <= 0.0f;
    }


	UFUNCTION()
	void SetEnterAnimation(EHazeAnimationSlopeSlidingEnterType EnterAnim, float EnterBlendTime)
	{
		EnterType = EnterAnim;
		CustomBlendTime = EnterBlendTime;
	}

}