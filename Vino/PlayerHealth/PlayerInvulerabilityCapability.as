import Vino.PlayerHealth.PlayerHealthStatics;

class UPlayerInvulnerabilityCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerInvulnerable");

	default CapabilityDebugCategory = n"Health";

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			AddPlayerInvulnerability(Player, this);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			RemovePlayerInvulnerability(Player, this);
	}
}