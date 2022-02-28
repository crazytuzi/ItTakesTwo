import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingInteractStart;

class UCurlingPlayerInteractCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerInteractCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCurlingPlayerInteractComponent PlayerInteractComp;
	ACurlingInteractStart InteractStart;

	bool bShowCancel;

	FRotator RotationTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		PlayerInteractComp = UCurlingPlayerInteractComponent::Get(Player);
		bShowCancel = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}