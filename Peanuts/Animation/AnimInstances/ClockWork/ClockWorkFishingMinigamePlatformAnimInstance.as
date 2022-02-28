import Cake.LevelSpecific.Clockwork.Fishing.RodBase;
class UClockWorkFishingMinigamePlatformAnimInstance : UHazeAnimInstanceBase
{
	// Animations
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Anticipation;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Throw;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FishingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HasBite;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData ReelingIn;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Hauling;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData ThrowCatch;


	UPROPERTY(BlueprintReadOnly, NotEditable)
	EFishingState FishingState;

	UPROPERTY(BlueprintReadOnly)
    FRotator LeftCogWheelRotation;

	UPROPERTY(BlueprintReadOnly)
    FRotator RightCogWheelRotation;

	UPROPERTY(BlueprintReadOnly)
    FRotator CrankRotation;

	// This variable should be safe to remove
	UPROPERTY(BlueprintReadOnly)
    FRotator LeverRotation;

	UPROPERTY(BlueprintReadOnly)
    bool bHasPlayer;

	UPROPERTY(BlueprintReadOnly)
	bool bHasBite;

	UPROPERTY(BlueprintReadOnly)
    FRotator RodRotation;

	UPROPERTY(BlueprintReadOnly)
	float AnticipationExplicitTime;

	UPROPERTY(BlueprintReadOnly)
	float ThrowStartTime;

	UPROPERTY(BlueprintReadOnly)
	float ReelInPosition;


	float ReelingInCrankPostion;
	ARodBase RodBase;
	URodBaseComponent RodBaseComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        RodBase = Cast<ARodBase>(OwningActor);
		if (RodBase == nullptr)
			return;
		RodBaseComp = RodBase.RodBaseComp;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (RodBase == nullptr)
            return;

		RodRotation = RodBaseComp.RodStickRotation;

		bHasPlayer = (RodBase.PlayerComp != nullptr);
		if (!bHasPlayer)
		{
			RodRotation = FRotator::ZeroRotator;
			return;
		}

		FishingState = RodBase.PlayerComp.FishingState;


		if (FishingState == EFishingState::Default)
		{
			CrankRotation.Pitch = 0.f;
			LeverRotation.Pitch = RodBase.PlayerComp.TargetRotationInput * 25.f;
			RightCogWheelRotation.Pitch += LeverRotation.Pitch * DeltaTime * 5.f;
			LeftCogWheelRotation.Pitch = -RightCogWheelRotation.Pitch;
		}
		else if (FishingState == EFishingState::WindingUp)
		{
			AnticipationExplicitTime = RodBaseComp.RodStickRotation.Pitch / 25.f;
			ThrowStartTime = (1.f - AnticipationExplicitTime) / 4.5f;
			bHasBite = false;
		}
		else if (FishingState == EFishingState::Catching)
		{
			bHasBite = RodBase.PlayerComp.bCatchIsHere;
			ReelingInCrankPostion = 1.f;
		}
		else if (FishingState == EFishingState::Reeling)
		{
			ReelInPosition = ((1.f- RodBase.PlayerComp.AlphaPlayerReel) * RodBase.PlayerComp.StoredCastPower) / RodBase.PlayerComp.MaxCastPower;
			if (!RodBase.RodBaseComp.HasControl())
			{
				// Remote side
				ReelingInCrankPostion = FMath::FInterpTo(ReelingInCrankPostion, ReelInPosition, DeltaTime, 1.f);
				if (ReelingInCrankPostion > ReelInPosition)
				{
					CrankRotation.Pitch -= DeltaTime * 700.f;
					CrankRotation.Pitch = Math::FWrap(CrankRotation.Pitch, 0.f, 360.f);
				}
			}
			else if (RodBase.PlayerComp.ReelingCatchInput.Value > 0.f)
			{
				// Control side
				ReelingInCrankPostion = Math::FWrap(ReelingInCrankPostion - (RodBase.PlayerComp.ReelingCatchInput.Value * 0.135f), 0.f, 1.f);
				CrankRotation.Pitch = ReelingInCrankPostion * 360.f;
			}	
		} 
		else if (FishingState == EFishingState::Hauling || FishingState == EFishingState::HoldingCatch) 
		{
			CrankRotation.Pitch = FMath::FInterpTo(CrankRotation.Pitch, 0.f, DeltaTime, 3.5f);
		}
    }
	
}