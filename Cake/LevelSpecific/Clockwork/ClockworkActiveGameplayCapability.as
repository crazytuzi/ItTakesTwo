import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;

class UClockworkActiveGameplayCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::ActiveGameplay);

	default CapabilityDebugCategory = CapabilityTags::ActiveGameplay;

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UTimeControlComponent TimeComp;
	UTimeControlSequenceComponent SeqComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TimeComp = UTimeControlComponent::Get(Player);
		SeqComp = UTimeControlSequenceComponent::Get(Player);
	}


	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(TimeComp != nullptr)
		{

		}

		if(SeqComp != nullptr)
		{
			// SeqComp.DeactiveClone(Player);''
		}
	}
}