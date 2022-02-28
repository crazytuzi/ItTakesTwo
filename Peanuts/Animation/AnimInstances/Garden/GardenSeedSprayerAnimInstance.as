import Peanuts.Animation.AnimationStatics;

class UGardenSeedSprayerAnimInstance : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Exit;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bExit;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		const FVector LocalVelocity = OwningActor.GetActorLocalVelocity();
		Speed = LocalVelocity.Size();
		BlendspaceValues.X = FMath::Clamp(LocalVelocity.Y / 850.f, -1.f, 1.f);
		BlendspaceValues.Y = FMath::FInterpTo(BlendspaceValues.Y, FMath::Clamp(LocalVelocity.X / 850.f, -1.f, 1.f), DeltaTime, 3.f);
		bExit = GetAnimBoolParam(n"PlayExit", true);
    }

    

}