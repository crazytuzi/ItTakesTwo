import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimmingDash;

class USwimmingDashAnimInstance : USwimmingAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureSnowGlobeSwimmingDash SwimmingDashFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSwimmingFast;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ExplicitDashTime;

	UPROPERTY()
	bool bForceExit;

	FName PreviousTopLevelGraphRelevantStateName;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		if (SwimmingComp == nullptr)
			return;

		SwimmingDashFeature = Cast<ULocomotionFeatureSnowGlobeSwimmingDash>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimmingDash::StaticClass()));
		SetSwimmingBlendTime(.15f);
		bForceExit = false;
		bInputAffectsInterpSpeed = false;
		ExplicitDashTime = 0.f;

	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.06f;
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			return;
		Super::BlueprintUpdateAnimation(DeltaTime);

		bSwimmingFast = SwimmingSpeedState == ESwimmingSpeedState::Fast;
		if (TopLevelGraphRelevantStateName == n"Dash")
		{
			ExplicitDashTime += DeltaTime;
		}

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom()
	{
		if (GetLocomotionAnimationTag() != n"Swimming")
			return true;

		if (bForceExit)
			return true;

		if (GetTopLevelGraphRelevantAnimTimeRemaining() <= 0.1f)
		{
			if (!(bIsSwimmingForward || VerticalInputDir != 0.f))
				SetSwimmingBlendTime(.5f);
			return true; 
		}

		return false;
		
	}

	// On Transition From
	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		Super::OnTransitionFrom(NewSubAnimInstance);
		if (GetLocomotionAnimationTag() == n"SwimmingBreach")
		{
			const float TimeRemainingRatio = (GetTopLevelGraphRelevantAnimTimeRemaining() / SwimmingDashFeature.Dash.Sequence.SequenceLength);
			SetAnimFloatParam(n"DashAnimTimeRemaining", TimeRemainingRatio);
			SetAnimBoolParam(n"BreachFromDash", true);
		}
	}

	UFUNCTION()
	void ResetExplicitDashTime()
	{
		ExplicitDashTime = 0.f;
	}

}