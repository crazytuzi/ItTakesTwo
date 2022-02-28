import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;

class UWhackACodyCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackaComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"NailThrow", this);
		Player.BlockCapabilities(n"HammeredPlayer", this);
		Player.BlockCapabilities(n"NailRecall", this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.ActivateCamera(WhackaComp.WhackABoardRef.Camera, CameraBlend::Normal(1.f), this);

		if (Player.IsCody())
			Game::May.DisableOutlineByInstigator(this);

		auto Board = WhackaComp.WhackABoardRef;
		Board.DoubleInteract.StartInteracting(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"NailThrow", this);
		Player.UnblockCapabilities(n"HammeredPlayer", this);
		Player.UnblockCapabilities(n"NailRecall", this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DeactivateCameraByInstigator(this);

		if (Player.IsCody())
			Game::May.EnableOutlineByInstigator(this);
	}
}