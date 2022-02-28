import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;
import Vino.Movement.Helpers.BurstForceStatics;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

class UClockworkBullBossPlayerStunnedCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBossTakeDamage);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 9; // 1 before take damage

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	UClockWorkBullBossPlayerComponent BullBossComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		BullBossComponent = UClockWorkBullBossPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
			
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(ClockworkBullBossTags::ClockworkBullBossStunned))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ClockworkBullBossTags::ClockworkBullBossStunned))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& Params)
	{
		//BullBossComponent.BullBoss.IgnoreMovementCollision(PlayerOwner, true);

		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);
		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeDiliationCapability, this);
		PlayerOwner.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);

		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		//BullBossComponent.BullBoss.IgnoreMovementCollision(PlayerOwner, false);

		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);
		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeDiliationCapability, this);
		PlayerOwner.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);

		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveComp.SetAnimationToBeRequested(n"TakeBullBossDamageStunned");	
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "\n";
		return Str;
	} 
};
