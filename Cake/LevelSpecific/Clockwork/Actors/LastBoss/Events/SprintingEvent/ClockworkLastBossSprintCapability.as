import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;

/* 
	Forcing the Characters to sprint 
	This is used during the last part of
	the Clockwork Boss.
*/

class UClockworkLastBossSprintCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossSprintCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkLastBossSprintCapability";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	UMovementSettings MoveSettings;

	UPROPERTY()
	USprintSettings SprintSettings;

	UPROPERTY()
	UCharacterAirDashSettings AirDashSettings;

	AHazePlayerCharacter Player;
	UCharacterSprintComponent SprintComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);	
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SprintComp = UCharacterSprintComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"ClockBossSprint"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ClockBossSprint"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SprintComp.ForceSprint(this);
		Player.ApplySettings(MoveSettings, this);
		Player.ApplySettings(SprintSettings, this);
		Player.ApplySettings(AirDashSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SprintComp.ClearForceSprint(this);
		Player.ClearSettingsByInstigator(this);
	}
}