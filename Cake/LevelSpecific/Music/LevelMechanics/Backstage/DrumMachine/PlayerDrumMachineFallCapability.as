import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.PlayerDrumMachineComponent;
import Vino.Movement.Components.MovementComponent;

/*
Toggle a button on the drum machines when landing on them.
*/

class UPlayerDrumMachineFallCapability : UHazeCapability
{
	UPlayerDrumMachineComponent DrumComp;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DrumComp = UPlayerDrumMachineComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(DrumComp.DrumMachine == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DrumComp.DrumMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DrumComp.DrumMachine != nullptr && HasControl())
		{
			//DrumComp.DrumMachine.ToggleButton(Player);
		}
	}
}
