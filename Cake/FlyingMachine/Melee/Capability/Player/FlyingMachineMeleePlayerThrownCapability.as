import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightThrown;

class UFlyingMachineMeleePlayerThrownCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeHitReaction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = MeleeTags::Melee;

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;
	EHazeMeleeMovementType ActivationMovementType = EHazeMeleeMovementType::Idling;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMeleeComponent = Cast<UFlyingMachineMeleePlayerComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerMeleeComponent.HasMeleeAction(MeleeTags::MeleeThrow))
			return EHazeNetworkActivation::ActivateLocal;

		if(PlayerMeleeComponent.HasMeleeAction(MeleeTags::MeleeThrowForward))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsStateActive(EHazeMeleeStateType::HitReaction))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		// SetMutuallyExclusive(MeleeTags::Melee, true);
		// Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		// Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		PlayerMeleeComponent.RemoveMeleeAction(MeleeTags::MeleeThrow);	
		PlayerMeleeComponent.RemoveMeleeAction(MeleeTags::MeleeThrowForward);
		PlayerMeleeComponent.ClearTranslationData();	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DeactivateState(EHazeMeleeStateType::HitReaction);
		
		// SetMutuallyExclusive(MeleeTags::Melee, false);
		// Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		// Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}
}
