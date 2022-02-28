// Overrides cody jog state machine in snowglobe to avoid playing incompatible idle animations
class USnowglobeCodyJogSMOverrideCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SnowGlobeCodyJogSMOverride");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY()
	UHazeLocomotionAssetBase JogLocomotionOverride;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsCody())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.AddLocomotionAsset(JogLocomotionOverride, this, 80);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Only deactivates when snowglobe sheet is removed
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.RemoveLocomotionAsset(JogLocomotionOverride, this);
	}
}