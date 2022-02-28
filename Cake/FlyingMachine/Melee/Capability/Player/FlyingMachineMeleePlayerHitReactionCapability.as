
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeHitReactionCapability;

class UFlyingMachineMeleePlayerHitReactionComboCapability : UFlyingMachineMeleePlayerHitReactionCapability
{
	default TickGroupOrder = TickGroupOrder + 1;
}

class UFlyingMachineMeleePlayerHitReactionCapability : UFlyingMachineMeleeHitReactionCapability
{
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		
		// This will setup the active feature
		Super::OnActivated(ActivationParams);

	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Super::OnDeactivated(DeactivationParams);
	}
}
