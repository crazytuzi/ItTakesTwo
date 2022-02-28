import Vino.Movement.MovementSystemTags;
class USunChairBlockMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SunChairBlockMovementCapability");
	default CapabilityTags.Add(n"SunChair");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Player.BlockCapabilities(MovementSystemTags::Dash, this);
		// Player.BlockCapabilities(MovementSystemTags::Jump, this);
		// Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		// Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		// Player.BlockCapabilities(MovementSystemTags::Grinding, this);
		// Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		// Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		// Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		// Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		// Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		// Player.UnblockCapabilities(MovementSystemTags::Grinding, this);
		// Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
    }
}