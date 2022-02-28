import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeData;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightThrown;

class UFlyingMachineMeleePlayerComponent : UFlyingMachineMeleeComponent
{
	/*  EDITABLE VARIABLES */
	default FlashTime = 0.0f;
	/*********/

	private float BlockJumpTimeLeft = 0;
	private float BlockAttackTimeLeft = 0;

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		
		// DEBUG
	#if !RELEASE
		if(DebugIsActive())
		{
			FString CurrentFrameInfo;
			CurrentFrameInfo += "PLAYER\n";
			GetDebugInfo(CurrentFrameInfo);

			CurrentFrameInfo += "BlockJumpTimeLeft: " + BlockJumpTimeLeft + "\n";
			CurrentFrameInfo += "BlockAttackTimeLeft: " + BlockAttackTimeLeft + "\n";

			FHazeMeleeTarget Squirrel;
			if(GetCurrentTarget(Squirrel))
			{
				CurrentFrameInfo += "Distance: " + Squirrel.Distance + "\n";
			}
	
			PrintToScreen(CurrentFrameInfo);
		}
	#endif


		if(BlockJumpTimeLeft > 0)
			BlockJumpTimeLeft = FMath::Max(BlockJumpTimeLeft - DeltaTime, 0.f);
		
		if(BlockAttackTimeLeft > 0)
			BlockAttackTimeLeft = FMath::Max(BlockAttackTimeLeft - DeltaTime, 0.f);

