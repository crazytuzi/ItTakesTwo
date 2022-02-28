import Vino.PlayerHealth.PlayerHealthComponent;

class UPlayerDieCapability : UHazeCapability
{
	default RespondToEvent(n"NeverActivate");

    default CapabilityTags.Add(n"CanDie");
    default CapabilityTags.Add(n"Death");
	default CapabilityDebugCategory = n"Health";

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		return EHazeNetworkActivation::DontActivate;
	}

	void Update()
	{
		HealthComp.bDeathBlocked = IsBlocked();
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		Update();
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		Update();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Update();
	}
};