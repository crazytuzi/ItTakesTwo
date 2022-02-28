import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
class UCurlingPlayerAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerAnimationCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UCurlingPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Default)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Default)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
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
		if (!Player.Mesh.CanRequestLocomotion())
			return;

		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"Curling";
		Player.RequestLocomotion(AnimRequest);
	}
}