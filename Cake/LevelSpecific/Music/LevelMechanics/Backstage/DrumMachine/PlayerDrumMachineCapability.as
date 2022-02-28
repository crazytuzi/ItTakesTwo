import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.PlayerDrumMachineComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;

class UPlayerDrumMachineCapability : UHazeCapability
{
	UPlayerDrumMachineComponent DrumComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DrumComp = UPlayerDrumMachineComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(DrumComp.DrumMachine == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Owner.BlockCapabilities(MovementSystemTags::Jump, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DrumComp.DrumMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
	}
}
