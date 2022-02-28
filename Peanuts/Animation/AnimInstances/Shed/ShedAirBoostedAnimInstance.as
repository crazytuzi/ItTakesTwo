import Peanuts.Animation.Features.Shed.LocomotionFeatureShedAirBoosted;
import Peanuts.Animation.AnimationStatics;

class UShedAirBoostedAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureShedAirBoosted LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSucking;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	float CustomBlendTime = 0.6f;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureShedAirBoosted>(GetFeatureAsClass(ULocomotionFeatureShedAirBoosted::StaticClass()));
		if (GetAnimBoolParam(n"Sucking", false))
			CustomBlendTime = 0.4f;
		else
			CustomBlendTime = 0.6f;

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
		if (LocomotionFeature == nullptr)
            return;

		bSucking = GetAnimBoolParam(n"Sucking", true);
		const FVector LocalVelocity = GetActorLocalVelocity(OwningActor);
		BlendspaceValues.X = FMath::Clamp(LocalVelocity.Y / 100.f, -1.f, 1.f);
		BlendspaceValues.Y = FMath::Clamp(LocalVelocity.X / 100.f, -1.f, 1.f);
    }

    // Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}