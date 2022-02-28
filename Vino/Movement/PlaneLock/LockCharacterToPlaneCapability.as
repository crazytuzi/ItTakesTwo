import Vino.Movement.PlaneLock.PlaneLockProcessor;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;

class ULockCharacterToPlaneCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 99;
	default SeperateInactiveTick(ECapabilityTickGroups::BeforeMovement, 100);

	UPlaneLockProcessor PlaneLockProcessor;

	UPlaneLockUserComponent PlaneLockComp;
	UHazeBaseMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		PlaneLockComp = UPlaneLockUserComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::GetOrCreate(Owner);
		PlaneLockProcessor = UPlaneLockProcessor();
		PlaneLockProcessor.PlaneLockComp = PlaneLockComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlaneLockComp.IsActiveltyConstraining())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlaneLockComp.IsActiveltyConstraining())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.UseDeltaProcessor(PlaneLockProcessor, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoveComp.StopDeltaProcessor(this);
	}
}
