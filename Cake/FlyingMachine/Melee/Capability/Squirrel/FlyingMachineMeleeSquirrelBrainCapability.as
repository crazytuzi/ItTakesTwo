
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;



// The master capability that pickes what moves the squirrel should be dooing
class UFlyingMachineMeleeSquirrelBrainCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	default TickGroup = ECapabilityTickGroups::Input;

	default CapabilityDebugCategory = MeleeTags::Melee;

	// InternalParams
	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	FHazeMeleeTarget PlayerTarget;
	bool bHasTarget = false;

	FMeleeAiSettings CurrentAiSettings;
	float NotAttackingTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Clear the data until something picks it up
		SquirrelMeleeComponent.PendingActivationData.Clear();
			
		// Store the target
		bHasTarget = MeleeComponent.GetCurrentTarget(PlayerTarget);

		// Store the ai settings
		CurrentAiSettings = SquirrelMeleeComponent.GetCurrentAiSetting();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!SquirrelMeleeComponent.bUseAi)
			return EHazeNetworkActivation::DontActivate;

		if(SquirrelMeleeComponent.BlockAiTimeLeft > 0)
			return EHazeNetworkActivation::DontActivate;

		if(SquirrelMeleeComponent.BlockAiInstigators.Num() > 0)
			return EHazeNetworkActivation::DontActivate;

		if(SquirrelMeleeComponent.HasPendingKillingBlow())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SquirrelMeleeComponent.bUseAi)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SquirrelMeleeComponent.BlockAiTimeLeft > 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SquirrelMeleeComponent.BlockAiInstigators.Num() > 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SquirrelMeleeComponent.HasPendingKillingBlow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SquirrelMeleeComponent.SetAiLevel(SquirrelMeleeComponent.CurrentAiSettingIndex);
		CurrentAiSettings = SquirrelMeleeComponent.GetCurrentAiSetting();
		NotAttackingTime = CurrentAiSettings.DelayBetweenAttacks;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SquirrelMeleeComponent.PendingActivationData = FMeleePendingControlData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SquirrelMeleeComponent.CurrentAiSettingsActiveTime += DeltaTime;
		if(!IsStateActive(EHazeMeleeStateType::Attack))
			NotAttackingTime += DeltaTime;
		else
			NotAttackingTime = 0;

		UpdateAiLevel(DeltaTime);

		if(ShouldAttackPlayer())
		{
			AttackPlayer();
		}	
	}

	void UpdateAiLevel(float DeltaTime)
	{
		SquirrelMeleeComponent.CurrentAiLevelChangeAmount += SquirrelMeleeComponent.AiLevelChangeSpeedAmount * DeltaTime;
		if(SquirrelMeleeComponent.CurrentAiLevelChangeAmount >= 1.f)
		{
			SquirrelMeleeComponent.IncreaseAiLevel();
		}
		else if(SquirrelMeleeComponent.CurrentAiLevelChangeAmount <= 0.f)
		{
			SquirrelMeleeComponent.DecreaseAiLevel();
		}
	}

	bool ShouldAttackPlayer() const
	{
		if(IsStateActive(EHazeMeleeStateType::Attack))
			return false;

		if(SquirrelMeleeComponent.bAiBlockedByNotify)
			return false;

		if(NotAttackingTime < CurrentAiSettings.DelayBetweenAttacks)
		 	return false;

		if(SquirrelMeleeComponent.CurrentAiSettingsActiveTime < CurrentAiSettings.DelayToFirstAttack)
		 	return false;

		if(PlayerTarget.StateType == EHazeMeleeStateType::HitReaction)
			return false;

		if(!PlayerTarget.bIsInFrontOfMe)
			return false;

		return true;
	}

	void AttackPlayer()
	{
		EHazeMeleeMovementType CurrentMovementState = GetStateMovementType();

		if(CurrentMovementState == EHazeMeleeMovementType::Idling 
			&& TryRushPlayer())
			return;

		if(CurrentMovementState == EHazeMeleeMovementType::Idling 
			&& TryShootPlayer())
			return;
		
		if(CurrentMovementState == EHazeMeleeMovementType::Idling 
		|| CurrentMovementState == EHazeMeleeMovementType::Walking)
		{
			if(TryGrabPlayer())
				return;

			if(TryPunchPlayer())
				return;
		}
	}

	bool TryPunchPlayer()
	{
		if(SquirrelMeleeComponent.HitByPlayer_PlayerMoveTypes[int(EHazeMeleeMovementType::Jumping)] > 3)
		{
			// The player keeps on hitting us by jumping, counter that
			SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::AttackHigh;
		}
		else if(PlayerTarget.MovementType == EHazeMeleeMovementType::Crouching && FMath::RandRange(0.f, 1.f) > 0.75f)
		{
			SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::AttackLow;
		}
		else if(PlayerTarget.MovementType == EHazeMeleeMovementType::Jumping && FMath::RandRange(0.f, 1.f) > 0.75f)
		{
			SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::AttackHigh;
		}		
		else
		{
			SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::AttackMid;
		}

		if(SquirrelMeleeComponent.WantedAttackAction == EAiAttackType::MAX)
			return false;

		// Evalutate the attack features
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightAttack>(MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightAttack::StaticClass()));
		if(AttackFeature == nullptr)
			return false;

		SquirrelMeleeComponent.PendingActivationData.Feature = AttackFeature;
		SquirrelMeleeComponent.PendingActivationData.ActionType = AttackFeature.AiAction;
		SquirrelMeleeComponent.UpdateAttackTypeData(SquirrelMeleeComponent.WantedAttackAction);
		SquirrelMeleeComponent.ApplyFeatureCooldown(AttackFeature);
		return true;
	}

	bool TryShootPlayer()
	{
		SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::Any;

		// Evalutate the attack features
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightAttackShootNut>(MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightAttackShootNut::StaticClass()));
		if(AttackFeature == nullptr)
			return false;

		SquirrelMeleeComponent.PendingActivationData.Feature = AttackFeature;
		SquirrelMeleeComponent.PendingActivationData.ActionType = AttackFeature.AiAction;
		SquirrelMeleeComponent.UpdateAttackTypeData(SquirrelMeleeComponent.WantedAttackAction);
		SquirrelMeleeComponent.ApplyFeatureCooldown(AttackFeature);
		return true;
	}

	bool TryGrabPlayer()
	{
		if(SquirrelMeleeComponent.UnCounteredImpactAmounts <= 4)
			return false;

		if(SquirrelMeleeComponent.ImpactRatio > -4)
			return false;

		// Dont grabb players with little health
		if(PlayerTarget.GetTargetHealth(true) <= 0.3f)
			return false;

		if(PlayerTarget.MovementType != EHazeMeleeMovementType::Idling
			&& PlayerTarget.MovementType != EHazeMeleeMovementType::Walking)
			return false;

		SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::Any;

		// Evalutate the attack features
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightGrab>(MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightGrab::StaticClass()));
		if(AttackFeature == nullptr)
			return false;

		SquirrelMeleeComponent.PendingActivationData.Feature = AttackFeature;
		SquirrelMeleeComponent.PendingActivationData.ActionType = AttackFeature.AiAction;
		SquirrelMeleeComponent.UpdateAttackTypeData(SquirrelMeleeComponent.WantedAttackAction);
		SquirrelMeleeComponent.ApplyFeatureCooldown(AttackFeature);
		return true;
	}

	bool TryRushPlayer()
	{
		auto LastRushFeature = Cast<ULocomotionFeaturePlaneFightAttackRush>(MeleeComponent.GetLastActiveFeature());
		auto LastAttackFeature = Cast<ULocomotionFeaturePlaneFightAttack>(MeleeComponent.GetLastActiveFeature());
		
		// We can only active rush if last was a rush or if last was an attack
		if(!(LastRushFeature != nullptr || LastAttackFeature != nullptr))
			return false;
			

		SquirrelMeleeComponent.WantedAttackAction = EAiAttackType::Any;
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightAttackRush>(MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightAttackRush::StaticClass()));
		
		if(AttackFeature == nullptr)
		{
			SquirrelMeleeComponent.MadeRushAmounts = 0;
			if(LastRushFeature != nullptr)
			{
				SquirrelMeleeComponent.ApplyFeatureCooldown(LastRushFeature);
			}
			return false;
		}
			

		SquirrelMeleeComponent.PendingActivationData.Feature = AttackFeature;
		SquirrelMeleeComponent.PendingActivationData.ActionType = AttackFeature.AiAction;
		SquirrelMeleeComponent.UpdateAttackTypeData(SquirrelMeleeComponent.WantedAttackAction);
		SquirrelMeleeComponent.MadeRushAmounts++;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";	
		return Str;	
	}
}
