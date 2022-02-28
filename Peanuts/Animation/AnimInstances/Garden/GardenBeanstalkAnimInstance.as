import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Peanuts.Animation.AnimationStatics;

class UGardenBeanstalkAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Hurt;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Exit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData ExitIntoSoil;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData CloseToGEO;


	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPlayExit;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float EnvironmentHitFraction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SplineLenght;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator BankingRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EBeanstalkState BeanstalkState;

	ABeanstalk Beanstalk;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Beanstalk = Cast<ABeanstalk>(OwningActor);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Beanstalk == nullptr)
            return;

		const FVector LocalVelocity = Beanstalk.HeadRotationNode.WorldRotation.UnrotateVector(OwningActor.ActorVelocity);
		
		BlendspaceValues.Y = LocalVelocity.X / 1000.f;

		if (Beanstalk.HasControl())
		{
			const float InterpSpeed = Beanstalk.WantedMovementDirection < 0 ? 1.f : 2.f;
			const float Target = FMath::Abs(LocalVelocity.X) > 100.f ? FMath::Clamp(LocalVelocity.Y, -70.f, 70.f) : 0.f;
			BankingRotation.Yaw = FMath::FInterpTo(BankingRotation.Yaw, Target, DeltaTime, InterpSpeed);
		}
		

		BeanstalkState = Beanstalk.CurrentState;
		if (Beanstalk.CurrentState == EBeanstalkState::Submerging)
		{
			SplineLenght = Beanstalk.GetSplineLength();
		}
		else
		{
			EnvironmentHitFraction = FMath::FInterpTo(EnvironmentHitFraction, Beanstalk.GetEnvironmentHitFraction(), DeltaTime, 1.5f);
		}

    }

    

}