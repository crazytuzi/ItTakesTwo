import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

/*	This capability is used to apply all outside-made rotations to the
	internal orientation structure */
class UFlyingMachineApplyRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;
	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

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

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Machine.Orientation.SetFromRotator(Machine.GetActorRotation());
	}
}