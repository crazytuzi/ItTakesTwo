import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;

class UClockworkBirdDashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdDash");

	default CapabilityDebugCategory = n"ClockworkBirdFlying";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AClockworkBird Bird;
	UClockworkBirdFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
		Settings = UClockworkBirdFlyingSettings::GetSettings(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Bird.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Settings.DashCooldown)
			return EHazeNetworkActivation::DontActivate;
		
		if (!WasActionStarted(ClockworkBirdTags::ClockworkBirdFlap)) 
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.DashDuration) 
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird.bIsDashing = true;
		Bird.Boost(Settings.DashSpeedBoost, Settings.DashDuration);
		Bird.SetCapabilityActionState(n"AudioFlapWings", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bird.bIsDashing = false;
	}
}