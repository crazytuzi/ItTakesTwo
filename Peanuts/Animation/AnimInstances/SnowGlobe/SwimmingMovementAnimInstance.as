import Peanuts.Animation.AnimInstances.SnowGlobe.SwimmingAnimInstance;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSwimming;
import Peanuts.Animation.AnimationStatics;

class USwimmingMovementAnimInstance : USwimmingAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureSnowGlobeSwimming SwimmingFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCanDoNiceTransition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCharacterHasInput;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		if (SwimmingComp == nullptr)
			return;

		SwimmingFeature = Cast<ULocomotionFeatureSnowGlobeSwimming>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeSwimming::StaticClass()));

		LocalVelocity = GetActorLocalVelocity(OwningActor);
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			return;
		Super::BlueprintUpdateAnimation(DeltaTime);
		CalculateHorizontalRotationRate(DeltaTime);

		bCanDoNiceTransition = GetAnimBoolParam(n"AllowTransition", false);
		bCharacterHasInput = CharacterHasInput();

	}

}