import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;

class UPlayerFishingLocomotionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingBlockingCapability");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
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
		if (Player == Game::GetMay())
			Player.AddLocomotionFeature(PlayerComp.MayLocomotion);
		else
			Player.AddLocomotionFeature(PlayerComp.CodyLocomotion);

		Player.TriggerMovementTransition(this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (Player == Game::GetMay())
			Player.RemoveLocomotionFeature(PlayerComp.MayLocomotion);
		else
			Player.RemoveLocomotionFeature(PlayerComp.CodyLocomotion);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData LocoMotionRequestData;
		LocoMotionRequestData.AnimationTag = n"FishingMinigame";
		Player.RequestLocomotion(LocoMotionRequestData);
	}
}