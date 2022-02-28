import Peanuts.Animation.AnimationStatics;

class UGardenDandelionAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator BaseRotation;

    UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayingEnter = true;

	bool bAllowToLeaveLaunchState = false;

	float RotationSpeed = 100.f;
	const float InitialRotationSpeed = 700.f;
	const float TargetRotationSpeed = 100.f;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
            return;

		bPlayingEnter = true;
		bAllowToLeaveLaunchState = true;
		BaseRotation.Yaw = 0.f;

		RotationSpeed = InitialRotationSpeed;
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		if (bPlayingEnter)
		{
			if (!bAllowToLeaveLaunchState)
				return;
			bPlayingEnter = (GetTopLevelGraphRelevantAnimTimeRemaining() > 0.1f);
			if (!bPlayingEnter)
				bAllowToLeaveLaunchState = false;
		}
		else
		{
			const FVector LocalVelocity = OwningActor.GetActorLocalVelocity();
			BlendspaceValues.X = LocalVelocity.Y;
			BlendspaceValues.Y = LocalVelocity.X;		
		}

		if (GetAnimBoolParam(n"Launched", true))
			RotationSpeed = InitialRotationSpeed;

		// Calcualte rotations
		if (RotationSpeed != TargetRotationSpeed) 
		{
			RotationSpeed = FMath::FInterpTo(RotationSpeed, TargetRotationSpeed, DeltaTime, 1.f);
		}
		BaseRotation.Yaw -= DeltaTime * RotationSpeed;


    }

    

}