import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;


class USwimmingAnimInstance : UHazeFeatureSubAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSwimmingForward;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator SwimmingHipsRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ESwimmingSpeedState SwimmingSpeedState;

	USnowGlobeSwimmingComponent SwimmingComp;
	FRotator ActorRotation;
	
	bool bCalculateHipsRotation = true;
	bool bInputAffectsInterpSpeed = true;
	float HipsPitchInterpSpeed = 5.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VerticalInputDir;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
			return;

		
		SwimmingComp = Cast<USnowGlobeSwimmingComponent>(OwningActor.GetComponent(USnowGlobeSwimmingComponent::StaticClass()));
		SwimmingHipsRotation = FRotator(GetAnimFloatParam(n"SwimmingPitchRotation", true), 0.f, 0.f);
		ActorRotation = OwningActor.ActorRotation;
		
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParamConst(n"SwimmingBlendTime", 0.4f);
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			return;

		bIsSwimmingForward = SwimmingComp.bIsSwimmingForward;
		SwimmingSpeedState = SwimmingComp.SwimmingSpeedState;
		VerticalInputDir = SwimmingComp.VerticalScale;
		if (bCalculateHipsRotation)
			CalculateHipsRotationValue(DeltaTime);
	
	}

	// On Transition From
	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		SetAnimFloatParam(n"SwimmingPitchRotation", SwimmingHipsRotation.Pitch);
	}



	// Swimming Hips rotation (Pitch)
	UFUNCTION()
	void CalculateHipsRotationValue(float DeltaTime)
	{
		float NewRotationValue;
		FVector Velocity = OwningActor.ActorVelocity;

		if (!CharacterHasInput() && bInputAffectsInterpSpeed)
		{	
			NewRotationValue = FMath::FInterpTo(SwimmingHipsRotation.Pitch, 0.f, DeltaTime, (HipsPitchInterpSpeed / 6.f));
		}
		else if (!bIsSwimmingForward && bInputAffectsInterpSpeed)
		{
			NewRotationValue = FMath::FInterpTo(SwimmingHipsRotation.Pitch, Velocity.Rotation().Pitch, DeltaTime, HipsPitchInterpSpeed / 3.f);
		}
		else
		{
			NewRotationValue = FMath::FInterpTo(SwimmingHipsRotation.Pitch, Velocity.Rotation().Pitch, DeltaTime, HipsPitchInterpSpeed);
		}

		if (DeltaTime != 0.f)
			RotationRate.Y = FMath::Clamp((NewRotationValue - SwimmingHipsRotation.Pitch) / DeltaTime, -150.f, 150.f);
		SwimmingHipsRotation.Pitch = NewRotationValue;
	}

	
	UFUNCTION()
	void CalculateHorizontalRotationRate(float DeltaTime)
	{
		RotationRate.X = (OwningActor.ActorRotation - ActorRotation).Normalized.Yaw;
		RotationRate.X /= DeltaTime;
		ActorRotation = OwningActor.ActorRotation;
	}

	UFUNCTION(BlueprintPure)
	bool CharacterHasInput() const 
	{
		return (bIsSwimmingForward || VerticalInputDir != 0.f);
	}

	UFUNCTION()
	void SetSwimmingBlendTime(float Time)
	{
		SetAnimFloatParam(n"SwimmingBlendTime", Time);
	}

}