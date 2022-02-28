import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

class UClockworkBullBossPlayerIgnoreBullCollision : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	UClockWorkBullBossPlayerComponent BullBossComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BullBossComponent = UClockWorkBullBossPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BullBossComponent.BullBoss == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		if(BullBossComponent.BullBoss.ActiveDamageCount <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BullBossComponent.BullBoss.ActiveDamageCount > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{	
		BullBossComponent.IgnoreBullBossInMovement(this, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		BullBossComponent.IgnoreBullBossInMovement(this, false);
	}
};
