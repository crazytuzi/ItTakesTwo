import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Boost);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 101;
	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Flags if the boost should activate (set in PreTick)
	bool bShouldActivate = false;

	// Settings
	FFlyingMachineSettings Settings;
	float BoostPauseTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(FlyingMachineAction::Boost))
			return EHazeNetworkActivation::DontActivate;

		if (!FMath::IsNearlyEqual(Machine.BoostCharge, 1.f))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (FMath::IsNearlyZero(Machine.BoostCharge))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(FlyingMachineTag::Speed, this);

		Machine.CallOnStartBoostingEvent();
		Machine.OnBoost.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(FlyingMachineTag::Speed, this);

		Machine.CallOnStopBoostingEvent();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (BoostPauseTimer > 0.f)
			BoostPauseTimer -= DeltaTime;
		else
			Machine.RegainBoostCharge(DeltaTime / Settings.BoostRegenDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Machine.ConsumeBoostCharge(DeltaTime / Settings.BoostDuration);
		BoostPauseTimer = Settings.BoostRegenPause;

		if (Machine.Pilot.HasControl())
		{
			// Set speed
			Machine.Speed = Settings.BoostSpeed;
			Machine.Pilot.SetFrameForceFeedback(0.3f, 0.3f);
		}
	}
}