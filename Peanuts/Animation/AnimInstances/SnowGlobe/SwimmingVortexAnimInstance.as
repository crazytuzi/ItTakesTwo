import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimmingVortex;


class USwimmingVortexAnimInstance : USwimmingAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureSnowGlobeSwimmingVortex SwimmingVortexFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayAnticipation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayDash;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayEnter;

	bool bDoOnce = true;

	default BlendTime = 0.8f;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		if (SwimmingComp == nullptr)
			return;

		SwimmingVortexFeature = Cast<ULocomotionFeatureSnowGlobeSwimmingVortex>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimmingVortex::StaticClass()));
		bDoOnce = true;
		bCalculateHipsRotation = false;
		bPlayEnter = false;

		const FName PreviousLocomotionTag = GetPreviousAnimationUpdateParams().LocomotionTag;
		if (PreviousLocomotionTag == n"SwimmingBreach")
			bPlayEnter = true;

		
		
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			return;
		Super::BlueprintUpdateAnimation(DeltaTime);

		bPlayAnticipation = (GetLocomotionSubAnimationTag() == n"Anticipation");
		bPlayDash = (GetLocomotionAnimationTag() == n"SwimmingBreach");
		if (bPlayDash)
		{
			if (bDoOnce)
			{
				SwimmingHipsRotation = FRotator(10.f, 0.f, 0.f);
				bCalculateHipsRotation = true;
				bPlayEnter = true;
				bDoOnce = false;
			}
		}
		else
		{
			CalculateHorizontalRotationRate(DeltaTime);
		}
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom()
	{
		return (GetLocomotionAnimationTag() != n"SwimmingBreach" || GetTopLevelGraphRelevantStateName() == n"Exit");
	}

}