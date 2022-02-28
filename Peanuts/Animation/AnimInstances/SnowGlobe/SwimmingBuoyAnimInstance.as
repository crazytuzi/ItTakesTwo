import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSwimmingBuoy;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticBuoyComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

enum EHazeSwimmingBuoyExitTypes {
	None,
	ExitPastBuoy,
	ExitToMh,
	ExitToNormal,
	ExitToSwimFast,
	ExitToCruise,
};

class USwimmingBuoyAnimInstance : USwimmingAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRequestingThisSubABP;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureSwimmingBuoy SwimmingBuoyFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector BuoyDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeSwimmingBuoyExitTypes ExitAnimation;

	bool bHasPickedExit;
	UMagneticPlayerComponent MagneticComp;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		if (SwimmingComp == nullptr)
			return;

		SwimmingBuoyFeature = Cast<ULocomotionFeatureSwimmingBuoy>(GetFeatureAsClass(ULocomotionFeatureSwimmingBuoy::StaticClass()));
		MagneticComp = Cast<UMagneticPlayerComponent>(OwningActor.GetComponentByClass(UMagneticPlayerComponent::StaticClass()));
		bInputAffectsInterpSpeed = false;
		ExitAnimation = EHazeSwimmingBuoyExitTypes::None;
		
		bHasPickedExit = false;
		
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.08f;
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			return;
		Super::BlueprintUpdateAnimation(DeltaTime);

		bRequestingThisSubABP = (GetLocomotionAnimationTag() == n"SwimmingBuoy");

		// Get the direction to the Buoy from the actor
		const UHazeActivationPoint ActivationPoint = MagneticComp.GetActivatedMagnet();
		if (ActivationPoint != nullptr)
		{
			BuoyDirection = OwningActor.ActorRotation.UnrotateVector(OwningActor.ActorLocation - ActivationPoint.GetWorldLocation());
			BuoyDirection.Normalize();
			BuoyDirection.Y *= -1.f;
		}


	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom()
	{
		if (GetAnimBoolParam(n"PlayerSwamPastBuoy", true))
		{
			ExitAnimation = EHazeSwimmingBuoyExitTypes::ExitPastBuoy;
			SetSwimmingBlendTime(0.4f);
			bHasPickedExit = true;
			return false;
		}

		if (!bHasPickedExit)
		{
			SetSwimmingBlendTime(0.1f);
			if (ExitAnimation != EHazeSwimmingBuoyExitTypes::None)
				bHasPickedExit = true;

			if (!bIsSwimmingForward && VerticalInputDir == 0.f)
				ExitAnimation = EHazeSwimmingBuoyExitTypes::ExitToMh;

			else if (SwimmingSpeedState == ESwimmingSpeedState::Normal)
				ExitAnimation = EHazeSwimmingBuoyExitTypes::ExitToNormal;
			
			else if (SwimmingSpeedState == ESwimmingSpeedState::Fast)
				ExitAnimation = EHazeSwimmingBuoyExitTypes::ExitToSwimFast;

			else if (SwimmingSpeedState == ESwimmingSpeedState::Cruise)
			{
				ExitAnimation = EHazeSwimmingBuoyExitTypes::ExitToCruise;
				SetSwimmingBlendTime(0.25f);
			}
			
		}

		if (ExitAnimation == EHazeSwimmingBuoyExitTypes::ExitToMh && (bIsSwimmingForward || VerticalInputDir != 0.f))
		{
			SetSwimmingBlendTime(0.3f);
			return true;
		}

		if (GetLocomotionAnimationTag() != n"Swimming")
			return true;

		return (GetTopLevelGraphRelevantAnimTimeRemaining() <= 0.1f && GetTopLevelGraphRelevantStateName() == n"Exit");
	}

}