import Vino.LevelSpecific.Garden.ValveTurnInteractionLocomotionFeature;
import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Vino.LevelSpecific.Garden.ValveTurnData;

class UValveTurnInteractionLocomotionFeatureSubAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter PlayerOwner;

	UPROPERTY(BlueprintReadOnly)
	UValveTurnInteractionLocomotionFeature TurnFeature;

	UPROPERTY(BlueprintReadOnly)
	float Alpha = 0;

	UPROPERTY(BlueprintReadOnly)
	bool ReachedEndR = false;

	UPROPERTY(BlueprintReadOnly)
	bool ReachedEndL = false;

	UPROPERTY(BlueprintReadOnly)
	bool Left = false;

	UPROPERTY(BlueprintReadOnly)
	float Struggling = 0;

	UPROPERTY(BlueprintReadOnly)
	bool bIsTurning = false;
	
	AValveTurnInteractionActor InteractionActor;

	UFUNCTION()
	void AnimNotify_stateEnterStruggle()
	{
		if(InteractionActor == nullptr){
			return;
		}
		InteractionActor.SetAnimBoolParam(n"IsStruggling", true);
	}
		UFUNCTION()
	void AnimNotify_stateExitStruggle()
	{
		if(InteractionActor == nullptr){
			return;
		}
		InteractionActor.SetAnimBoolParam(n"IsStruggling", false);	
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwningActor());
		if(PlayerOwner != nullptr)
		{
			TurnFeature = Cast<UValveTurnInteractionLocomotionFeature>(GetFeatureAsClass(UValveTurnInteractionLocomotionFeature::StaticClass()));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(PlayerOwner != nullptr)
		{
			AValveTurnInteractionActor NewInteractionActor = Cast<AValveTurnInteractionActor>(GetAnimObjectParam(ValveTurnTags::InteractionActor, true));
			if(NewInteractionActor != nullptr && NewInteractionActor != InteractionActor)
				InteractionActor = NewInteractionActor;
		}

		if(InteractionActor == nullptr)
			return;

		ReachedEndR = HasReachedEndTurningRight();
		ReachedEndL = HasReachedEndTurningLeft();
		bIsTurning = IsTurning();
		if(!InteractionActor.bClockwiseIsCorrectInput)
			Left = IsTurningInTheCorrectDirection();
		else
			Left = !IsTurningInTheCorrectDirection();

		if(IsStruggling())
		{
			Struggling = FMath::FInterpTo(Struggling, 1, DeltaTime, 4);
		}
		else
		{
			Struggling = FMath::FInterpTo(Struggling, 0, DeltaTime, 4);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		InteractionActor = nullptr;
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

	// True if the player is rotating the input stick in the wrong direction
	UFUNCTION(BlueprintPure)
	bool IsTurningInTheWrongDirection()
	{
		if(InteractionActor != nullptr)
		{
			if(InteractionActor.bClockwiseIsCorrectInput)
				return InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::Left;
			else
				return InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::Right;
		}

		return false;
	}

	// True if the player is turning and the valve can still turn that direction
	UFUNCTION(BlueprintPure)
	bool IsTurning()
	{
		if(InteractionActor != nullptr)
		{
			return InteractionActor.PlayerStatus != EValveTurnInteractionAnimationType::None;
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

	bool IsStruggling()
	{
		if(InteractionActor != nullptr)
		{
			return (InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::LeftStruggle 
			|| InteractionActor.PlayerStatus == EValveTurnInteractionAnimationType::RightStruggle);
		}

		return false;
	}
}

class UValveTurnInteractionAnimInstance : UHazeCharacterAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	float RotationValue = 0;

	UPROPERTY(BlueprintReadOnly)
	float Struggling = 0;

	AValveTurnInteractionActor InteractionActor;

	UPROPERTY(BlueprintReadOnly)
	bool ReachedEndR = false;

	UPROPERTY(BlueprintReadOnly)
	bool ReachedEndL = false;

	UPROPERTY(BlueprintReadOnly)
	bool bStruggling = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		InteractionActor = Cast<AValveTurnInteractionActor>(GetOwningActor());
	}

	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(InteractionActor != nullptr)
			RotationValue = InteractionActor.SyncComponent.Value * -10;
		else
			RotationValue = 0.f;
		
		if(IsStruggling())
		{
			Struggling = FMath::FInterpTo(Struggling, 1, DeltaTime, 4);
		}
		else
		{
			Struggling = FMath::FInterpTo(Struggling, 0, DeltaTime, 4);
		}
		ReachedEndR = HasReachedEndTurningRight();
		ReachedEndL = HasReachedEndTurningLeft();
		bStruggling = GetAnimBoolParam(n"IsStruggling");
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
