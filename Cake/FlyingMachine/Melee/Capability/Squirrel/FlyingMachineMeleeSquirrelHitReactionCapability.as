import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeHitReactionCapability;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;

class UFlyingMachineMeleeSquirrelHitReactionComboCapability : UFlyingMachineMeleeSquirrelHitReactionCapability
{
	default TickGroupOrder = TickGroupOrder + 1;
}

class UFlyingMachineMeleeSquirrelHitReactionCapability : UFlyingMachineMeleeHitReactionCapability
{
	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = UFlyingMachineMeleeSquirrelComponent::Get(Squirrel);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		UHazeMeleeImpactAsset ImpactAsset = nullptr;
		ULocomotionFeatureMeleeFightHitReaction HitReactionFeature = nullptr;
		if(!GetPendingImpactData(ImpactAsset, HitReactionFeature))
			return EHazeNetworkActivation::DontActivate;

		// The killing blow will always trigger
		auto PlaneFightHitReaction = Cast<ULocomotionFeaturePlaneFightHitReaction>(HitReactionFeature);
		if(PlaneFightHitReaction != nullptr && PlaneFightHitReaction.ValidationType == EPlaneFightHitReactionValidationType::KillingBlow)
		 	return EHazeNetworkActivation::ActivateLocal;
		
		// The roundkick will break the current attack animation if it is not a special attack
		if(SquirrelMeleeComponent.GetActionType() != EHazeMeleeActionInputType::Special)
		{
			if(ImpactAsset != nullptr && ImpactAsset.ImpactTag == n"RoundKick")
				return EHazeNetworkActivation::ActivateLocal;
		}

		// Attacking will not trigger impact state
		if(IsStateActive(EHazeMeleeStateType::Attack))
			return EHazeNetworkActivation::DontActivate;
	
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		if(bActivatedInAir)
		{
			SquirrelMeleeComponent.BlockAiInstigators.Add(this);
			SquirrelMeleeComponent.SetCanTakeDamage(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bActivatedInAir)
		{
			SquirrelMeleeComponent.BlockAiInstigators.RemoveSwap(this);
			SquirrelMeleeComponent.SetCanTakeDamage(true);
		}

		Super::OnDeactivated(DeactivationParams);
	}
}