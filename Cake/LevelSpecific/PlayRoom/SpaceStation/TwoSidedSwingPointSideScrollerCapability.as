
class UTwoSidedSwingPointSideScrollerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"TwoSidedSwingPointSideScroller"))
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"TwoSidedSwingPointSideScroller"))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		// Player.BlockCapabilities(n"SwingingDetach", this);
		// Player.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		// Player.UnblockCapabilities(n"SwingingDetach", this);
		// Player.UnblockCapabilities(n"Respawn", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::SwingJump);
	}
}