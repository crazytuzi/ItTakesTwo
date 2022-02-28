import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;

class UPlayerBombBlockMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombBlockMovementCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerTimeBombComp PlayerComp;

	UCameraUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Ready || PlayerComp.TimeBombState == ETimeBombState::Spawned)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.TimeBombState != ETimeBombState::Ready && PlayerComp.TimeBombState != ETimeBombState::Losing && PlayerComp.TimeBombState != ETimeBombState::Spawned)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}
}