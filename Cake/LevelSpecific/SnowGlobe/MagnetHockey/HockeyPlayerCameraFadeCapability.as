import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;
import Peanuts.Fades.FadeStatics;

class UHockeyPlayerCameraFadeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerCameraFadeCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	FHazeAcceleratedRotator AcceleratedRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::ResetNextPlay)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.HockeyPlayerState != EHockeyPlayerState::ResetNextPlay)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// FadeOutPlayer(Player, 1.f, 0.5f, 0.5f); 
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}