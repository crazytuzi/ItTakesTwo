
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;
import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeManager;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeData;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;


class UFlyingMachineMeleeSquirrelComponent : UFlyingMachineMeleeComponent
{
	/*  EDITABLE VARIABLES */
	default FlashTime = 0.2f;
	default DebugColor = FLinearColor::Gray;

	// MoveParams
	const float ForwardSpeed = 350.f;

	bool FinishOnNextImpact = false;
	bool bAiBlockedByNotify = false;

	UPROPERTY()
	TSubclassOf<AFlyingMachineMeleeNut> NutType;

	UPROPERTY()
	bool bUseAi = true;

	int ValidImpactsMadeToMe = 0;
	int ValidImpactMadeToPlayer = 0;
	int ImpactRatio = 0;
	int UnCounteredImpactAmounts = 0;

	EHazeMeleeLevelType CurrentAiSettingIndex = EHazeMeleeLevelType::Retarded;
	float AiLevelChangeSpeed = 0;
	float CurrentAiLevelChangeAmount = 0;
	float CurrentAiSettingsActiveTime = 0;

	EAiAttackType WantedAttackAction = EAiAttackType::MAX;
	TArray<EAiAttackType> LastAttacks;
	TMap<ULocomotionFeatureMeleeBase, float> FeatureLastTriggeredTime;
	TArray<int> HitByPlayer_PlayerMoveTypes;
	
	AFlyingMachineMeleeNut CurrentNut;	

	float IdleTime = -1;
	int MadeRushAmounts = 0;
	float BlockAiTimeLeft = 0;
	TArray<UObject> BlockAiInstigators;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{	
		bUseAi = true;	
		for(int i = 0; i < int(EHazeMeleeMovementType::Unset); ++i)
		{
			HitByPlayer_PlayerMoveTypes.Add(0);
		}
	}

	void SetAiLevel(EHazeMeleeLevelType Level)
	{
		CurrentAiSettingIndex = Level;
		CurrentAiLevelChangeAmount = 0.5f;
		AiLevelChangeSpeed = GetCurrentAiSetting().InitialSpeedAmount;
		CurrentAiSettingsActiveTime = 0;
	}

	void IncreaseAiLevel()
	{
		if(CurrentAiSettingIndex < EHazeMeleeLevelType(int(EHazeMeleeLevelType::MAX) - 1))
			SetAiLevel(EHazeMeleeLevelType((int(CurrentAiSettingIndex) + 1)));
	}

	void DecreaseAiLevel()
	{
		if(CurrentAiSettingIndex > EHazeMeleeLevelType::Retarded)
			SetAiLevel(EHazeMeleeLevelType((int(CurrentAiSettingIndex) - 1)));
	}

	float GetAiLevelChangeSpeedAmount() const property
	{
		float TotalAmount = AiLevelChangeSpeed;
		
		// Add the idle bonus time
		if(IdleTime >= 0 && IdleTime >= FMath::Abs(CurrentAiSetting.IdleTimeToIdleLevelChangeSpeedBonusAmount))
		{
			TotalAmount += FMath::Clamp(CurrentAiSetting.IdleLevelChangeSpeedBonusAmount, CurrentAiSetting.LevelChangeSpeedClamps.Min, CurrentAiSetting.LevelChangeSpeedClamps.Max);
		}

		return TotalAmount;
	}

