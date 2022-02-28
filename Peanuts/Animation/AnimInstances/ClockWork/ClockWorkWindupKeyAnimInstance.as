import Cake.Interactions.Windup.LocomotionFeatureWindup;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Clockwork.Windup.WindupKeyActor;


class UClockWorkWindupKeyAnimInstance : UHazeFeatureSubAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureWindup WindupFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector KeyOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRequestingPush;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRequestingPull;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsPushing;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsPulling;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFinished;

	bool bEnteredFromJumpTo;

	AWindupKeyActor WindupKeyActor;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
		WindupFeature = Cast<ULocomotionFeatureWindup>(GetFeatureAsClass(ULocomotionFeatureWindup::StaticClass()));

		// Check if we come from a JumpTo
		
		bEnteredFromJumpTo = (GetPreviousAnimationUpdateParams().LocomotionTag == MovementSystemTags::AirMovement);
		WindupKeyActor = Cast<AWindupKeyActor>(OwningActor.GetAttachParentActor());

    }

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bEnteredFromJumpTo)
			return 0.05f;
		return 0.2f;
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (WindupKeyActor == nullptr)
            return;

		// Z Range [0, -40]
		KeyOffset = WindupKeyActor.Mesh.GetRelativeLocation();

		bFinished = WindupKeyActor.IsFinished();
			
		
		// Set some bools depending on if the players are pusing/pulling
		const float MovementDirection = GetAnimFloatParam(n"PushInputY", true);
		if (MovementDirection != 0)
		{
			bIsPushing = (MovementDirection > 0);
			bIsPulling = !bIsPushing;
			bRequestingPush = bIsPushing;
			bRequestingPull = bIsPulling;
		}
		else
		{
			const float WantedMovementDir = GetAnimFloatParam(n"PushInputX", true);
			if (WantedMovementDir != 0)
			{
				bRequestingPush = (WantedMovementDir > 0);
				bRequestingPull = !bRequestingPush;
			}
			else
			{
				bRequestingPush = false;
				bRequestingPull = false;
			}
			bIsPushing = false;
			bIsPulling = false;
		}

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}