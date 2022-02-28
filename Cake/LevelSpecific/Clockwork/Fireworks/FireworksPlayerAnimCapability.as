import Cake.LevelSpecific.Clockwork.Fireworks.FireworksPlayerComponent;

class UFireworksPlayerAnimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FireworksPlayerAnimCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;

	UFireworksPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
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
		// Player.TriggerMovementTransition(this);
		// Player.CleanupCurrentMovementTrail();

		// Player.SmoothSetLocationAndRotation();
		
		if (Player == Game::GetMay())
			Player.AddLocomotionFeature(PlayerComp.MayLocomotion);
		else 
			Player.AddLocomotionFeature(PlayerComp.CodyLocomotion);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Player == Game::GetMay())
			Player.RemoveLocomotionFeature(PlayerComp.MayLocomotion);
		else 
			Player.RemoveLocomotionFeature(PlayerComp.CodyLocomotion);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"Fireworks";

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(AnimRequest);
	}
}