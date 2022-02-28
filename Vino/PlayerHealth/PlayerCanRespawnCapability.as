import Vino.PlayerHealth.PlayerRespawnComponent;

class UPlayerCanRespawnCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Respawn");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerRespawnComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		RespawnComp.bRespawnBlocked = IsBlocked();
	}
};