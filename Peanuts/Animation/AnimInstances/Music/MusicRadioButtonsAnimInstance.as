import Vino.LevelSpecific.Garden.ValveTurnInteractionLocomotionFeature;
import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;

class UMusicRadioButtonsAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly)
	UValveTurnInteractionLocomotionFeature TurnFeature;

	UPROPERTY(BlueprintReadOnly)
	bool bTurningLeft;

	UPROPERTY(BlueprintReadOnly)
	bool bTurningRight;

	UPROPERTY(BlueprintReadOnly)
	bool bStruggle;

	AValveTurnInteractionActor InteractionActor;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        TurnFeature = Cast<UValveTurnInteractionLocomotionFeature>(GetFeatureAsClass(UValveTurnInteractionLocomotionFeature::StaticClass()));
		InteractionActor = Cast<AValveTurnInteractionActor>(GetAnimObjectParam(ValveTurnTags::InteractionActor, true));

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (TurnFeature == nullptr)
            return;
		
		bStruggle = IsStruggling();
		InteractionActor.SetAnimBoolParam(n"Struggling", bStruggle);
		if (IsTurning())
		{
			bTurningLeft = IsTurningInTheCorrectDirection() && !bStruggle;
			bTurningRight = !bTurningLeft && !bStruggle;
		}
		else
		{
			bTurningLeft = false;
			bTurningRight = false;
		}

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }


	// True if the player is rotating the input stick in the correct direction
	UFUNCTION(BlueprintPure)
	bool IsTurningInTheCorrectDirection()
	{
		if(InteractionActor != nullptr)
		{
			if(InteractionActor.bClockwiseIsCorrectInput)
				return InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::Right;
			else
				return InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::Left;
		}

		return false;
	}

	
	// True if the player is turning and the valve can still turn that direction
	UFUNCTION(BlueprintPure)
	bool IsTurning()
	{
		if(InteractionActor != nullptr)
		{
			if (HasReachedEndTurningRight() || HasReachedEndTurningLeft())
				return false;

			return InteractionActor.PlayerStatus != EValveTurnInteractionAnimationType::None;
		}
		return false;
	}


	bool IsStruggling()
	{
		if(InteractionActor != nullptr)
		{
			return (InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::LeftStruggle 
			|| InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::RightStruggle);
		}

		return false;
	}

	bool HasReachedEndTurningRight()
	{
		if(InteractionActor != nullptr)
		{
			return (InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::RightEnd 
			|| InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::RightStruggle);
		}

		return false;
	}


	bool HasReachedEndTurningLeft()
	{
		if(InteractionActor != nullptr)
		{
			return (InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::LeftEnd 
			|| InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::LeftStruggle);
		}

		return false;
	}

}

class UMusicRadioButtonActorAnimInstance : UHazeCharacterAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData Struggling;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator RotationValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bStruggling;

	AValveTurnInteractionActor InteractionActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		InteractionActor = Cast<AValveTurnInteractionActor>(GetOwningActor());
	}

	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(InteractionActor != nullptr)
		{
			RotationValue.Roll = InteractionActor.SyncComponent.Value * -10;
			bStruggling = GetAnimBoolParam(n"Struggling");
		}
			
		else
			RotationValue.Roll = 0.f;
	}
}