import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;
class UAxeThrowingPlayerLocoCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingPlayerLocoCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;

	UAxeThrowingPlayerComp PlayerComp;

    FHazeRequestLocomotionData AnimationRequestMay;
    FHazeRequestLocomotionData AnimationRequestCody;

	bool bRemovedLocomotion;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UAxeThrowingPlayerComp::Get(Player);
		
		AnimationRequestMay.AnimationTag = n"IceTapThrow";
		AnimationRequestCody.AnimationTag = n"IceTapThrow";

		bRemovedLocomotion = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::InPlay)
       	 	return EHazeNetworkActivation::ActivateFromControl;

		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::BeforePlay)
       	 	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::WinnerAnnouncement)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::Inactive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (Player == Game::GetMay())
			Player.AddLocomotionFeature(PlayerComp.IcicleFeatureMay);
		else
			Player.AddLocomotionFeature(PlayerComp.IcicleFeatureCody);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		if (Player == Game::GetMay())
			Player.RemoveLocomotionFeature(PlayerComp.IcicleFeatureMay);
		else
			Player.RemoveLocomotionFeature(PlayerComp.IcicleFeatureCody);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (PlayerComp == nullptr)
			return;

		if (PlayerComp.bGameFinished && !bRemovedLocomotion)
		{
			bRemovedLocomotion = true;

			if (Player == Game::GetMay())
				Player.RemoveLocomotionFeature(PlayerComp.IcicleFeatureMay);
			else
				Player.RemoveLocomotionFeature(PlayerComp.IcicleFeatureCody);

			return;
		}

		if (Player.Mesh.CanRequestLocomotion())
		{
			if (Player == Game::May)
				Player.RequestLocomotion(AnimationRequestMay);
			else
				Player.RequestLocomotion(AnimationRequestCody);
		}
	}
}