	UFUNCTION(BlueprintOverride)
	bool GetAiLevel(EHazeMeleeLevelType& OutMeleeLevel) const 
	{
		OutMeleeLevel = CurrentAiSettingIndex;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		BlockAiTimeLeft = FMath::Max(BlockAiTimeLeft - DeltaSeconds, 0.f);

		// DEBUG
	#if !RELEASE
		if(DebugIsActive())
		{
			FString CurrentFrameInfo;
			CurrentFrameInfo += "SQUIRREL\n";
			GetDebugInfo(CurrentFrameInfo);

			CurrentFrameInfo += "AI - Settings\n";
			if(bUseAi)
			{	
				CurrentFrameInfo += "*   ValidImpactsMadeToMe: " + ValidImpactsMadeToMe + "\n";
				CurrentFrameInfo += "*   ValidImpactMadeToPlayer: " + ValidImpactMadeToPlayer + "\n";
				CurrentFrameInfo += "*   ImpactRatio: " + ImpactRatio + "\n";
				CurrentFrameInfo += "*   UnCounteredImpactAmounts: " + UnCounteredImpactAmounts + "\n";

				auto AiSettings = GetCurrentAiSetting();
				CurrentFrameInfo += "*   Level: " + CurrentAiSettingIndex + "\n";
				CurrentFrameInfo += "*   Settings Modifier: " + CurrentAiLevelChangeAmount + "\n";
				CurrentFrameInfo += "*   Settings Speed: " + AiLevelChangeSpeed + "\n";
			}
			else
			{
				CurrentFrameInfo += "*   Inactive\n";
			}
	
			FHazeMeleeTarget PlayerTarget;
			if(GetCurrentTarget(PlayerTarget))
			{
				CurrentFrameInfo += "Player Target Info\n";
				if(PlayerTarget.bIsFacingRight)
					CurrentFrameInfo += "*   Facing Right: " + "\n";
				else
					CurrentFrameInfo += "*   Facing Left: " + "\n";

				CurrentFrameInfo += "*   Distance: " + PlayerTarget.Distance + "\n";
				CurrentFrameInfo += "*   LeftEdgeDistance: " + PlayerTarget.SplineInformation.DistanceToLeftEdge + "\n";
				CurrentFrameInfo += "*   RightEdgeDistance: " + PlayerTarget.SplineInformation.DistanceToRightEdge + "\n";
				
			}

			PrintToScreen(CurrentFrameInfo);
		}
	#endif

	}

