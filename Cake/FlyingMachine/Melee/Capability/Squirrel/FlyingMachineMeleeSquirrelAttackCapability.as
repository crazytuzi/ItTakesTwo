
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;

class UFlyingMachineMeleeSquirrelAttackCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeAttack);
	default CapabilityTags.Add(MeleeTags::MeleeAttackNormal);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroupOrder = 100;

	// InternalParams
	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;
	
	FHazeMeleeTarget PlayerTarget;
	bool bHasTarget = false;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Store the target
		bHasTarget = MeleeComponent.GetCurrentTarget(PlayerTarget);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

        if(!bHasTarget)
            return EHazeNetworkActivation::DontActivate;

		if(!SquirrelMeleeComponent.HasPendingAttack())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsStateActive(EHazeMeleeStateType::Attack))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		SquirrelMeleeComponent.PendingActivationData.Consume(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		// This will reset the other attack capability
		SetMutuallyExclusive(MeleeTags::MeleeAttack, true);
		SetMutuallyExclusive(MeleeTags::MeleeAttack, false);

		FMeleePendingControlData AttackData;
		AttackData.Receive(ActivationParams);
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightAttackBase>(ActivateState(EHazeMeleeStateType::Attack, AttackData.Feature, AttackData.ActionType));
		SquirrelMeleeComponent.ActivateHorizontalTranslation(AttackFeature. HorizontalTranslationAmount, AttackFeature.HorizontalTranslationMoveSpeed);

		// Force the squirrel to face the correct way
		if(PlayerTarget.bIsToTheRightOfMe)
			FaceRight();
		else
			FaceLeft();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DeactivateState(EHazeMeleeStateType::Attack);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MeleeComponent.UpdateControlSideImpact();
	}
}
