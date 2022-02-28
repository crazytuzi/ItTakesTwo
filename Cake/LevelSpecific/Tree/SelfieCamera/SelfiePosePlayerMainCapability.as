import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePosePlayerComp;

class USelfiePosePlayerMainCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfiePosePlayerMainCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USelfiePosePlayerComp PlayerComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USelfiePosePlayerComp::Get(Player);
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

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(n"Death", this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
    }
}