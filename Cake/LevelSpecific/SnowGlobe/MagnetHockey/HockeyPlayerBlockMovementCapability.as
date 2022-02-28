import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

class UHockeyPlayerBlockMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerBlockMovementCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::MovementBlocked)
        // 	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if (PlayerComp.HockeyPlayerState != EHockeyPlayerState::MovementBlocked)
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"IceSkating", this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(FMagneticTags::MagneticCapabilityTag, this);

		Player.CleanupCurrentMovementTrail();
		// Player.SmoothSetLocationAndRotation(Player.ActorLocation, PlayerComp.SmoothRotation, 1.8f, 1.8f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(n"IceSkating", this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(FMagneticTags::MagneticCapabilityTag, this);
    }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	// {

	// }
}