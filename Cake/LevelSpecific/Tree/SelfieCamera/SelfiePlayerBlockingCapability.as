import Vino.Movement.MovementSystemTags;
import Cake.Weapons.Sap.SapWeaponNames;
import Vino.Camera.Capabilities.CameraTags;

class USelfiePlayerBlockingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfiePlayerBlockingCapability");
	default CapabilityTags.Add(n"SelfieCamera");

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
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
	}
}