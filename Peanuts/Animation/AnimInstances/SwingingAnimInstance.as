import Peanuts.Animation.AnimationStatics;
import Peanuts.Animation.Features.LocomotionFeatureSwinging;
import Vino.Movement.Swinging.SwingComponent;

enum EHazeSwingingExitTypes {
	JumpForward,
	JumpBackward,
	ExitForwards,
	ExitBackwards,
	ExitJumpBackwardLeft,
	ExitJumpBackwardRight
}

class USwingingAnimInstance : UHazeFeatureSubAnimInstance
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ULocomotionFeatureSwinging SwingingFeature;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	EHazeSwingingExitTypes ExitAnimation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D BlendSpaceValues;

	// Not actual mesh rotation, but rather the rotation of the root joint.
	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator MeshRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bEnableMeshRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)	
	bool bPlayExit;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bEnableIK;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bMovingForwads;

	UPROPERTY()
	bool bTurnAround;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTurnRight;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float TurnAroundPlayRate = 1.f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector IKHandLocationLeft;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector IKHandLocationRight;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector IKHandLocationLeftBck;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector IKHandLocationRightBck;

	AHazePlayerCharacter Player;
	USwingingComponent SwingingComponent;

	float SwingingPosition;
	float TriggerTurnAfter;
	bool bFirstTick = false;
	bool bExitsAreValid;
	float TriggerJumpBackAfter;

	bool bPlayTurnOnEveryApex;
	bool bCharacterIsTurning;
	int TurnDir;

	bool bOnCrazySpaceStationSwingpoint;

	float MaxApexValue = 70.f;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		Player = Cast<AHazePlayerCharacter>(OwningActor);
		SwingingComponent  = Cast<USwingingComponent>(OwningActor.GetComponentByClass(USwingingComponent::StaticClass()));
		SwingingFeature = Cast<ULocomotionFeatureSwinging>(GetFeatureAsClass(ULocomotionFeatureSwinging::StaticClass()));
		if (SwingingComponent == nullptr)
			return;

		const USwingPointComponent SwingPoint = SwingingComponent.GetActiveSwingPoint();
		if (SwingPoint != nullptr)
			MaxApexValue = SwingPoint.SwingAngle;

		bPlayTurnOnEveryApex = SwingingFeature.bPlayTurnOnEveryApex;

		bEnableIK = SwingingFeature.bEnableIK;
		if (bEnableIK)
		{
			IKHandLocationLeft = GetIkBoneOffset(SwingingFeature.IKReference, 0.f, n"Align", n"LeftHand").Location;
			IKHandLocationRight = GetIkBoneOffset(SwingingFeature.IKReference, 0.f, n"Align", n"RightHand").Location;
			IKHandLocationLeftBck = GetIkBoneOffset(SwingingFeature.IKReferenceBck, 0.f, n"Align", n"LeftHand").Location;
			IKHandLocationRightBck = GetIkBoneOffset(SwingingFeature.IKReferenceBck, 0.f, n"Align", n"RightHand").Location;
		}
		
		bEnableMeshRotation = false;
		bTurnAround = false;
		bFirstTick = true;
		bPlayExit = false;
		TriggerTurnAfter = SwingingFeature.TriggerTurnAfter;
		TriggerJumpBackAfter = SwingingFeature.TriggerJumpBackAfter;
		bExitsAreValid = Animation::IsSequencePlayerDataValid(SwingingFeature.ExitBck) && Animation::IsSequencePlayerDataValid(SwingingFeature.ExitFwd);
		
		bOnCrazySpaceStationSwingpoint = GetAnimBoolParam(n"CrazySpacestationSwingpoint", true);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return SwingingFeature.BlendTime;
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SwingingComponent == nullptr)
			return;

		if (bPlayExit)
		{
			bPlayExit = (LocomotionAnimationTag != n"Swinging");

			// Re-initialize the subABP
			if (!bPlayExit)
				BlueprintInitializeAnimation();
			return;
		}

		const FRotator ActorRotation = OwningActor.GetActorRotation();
		MeshRotation = OwningActor.ActorTransform.InverseTransformRotation(SwingingComponent.GetDesiredMeshRotation());

		// Blendspace Values
		const FVector LocalVelocity = GetActorLocalVelocity(OwningActor);
		BlendSpaceValues = FVector2D(FMath::Clamp(MeshRotation.Roll, -50.f, 50.f), LocalVelocity.X);

		// Get current position on the swing, range from -1 to 1
		const float NewSwingingPosition = FMath::Clamp((MeshRotation.Pitch / MaxApexValue), -1.f, 1.f);
		bMovingForwads = (NewSwingingPosition > SwingingPosition);
		SwingingPosition = NewSwingingPosition;

		if (bFirstTick)
		{
			bMovingForwads = true;
			bFirstTick = false;	
			return;
		}
		else
			bEnableMeshRotation = true;

		if (bOnCrazySpaceStationSwingpoint || 
			(TopLevelGraphRelevantStateName == n"Enter" && TopLevelGraphRelevantAnimTimeRemaining > 0.2f) || 
			FMath::Abs(MeshRotation.Roll) > 20.f || 
			FMath::Abs(NewSwingingPosition) > 0.95
			)
			return;


		// Compare capsule rotation to camera. Range from 0 - 1 depending on how different they are
		const float CapsuleCameraDelta = FMath::Abs(GetHorizontalAimSpaceValue(Player));
		if ((CapsuleCameraDelta > .65f || bPlayTurnOnEveryApex) && SwingingPosition > TriggerTurnAfter && bMovingForwads && !bTurnAround)
		{
			bTurnRight = ShouldTurnRight();
			bTurnAround = true;
		}		
		else if ((CapsuleCameraDelta < .4f  || bPlayTurnOnEveryApex) && SwingingPosition < -TriggerTurnAfter && !bMovingForwads && bTurnAround)
		{
			bTurnRight = ShouldTurnRight();
			bTurnAround = false;
		}

		if (SwingingFeature.bAllowPlayratedTurns)
		{
			if (!bTurnAround && TurnDir == -1)
				TurnAroundPlayRate = FMath::FInterpTo(TurnAroundPlayRate, 2.5f, DeltaTime, 8.f);
			else if (bTurnAround && TurnDir == 1)
				TurnAroundPlayRate = FMath::FInterpTo(TurnAroundPlayRate, 2.5f, DeltaTime, 8.f);
			else
			{
				
				TurnAroundPlayRate = FMath::FInterpTo(TurnAroundPlayRate, (70.f / MaxApexValue + 0.5) / 1.5, DeltaTime, 10.f);
			}
			TurnAroundPlayRate = FMath::Clamp(TurnAroundPlayRate, 0.5f, 1.2f);
		}

	}

	// Can transition from this subABP
	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom()
	{
		if (!bPlayExit)
		{
			// Only run this the first tick when we stop requesting swinging
			ExitAnimation = GetExitAnimationType();
			if (!bMovingForwads)
				MeshRotation.Pitch *= -1;

			bPlayExit = true;
			bEnableMeshRotation = false;
			bTurnAround = false;
			return false;
		}

		
		if (LocomotionAnimationTag == n"SwingJump" || ((LocomotionAnimationTag == n"AirMovement") &&
			(TopLevelGraphRelevantAnimTimeRemaining > 0.1 && TopLevelGraphRelevantStateName == n"Exit")))
		{
			return false;
		}
			
		return true;
	}

	UFUNCTION()
	bool ShouldTurnRight()
	{
		float AimValue = GetHorizontalAimSpaceValue(Player);

		// Fix for swinging upside down in space station
		AimValue = ConvertGrindAimValues(FVector2D(AimValue, 0.f), OwningActor, OwningActor.ActorRotation).X;
		
		const bool bInverted = FMath::Abs(AimValue) > 0.5;
		if (bInverted)
		{
			if (AimValue > 0)
				AimValue = 1 - AimValue;
			else
				AimValue = -1 - AimValue;
		}
		if (FMath::Abs(AimValue) < 0.1f)
			return bTurnRight;
		if (!bInverted)
			return (AimValue > 0);
		return (AimValue < 0);
	}


	UFUNCTION()
	void AnimNotify_CharacterTurned()
	{
		TurnDir = 0;
	}

	UFUNCTION()
	void AnimNotify_TurningFwd()
	{
		TurnDir = 1;
	}

	UFUNCTION()
	void AnimNotify_TurningBack()
	{
		TurnDir = -1;
	}


	// Get the exit type that should be played based on where on the swing the player is.
	UFUNCTION()
	EHazeSwingingExitTypes GetExitAnimationType()
	{
		const float JUMP_FWD_SWING_POS = 0.95f;
		const bool bJumped = GetAnimBoolParam(n"SwingDetachJump", true);
		if (TurnDir != 0)
		{
			if ((SwingingPosition > 0.f && !bMovingForwads) || (SwingingPosition < 0.f && bMovingForwads))
			{
				if (FMath::Abs(SwingingPosition) > JUMP_FWD_SWING_POS)
					return EHazeSwingingExitTypes::JumpBackward;
				return bJumped ? EHazeSwingingExitTypes::JumpForward : EHazeSwingingExitTypes::ExitForwards;
			}
				
			if (FMath::Abs(SwingingPosition) < TriggerJumpBackAfter)
				return EHazeSwingingExitTypes::JumpForward;
			else if (bTurnRight)
				return EHazeSwingingExitTypes::ExitJumpBackwardRight;
			else
				return EHazeSwingingExitTypes::ExitJumpBackwardLeft;
		}

		if (SwingingPosition > 0.f && bMovingForwads)
		{
			if (bTurnAround)
				return EHazeSwingingExitTypes::JumpBackward;
			else
				return EHazeSwingingExitTypes::JumpForward;
		}

		else if (SwingingPosition < 0.f && !bMovingForwads)
		{
			if (bTurnAround)
				return EHazeSwingingExitTypes::JumpForward;
			else
				return EHazeSwingingExitTypes::JumpBackward;
		}

		
		if (bMovingForwads)
			if (bTurnAround)
			{
				if (FMath::Abs(SwingingPosition) > JUMP_FWD_SWING_POS)
					return EHazeSwingingExitTypes::JumpForward;
				return bJumped ? EHazeSwingingExitTypes::JumpBackward : EHazeSwingingExitTypes::ExitBackwards;
			}
			else
			{
				if (FMath::Abs(SwingingPosition) > JUMP_FWD_SWING_POS)
					return EHazeSwingingExitTypes::JumpBackward;
				return bJumped ? EHazeSwingingExitTypes::JumpForward : EHazeSwingingExitTypes::ExitForwards;
			}
				
		else
			if (bTurnAround)
			{
				if (FMath::Abs(SwingingPosition) > JUMP_FWD_SWING_POS)
					return EHazeSwingingExitTypes::JumpBackward;
				return bJumped ? EHazeSwingingExitTypes::JumpForward : EHazeSwingingExitTypes::ExitForwards;
			}	
			else
			{
				if (FMath::Abs(SwingingPosition) > JUMP_FWD_SWING_POS)
					return EHazeSwingingExitTypes::JumpForward;
				return bJumped ? EHazeSwingingExitTypes::JumpBackward : EHazeSwingingExitTypes::ExitBackwards;
			}
				
	}

}