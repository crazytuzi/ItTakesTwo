import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimmingDolphinDive;
import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.AnimationStatics;

class USnowGlobeSwimmingBreachAnimInstance : USwimmingAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeSwimmingBreach BreachFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float EnterFromDashStartPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float BlendspaceValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ESwimmingBreachEnterTypes EnterType;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ESwimmingBreachExitType ExitType;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayExitAnimation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDiveFast;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsFreestyling;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FreeStyleXRotation;

	UPROPERTY()
	bool bIsRotatingForward = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAllowTransitionFromGroundToBreach;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUseCustomDiveAnim;


	FVector ActorVelocity;
	
    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        BreachFeature = Cast<ULocomotionFeatureSnowGlobeSwimmingBreach>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimmingBreach::StaticClass()));
		if (BreachFeature == nullptr)
			return;
		
		SetSwimmingBlendTime(0.5f);

		// Set default values
		bIsRotatingForward = true;
		bPlayExitAnimation = false;
		bDiveFast = false;
		FreeStyleXRotation = 0.f;
		ExitType = ESwimmingBreachExitType::Dive;

		// Parent variables
		bCalculateHipsRotation = false;
		bInputAffectsInterpSpeed = false;
		HipsPitchInterpSpeed = 10.f;


		// Get enter type
		const FName PreviousLocomotionTag = GetPreviousAnimationUpdateParams().LocomotionTag;

		if (GetAnimBoolParam(n"BreachFromDash", true))
		{
			EnterFromDashStartPosition = (1.f - GetAnimFloatParam(n"DashAnimTimeRemaining", true)) * BreachFeature.MaxedAllowedDashDashStartPosition;
			EnterType = ESwimmingBreachEnterTypes::SwimmingBoost;
		}
		else if (PreviousLocomotionTag == n"Jump" || PreviousLocomotionTag == n"SkateInAir")
		{
			EnterType = ESwimmingBreachEnterTypes::Ground;
			if (Animation::IsSequencePlayerDataValid(BreachFeature.ExitToSwimmingFromGroundDive))
				ExitType = ESwimmingBreachExitType::GroundDive;
			SwimmingHipsRotation = FRotator::ZeroRotator;
			bAllowTransitionFromGroundToBreach = BreachFeature.bAllowTransitionFromGroundToBreach;
		}
		else if (PreviousLocomotionTag == n"DoubleJump")
		{
			EnterType = ESwimmingBreachEnterTypes::DoubleJump;
		} 
		else 
		{
			EnterType = ESwimmingBreachEnterTypes::None;
		}


		bSkipEnter = GetAnimBoolParam(n"SkipDiveEnter", true);
		if (bSkipEnter)
		{
			SwimmingHipsRotation.Pitch = -70.f;
			bUseCustomDiveAnim = Animation::IsSequencePlayerDataValid(BreachFeature.CustomDiveFromGround);
		}
		else
		{
			bUseCustomDiveAnim = false;
		}



    }

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bSkipEnter)
			return 0.6f;
		else if (EnterType == ESwimmingBreachEnterTypes::SwimmingBoost)
			return 0.f;
		else if (EnterType == ESwimmingBreachEnterTypes::Ground)
			return 0.2f;
		else if (EnterType == ESwimmingBreachEnterTypes::DoubleJump)
			return 0.6f;
		else
			return 0.4f;
	}

    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (SwimmingComp == nullptr)
            return;

		// Call the parent class
		Super::BlueprintUpdateAnimation(DeltaTime);

		ActorVelocity = OwningActor.GetActorVelocity();//GetActorActorVelocity(OwningActor);
		Speed = ActorVelocity.Size();
		BlendspaceValue = ActorVelocity.Z;
		
		// Check if player requests a fast dive
		if (GetAnimBoolParam(n"BreachDive", true))
		{
			bDiveFast = true;

			// Get the type of fast dive
			if (ActorVelocity.Z < 0)
				ExitType = ESwimmingBreachExitType::DiveFast;
			else if (bIsRotatingForward)
				ExitType = ESwimmingBreachExitType::Dive;
			else
				ExitType = ESwimmingBreachExitType::DiveBackflip;
		}

		bIsFreestyling = false;
		if (GetAnimBoolParam(n"FreestyleActive") && !bDiveFast && !bPlayExitAnimation)
		{
			const float FreeStyleInput = GetAnimFloatParam(n"FreestyleX", true);
			if (FMath::Abs(FreeStyleInput) > 0.2f)
			{
				HipsPitchInterpSpeed = 4.f;
				bIsFreestyling = true;
				bIsRotatingForward = (FreeStyleInput > 0.f);
				const float FreestyleRotationRate = bIsRotatingForward ? BreachFeature.FrontFlipRotationRate : BreachFeature.BackFlipRotationRate;
				FreeStyleXRotation = Math::FWrap(FreeStyleXRotation - ((FreeStyleInput * FreestyleRotationRate) * DeltaTime), 0.f, 360.f);
				return;
			}
			
		}
		else if (FreeStyleXRotation != 0.f)
		{
			// Interp back to 0
			const float InterpSpeed = bPlayExitAnimation ? 10.f : 3.f;

			float InterpTarget;
			if (bIsRotatingForward)
			{
				InterpTarget = (FreeStyleXRotation > 300.f) ? 360.f : 0.f;
			}
			else 
			{
				InterpTarget = (FreeStyleXRotation > 20.f) ? 360.f : 0.f;
			}

			FreeStyleXRotation = FMath::FInterpTo(FreeStyleXRotation, InterpTarget, DeltaTime, InterpSpeed);
		}


		
		// Calculate the hips rotation
		if (bDiveFast)
			SwimmingHipsRotation.Pitch = FMath::FInterpTo(SwimmingHipsRotation.Pitch, -45.f, DeltaTime, 3.f);
		else
			CalculateHipsRotationValue(DeltaTime);

		

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {

		// Play the exit animation
		if (!bPlayExitAnimation)
		{
			bPlayExitAnimation = true;
			return (LocomotionAnimationTag != n"Swimming");
		}

		if (TopLevelGraphRelevantStateName == n"ExitToSwimMh")
		{

			if (CharacterHasInput())
			{
				// If char is playing exit to Mh but starts to move, cancel the exit animation
				SetSwimmingBlendTime(0.6f);
				return true;
			}
		}

        return (LocomotionAnimationTag != n"Swimming") || (TopLevelGraphRelevantAnimTimeRemaining < 0.2f);
    }

}