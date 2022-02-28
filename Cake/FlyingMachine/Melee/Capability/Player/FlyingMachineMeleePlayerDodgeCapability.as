
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightDodge;

class UFlyingMachineMeleePlayerDodgeComboCapability : UFlyingMachineMeleePlayerDodgeCapability
{
	default TickGroupOrder = TickGroupOrder + 1;
}

class UFlyingMachineMeleePlayerDodgeCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);

	default TickGroupOrder = 40;
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default CapabilityDebugCategory = MeleeTags::Melee;

	/*  EDITABLE VARIABLES */
	const float BlockJumpTime = 0.1f;
	/** */

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;
	
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

		if(!PlayerMeleeComponent.HasPendingDodge())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsStateActive(EHazeMeleeStateType::Dodge))
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
		Player.BlockCapabilities(MeleeTags::MeleeAttack, this);
		Player.UnblockCapabilities(MeleeTags::MeleeAttack, this);

		FMeleePendingControlData DodgeData;
		DodgeData.Receive(ActivationParams);
		auto DodgeFeature = Cast<UHazeLocomotionFeaturePlaneFightDodge>(ActivateState(EHazeMeleeStateType::Dodge, DodgeData.Feature));
		PlayerMeleeComponent.ActivateHorizontalTranslation(DodgeFeature.HorizontalTranslationAmount, DodgeFeature.HorizontalTranslationMoveSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DeactivateState(EHazeMeleeStateType::Dodge);
		if(DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
			PlayerMeleeComponent.BlockJump(BlockJumpTime);
	}
}