		Super::Tick(DeltaTime);
	}

	void BlockAttack(float Time = -1)
	{
		BlockAttackTimeLeft	 = Time;
	}

	bool AttackIsBlocked()const
	{
		return FMath::Abs(BlockAttackTimeLeft) > 0;
	}

	void BlockJump(float Time = -1)
	{
		BlockJumpTimeLeft = Time;
	}

	bool JumpIsBlocked()const
	{
		return FMath::Abs(BlockJumpTimeLeft) > 0;
	}
	
	bool CanPassTrough()const
	{
		FHazeMeleeTarget SquirrelTarget; 
		if(!GetCurrentTarget(SquirrelTarget))
			return true;

		if(FMath::Abs(SquirrelTarget.RelativeLocation.Y) > 50.f)
			return true;

		if(SquirrelTarget.MovementType == EHazeMeleeMovementType::Hanging)
			return true;

		return false;
	}

	float GetValidHorizontalDeltaTranslation(float DeltaTime, float X)
	{
		float Result = X;
		FHazeMeleeTarget SquirrelTarget; 
		if(!GetCurrentTarget(SquirrelTarget))
			return Result;

		if(!CanPassTrough())
		{
			const float MoveOutAmountX = SquirrelTarget.Distance.X - ClosestMoveDistance;
			
			if(IsFacingRight() && SquirrelTarget.bIsToTheRightOfMe && X > 0 && MoveOutAmountX >= 0)
			{	
				Result = FMath::Min(X, MoveOutAmountX);
			}
			else if(IsFacingRight() && SquirrelTarget.bIsToTheRightOfMe && X < 0)
			{
				Result = X;
			}
			else if(!IsFacingRight() && !SquirrelTarget.bIsToTheRightOfMe && X < 0 && MoveOutAmountX >= 0)
			{
				Result = -FMath::Min(FMath::Abs(X), MoveOutAmountX);
			}
			else if(!IsFacingRight() && !SquirrelTarget.bIsToTheRightOfMe && X > 0)
			{
				Result = X;
			}
			else if(MoveOutAmountX < 0)
			{
				const float MoveOutValue = (FMath::Abs(MoveOutAmountX) / ClosestMoveDistance);
				const float LerpValue = FMath::Lerp(100.f, 1000.f, FMath::Pow(MoveOutValue, 2)) * DeltaTime;
				if(SquirrelTarget.bIsToTheRightOfMe)
					Result = -FMath::Min(FMath::Abs(MoveOutAmountX), LerpValue);
				else
					Result = FMath::Min(FMath::Abs(MoveOutAmountX), LerpValue);
			}
		}

		return Result;
	}

	UFUNCTION(BlueprintOverride)
	FVector2D PreApplyDeltaMovement(float DeltaTime, const FVector2D& MoveAmount)
	{
		if(HasControl())
		{
			float Gravity = GravityAmount * DeltaTime;
			if(MoveAmount.Y != 0) // No gravity when vertical move
				Gravity = 0.f;

			return FVector2D(GetValidHorizontalDeltaTranslation(DeltaTime, MoveAmount.X), MoveAmount.Y + Gravity);
		}
		else
		{
			return MoveAmount;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PrepareNextFrame()
	{	
		if(IsGrounded() && HasControl())
		{
			FHazeSplineSystemPosition SplinePosition = GetPosition();
			Owner.SetActorLocation(SplinePosition.GetWorldLocation());
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanActivateAsset(ULocomotionFeatureMeleeBase MeleeBaseAsset)const override
	{
		auto AttackAsset = Cast<ULocomotionFeaturePlaneFightAttackBase>(MeleeBaseAsset);
		if(AttackAsset != nullptr)
		{
			if(AttackAsset.bIsPlayerValidation)
				return CanActivateAttackAsPlayer(AttackAsset);
			else
				return false;
		}

		auto ThrownAsset = Cast<ULocomotionFeaturePlaneFightThrown>(MeleeBaseAsset);
		if(ThrownAsset != nullptr)
		{
			if(ThrownAsset.bThrowIsForward)
			{
				if(!HasMeleeAction(MeleeTags::MeleeThrowForward))
					return false;
			}	
			else
			{
				if(!HasMeleeAction(MeleeTags::MeleeThrow))
					return false;
			}
		}

		return Super::CanActivateAsset(MeleeBaseAsset);
	}

	bool CanActivateAttackAsPlayer(ULocomotionFeaturePlaneFightAttackBase Asset) const
	{
		const FHazeMeleeAttackPlayerValidation& PlayerValidation = Asset.PlayerValidation;

		//Validate the combo
		FHazeMeleeActiveComboParams ActiveCombo;
		GetCurrentComboData(ActiveCombo);
		const auto CurrentComboFeature = Cast<ULocomotionFeaturePlaneFightAttackBase>(ActiveCombo.Feature);
		if(PlayerValidation.RequiredComboMoveTag != NAME_None)
		{
			if(CurrentComboFeature == nullptr)
				return false;

			if(CurrentComboFeature.ComboMoveTag != PlayerValidation.RequiredComboMoveTag)
				return false;
		}

		if(PlayerValidation.RequiredComboFeature != nullptr && CurrentComboFeature != PlayerValidation.RequiredComboFeature)
			return false;

		const int CurrentComboCount = ActiveCombo.ComboCount;
		if(PlayerValidation.RequiredComboCountType != EHazeMeleeComboCountCompareType::NotUsed)
		{
			if(PlayerValidation.RequiredComboCountType == EHazeMeleeComboCountCompareType::GreaterOrEqual && CurrentComboCount < PlayerValidation.RequiredComboCount)
				return false;
			else if(PlayerValidation.RequiredComboCountType == EHazeMeleeComboCountCompareType::Equal && CurrentComboCount != PlayerValidation.RequiredComboCount)
				return false;
			else if(PlayerValidation.RequiredComboCountType == EHazeMeleeComboCountCompareType::LessThenOrEqual && CurrentComboCount > PlayerValidation.RequiredComboCount)
				return false;

		}

		if(PlayerValidation.AnyRequiredComboActionTypes.Num() > 0)
		{
			for(int i = 0; i < PlayerValidation.AnyRequiredComboActionTypes.Num(); ++i)
			{
				if(PlayerValidation.AnyRequiredComboActionTypes[i] != ActiveCombo.ActionType)
					return false;
			}
		}

		// Validate the input
		const TArray<FHazeMeleeInputAmount>& CurrentInputHistory = GetInputHistory();
		if(PlayerValidation.RequiredInputHistory.Num() > 0)
		{
			bool bFound = false;
			if(CurrentInputHistory.Num() >= PlayerValidation.RequiredInputHistory.Num())
			{
				bFound = true;
				for(int i = 0; i < PlayerValidation.RequiredInputHistory.Num(); ++i)
				{	
					if(!PlayerValidation.RequiredInputHistory[i].CanActivate(CurrentInputHistory[i]))
					{
						bFound = false;
						break;
					}
				}
			}

			if(!bFound)
				return false;			
		}

		if(!CanActivateAttack(Asset))
			return false;
		
		return true;
	}
}