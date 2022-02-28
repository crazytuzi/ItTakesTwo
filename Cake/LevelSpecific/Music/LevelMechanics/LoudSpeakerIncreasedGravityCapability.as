import Vino.Movement.MovementSettings;

class ULoudSpeakerIncreasedGravityCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"LoudSpeakerGravity");

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMovementSettings MoveSettings;

	// 6.1 is default multiplier for the players
	UPROPERTY()
	float DesiredGravityMultiplier = 12.2f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveSettings = UMovementSettings::GetSettings(Owner);
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
		UMovementSettings::SetGravityMultiplier(Player, DesiredGravityMultiplier, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearSettingsByInstigator(this);
	}
}