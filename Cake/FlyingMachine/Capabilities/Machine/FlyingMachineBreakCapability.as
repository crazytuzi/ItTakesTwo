import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineBreakCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Break);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 101;
	default CapabilityDebugCategory = n"FlyingMachine";

	bool bShouldActivate = false;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;

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

		if (!IsActioning(FlyingMachineAction::Break))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!IsActioning(FlyingMachineAction::Break))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set speed
		Machine.Speed = FMath::Lerp(Machine.Speed, Settings.BreakSpeed, Settings.BreakLerpCoefficient * DeltaTime);
	}
}