	UFUNCTION(BlueprintOverride)
	void PrepareNextFrame()
	{	
		if(IsGrounded() && HasControl())
		{
			FHazeSplineSystemPosition SplinePosition = GetPosition();
			Owner.SetActorLocation(SplinePosition.GetWorldLocation());
		}

		if(CurrentNut != nullptr)
		{
			if(!CurrentNut.bIsAttached)
			{
				if(CurrentNut.bHasImpactedWithTarget)
				{
					if(HasControl())
						UHazeCrumbComponent::Get(Owner).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DeactivateNut"), FHazeDelegateCrumbParams());
	
				}
				else if(CurrentNut.MoveTime > 1.0f)
				{
					FVector CurrentRelativeLocation = Owner.RootComponent.RelativeLocation;
					if(CurrentRelativeLocation.DistSquared(CurrentNut.LastRelativeLocation) <= KINDA_SMALL_NUMBER || CurrentNut.MoveTime > 3.f)
					{
						Game::GetMay().SetCapabilityActionState(n"OnNutDissolve", EHazeActionState::ActiveForOneFrame);
						DeactivateNut();
					}
					else
						CurrentNut.LastRelativeLocation = CurrentRelativeLocation;
				}
			}
		}

		WantedAttackAction = EAiAttackType::MAX;

		const auto AiSettings = GetCurrentAiSetting();
		AiLevelChangeSpeed = FMath::Clamp(AiLevelChangeSpeed, AiSettings.LevelChangeSpeedClamps.Min, AiSettings.LevelChangeSpeedClamps.Max);
		CurrentAiLevelChangeAmount = FMath::Clamp(CurrentAiLevelChangeAmount, 0.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnValidImpactToMe(UHazeMeleeImpactAsset ImpactAsset, FHazeMeleeTarget Instigator)
	{
		if(bUseAi)
		{
			ValidImpactsMadeToMe++;
			UnCounteredImpactAmounts++;
			ImpactRatio--;

			const auto AiSettings = GetCurrentAiSetting();
			AiLevelChangeSpeed += AiSettings.ImpactToAiLevelSpeedChangeAmount;
		}

		// Increase the instigator movement type so we can reacto to what the player keeps on doing to us
		if(Instigator.MovementType != EHazeMeleeMovementType::Unset)
		{
			HitByPlayer_PlayerMoveTypes[int(Instigator.MovementType)] += 1;	
		}

		Super::OnValidImpactToMe(ImpactAsset, Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void OnValidImpactToTarget(UHazeMeleeImpactAsset ImpactAsset)
	{
		if(bUseAi)
		{
			ValidImpactMadeToPlayer++;
			ImpactRatio++;
			UnCounteredImpactAmounts = 0;
			const auto AiSettings = GetCurrentAiSetting();
			AiLevelChangeSpeed += AiSettings.ImpactToPlayerLevelSpeedChangeAmount;
		}

		for(int i = 0; i < int(EHazeMeleeMovementType::Unset); ++i)
		{
			HitByPlayer_PlayerMoveTypes[i] = 0;;
		}

		if(ImpactAsset.ImpactTag == n"NutInitial")
		{
			DeactivateNut();
		}

		Super::OnValidImpactToTarget(ImpactAsset);
	}

	FMeleeAiSettings DefaultSettings;
	FMeleeAiSettings GetCurrentAiSetting()const property
	{
		auto AiSettings = Cast<UFlyingMachineMeleeSettings>(GetSettings());
		if(AiSettings != nullptr)
		{
			return AiSettings.AiSettings;
		}

		return DefaultSettings;
	}
	
	int GetCurrentImpactCountToMe() const property
	{
		return ValidImpactsMadeToMe;
	}

	bool CanPassTrough()const
	{
		FHazeMeleeTarget PlayerTarget; 
		if(!GetCurrentTarget(PlayerTarget))
			return true;

		if(FMath::Abs(PlayerTarget.RelativeLocation.Y) > 50.f)
			return true;

		if(MovementType == EHazeMeleeMovementType::Hanging)
			return true;

		return false;
	}

	float GetValidHorizontalDeltaTranslation(float DeltaTime, float X)
	{
		float Result = X;
		FHazeMeleeTarget PlayerTarget; 
		if(!GetCurrentTarget(PlayerTarget))
			return Result;

		if(!CanPassTrough())
		{
			const float MoveOutAmountX = PlayerTarget.Distance.X - ClosestMoveDistance;
			
			if(IsFacingRight() && PlayerTarget.bIsToTheRightOfMe && X > 0 && MoveOutAmountX >= 0)
			{	
				Result = FMath::Min(X, MoveOutAmountX);
			}
			else if(IsFacingRight() && PlayerTarget.bIsToTheRightOfMe && X < 0)
			{
				Result = X;
			}
			else if(!IsFacingRight() && !PlayerTarget.bIsToTheRightOfMe && X < 0 && MoveOutAmountX >= 0)
			{
				Result = -FMath::Min(FMath::Abs(X), MoveOutAmountX);
			}
			else if(!IsFacingRight() && !PlayerTarget.bIsToTheRightOfMe && X > 0)
			{
				Result = X;
			}
			else
			{
				Result = 0;
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
			if(MoveAmount.Y != 0)
				Gravity = 0.f;

			return FVector2D(GetValidHorizontalDeltaTranslation(DeltaTime, MoveAmount.X), MoveAmount.Y + Gravity);
		}
		else
		{
			return MoveAmount;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_DeactivateNut(const FHazeDelegateCrumbData& CrumbData)
	{
		DeactivateNut();
	}

	void DeactivateNut()
	{
		if(CurrentNut != nullptr)
		{
			CurrentNut.SpawnDestroyEffect();
			auto NutMesh = CurrentNut.GetNutMesh();
			NutMesh.AttachToComponent(CurrentNut.Root);
			NutMesh.SetRelativeTransform(FTransform::Identity);
			CurrentNut.ActivationEffect.Deactivate();
			CurrentNut.ActivationEffect.SetHiddenInGame(true);
			CurrentNut.Model.SetHiddenInGame(true);
			CurrentNut.DisableActor(nullptr);
			CurrentNut.MoveTime = 0;
			CurrentNut.bHasImpactedWithTarget = false;		
			CurrentNut = nullptr;
		}
	}

	void UpdateAttackTypeData(EAiAttackType Type)
	{
		LastAttacks.Add(Type);
		if(LastAttacks.Num() > 5)
			LastAttacks.RemoveAt(0);	
	}

	void ApplyFeatureCooldown(ULocomotionFeatureMeleeBase Feature)
	{
		FeatureLastTriggeredTime.FindOrAdd(Feature) = Time::GetGameTimeSeconds();
	}

	bool AssetIsOnCooldown(ULocomotionFeatureMeleeBase Feature, float Amount) const
	{
		const float GameTime = Time::GetGameTimeSeconds();

		float LastActivatedTime = 0;
		if(FeatureLastTriggeredTime.Find(Feature, LastActivatedTime))
			return GameTime <= LastActivatedTime + Amount;
		return false;
	}

	bool LastAttackWasAnyOf(TArray<EAiAttackType> Types)
	{
		if(LastAttacks.Num() == 0)
			return false;

		return Types.Contains(LastAttacks[0]);
	}

	UFUNCTION(BlueprintOverride)
	bool CanActivateAsset(ULocomotionFeatureMeleeBase MeleeBaseAsset)const override
	{
		auto AttackAsset = Cast<ULocomotionFeaturePlaneFightAttackBase>(MeleeBaseAsset);
		if(AttackAsset != nullptr)
		{
			if(!AttackAsset.bIsPlayerValidation)
				return CanActivateAttackAsAi(AttackAsset);
			else
				return false;
		}

		return Super::CanActivateAsset(MeleeBaseAsset);
	}


	bool CanActivateAttackAsAi(ULocomotionFeaturePlaneFightAttackBase MeleeAsset) const
	{
		devEnsure(WantedAttackAction != EAiAttackType::MAX);
		const FHazeMeleeAttackAiValidation& AiValidation = MeleeAsset.AiValidation;
		if(AiValidation.RequiredAiLevel != EHazeMeleeComboCountCompareType::NotUsed)
		{
			if(AiValidation.RequiredAiLevel == EHazeMeleeComboCountCompareType::GreaterOrEqual && CurrentAiSettingIndex < AiValidation.AiLevel)
				return false;
			else if(AiValidation.RequiredAiLevel == EHazeMeleeComboCountCompareType::Equal && CurrentAiSettingIndex != AiValidation.AiLevel)
				return false;
			else if(AiValidation.RequiredAiLevel == EHazeMeleeComboCountCompareType::LessThenOrEqual && CurrentAiSettingIndex > AiValidation.AiLevel)
				return false;
		}

		if(AiValidation.CooldownTime > 0)
		{
			if(AssetIsOnCooldown(MeleeAsset, AiValidation.CooldownTime))
				return false;
		}
		
		// Standard attacks need to alternate to be valid
		auto DefaultAttackAsset = Cast<ULocomotionFeaturePlaneFightAttack>(MeleeAsset);
		if(DefaultAttackAsset != nullptr)
		{
			if(GetLastActiveFeature() == DefaultAttackAsset)
				return false;
		}

		// Evaluate the required type for attacking
		if(AiValidation.AnyWantedType.Num() > 0)
		{
			if(!AiValidation.AnyWantedType.Contains(WantedAttackAction))
				return false;
		}

		// Validate the edges when throwing
		auto GrabAttackAsset = Cast<ULocomotionFeaturePlaneFightGrab>(MeleeAsset);
		if(GrabAttackAsset != nullptr)
		{
			const float RequiredThrowDistance = 400.f;
			FHazeMelee2DSpineData SplineInformation;
			GetSplineData(SplineInformation);
			bool CheckRight = IsFacingRight();
			if(!GrabAttackAsset.bThrowingForward)
				CheckRight = !CheckRight;

			if(CheckRight)
			{
				if(SplineInformation.DistanceToRightEdge < RequiredThrowDistance)
					return false;
			}
			else
			{
				if(SplineInformation.DistanceToLeftEdge < RequiredThrowDistance)
					return false;
			}
		}

		// Validate the edges when rushing
		auto RushAttackAsset = Cast<ULocomotionFeaturePlaneFightAttackRush>(MeleeAsset);
		if(RushAttackAsset != nullptr)
		{
			FHazeMelee2DSpineData SplineInformation;
			GetSplineData(SplineInformation);
			if(IsFacingRight())
			{
				if(SplineInformation.DistanceToRightEdge < RushAttackAsset.MaxEdgeDistance)
					return false;
			}
			else
			{
				if(SplineInformation.DistanceToLeftEdge < RushAttackAsset.MaxEdgeDistance)
					return false;
			}

			if(MadeRushAmounts >= RushAttackAsset.MaxRushTimes)
				return false;
		}


		if(!CanActivateAttack(MeleeAsset))
			return false;

		return true;
	}
}
