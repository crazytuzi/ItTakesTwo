
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;

// This capability makes it possible to activate another attack action while the first one is still active
class UFlyingMachineMeleePlayerAttackComboCapability : UFlyingMachineMeleePlayerAttackCapability
{
	default TickGroupOrder = TickGroupOrder + 1;
}

class UFlyingMachineMeleePlayerAttackCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeAttack);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;

	bool bAirBourneActivation = false;
	bool bBlockedMovement = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMeleeComponent = Cast<UFlyingMachineMeleePlayerComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerMeleeComponent.HasPendingAttack())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		const bool bAirbourne = GetStateMovementType() == EHazeMeleeMovementType::Jumping;
		if(bAirBourneActivation != bAirbourne)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsStateActive(EHazeMeleeStateType::Attack))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		PlayerMeleeComponent.PendingActivationData.Consume(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		// // This will reset the other attack capability
		SetMutuallyExclusive(MeleeTags::MeleeAttack, true);
		SetMutuallyExclusive(MeleeTags::MeleeAttack, false);

		FMeleePendingControlData AttackData;
		AttackData.Receive(ActivationParams);
		auto AttackFeature = Cast<ULocomotionFeaturePlaneFightAttackBase>(ActivateState(EHazeMeleeStateType::Attack, AttackData.Feature, AttackData.ActionType));
		PlayerMeleeComponent.ActivateHorizontalTranslation(AttackFeature. HorizontalTranslationAmount, AttackFeature.HorizontalTranslationMoveSpeed);

		bAirBourneActivation = GetStateMovementType() == EHazeMeleeMovementType::Jumping;
		
		// We can't move during attacks, unless we are airbourne
		if(!bAirBourneActivation)
		{
			bBlockedMovement = true;
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		DeactivateState(EHazeMeleeStateType::Attack);		
		if(bBlockedMovement)
		{
			bBlockedMovement = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MeleeComponent.UpdateControlSideImpact();
	}

}
