import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;

class UHockeyPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerCancelCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && PlayerComp.bCanCancel)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.HockeyPaddle.OnHockeyPlayerLeftEvent.Broadcast(PlayerComp.HockeyPaddle.InteractComp, Player);
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