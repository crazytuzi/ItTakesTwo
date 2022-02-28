import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.PlayerDrumMachineComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;

class UPlayerDrumMachinePressButtonCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = n"LevelSpecific";

	UPlayerDrumMachineComponent DrumComp;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;

	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DrumComp = UPlayerDrumMachineComponent::Get(Owner);
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

		if(MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;
		
		if(WasActionStarted(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Owner.BlockCapabilities(MovementSystemTags::Jump, this);
		Owner.BlockCapabilities(MovementSystemTags::Dash, this);
		Owner.BlockCapabilities(MovementSystemTags::Crouch, this);

		Elapsed = DrumComp.PreventMovementTime;

		if(DrumComp.PressButtonAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = DrumComp.PressButtonAnimation;
			AnimParams.BlendTime = DrumComp.BlendTime;
			Player.PlaySlotAnimation(AnimParams);
		}

		if(DrumComp.DrumMachine != nullptr && HasControl())
		{
			DrumComp.DrumMachine.ToggleButton(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DrumComp.DrumMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Elapsed < 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
		Owner.UnblockCapabilities(MovementSystemTags::Dash, this);
		Owner.UnblockCapabilities(MovementSystemTags::Crouch, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;
	}
}
