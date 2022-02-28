import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimmingSurface;

class USnowGlobeSwimmingSurfaceAnimInstance : USwimmingAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeSwimmingSurface SwimmingSurfaceFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDive;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	const FName DiveSubTag = n"Dive";

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		// Valid check the swimming comp
		if (SwimmingComp == nullptr)
			return;
        
        SwimmingSurfaceFeature = Cast<ULocomotionFeatureSnowGlobeSwimmingSurface>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimmingSurface::StaticClass()));
		HipsPitchInterpSpeed = 999.f;
		SetSwimmingBlendTime(.55f);
		bCalculateHipsRotation = false;
		bDive = false;

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the swimming comp
		if (SwimmingComp == nullptr)
            return;
		Super::BlueprintUpdateAnimation(DeltaTime);
		CalculateHorizontalRotationRate(DeltaTime);
		
	
		BlendspaceValues.Y = FMath::Clamp(OwningActor.ActorVelocity.Size(), 0.f, 500.f);
		BlendspaceValues.X = RotationRate.X;

		const FName SubTag = GetLocomotionSubAnimationTag();
		if (SubTag == DiveSubTag)
		{
			bDive = true;
			bCalculateHipsRotation = true;
		}
		else if (SubTag != DiveSubTag && GetLocomotionAnimationTag() == n"SwimmingSurface")
		{
			bDive = false;
			bCalculateHipsRotation = false;
		}

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		if (bDive) {
			return (GetTopLevelGraphRelevantAnimTimeRemaining() < 0.1f);
		}
        return true;
    }

}