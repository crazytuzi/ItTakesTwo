import Vino.Movement.Components.MovementComponent;

class UAnimationSheetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CapabilityBlocking");
	default CapabilityTags.Add(n"EventAnimation");
	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

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
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Owner.TriggerMovementTransition(this);
	}

    UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Owner.TriggerMovementTransition(this);
	}
}