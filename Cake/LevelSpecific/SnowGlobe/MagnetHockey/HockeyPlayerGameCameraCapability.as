import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;
import Vino.Camera.Capabilities.CameraTags;

class UHockeyPlayerGameCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerGameCameraCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	float MinDistance = 1300.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::Countdown)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.HockeyPlayerState != EHockeyPlayerState::InPlay)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;

		PlayerComp.GameCamera.ActivateCamera(Player, Blend, this);

		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);

		// Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
		PlayerComp.GameCamera.DeactivateCamera(Player, 1.5f);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Fast);
		// Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
	}
}