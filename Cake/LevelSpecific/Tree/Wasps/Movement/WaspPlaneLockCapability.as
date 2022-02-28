import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;
import Vino.Movement.PlaneLock.PlaneLockProcessor;

// Wasp flight which will be constrained to plane through destination with scenepoint right vector as normal 
class UWaspPlaneLockCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Flying");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

    UWaspBehaviourComponent BehaviourComp;
	UPlaneLockUserComponent PlaneLockComp;
	UPlaneLockProcessor PlaneLockProcessor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		PlaneLockComp = UPlaneLockUserComponent::Get(Owner);
		ensure((BehaviourComp != nullptr) && (PlaneLockComp != nullptr));

		PlaneLockProcessor = UPlaneLockProcessor();
		PlaneLockProcessor.PlaneLockComp = PlaneLockComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.CurrentScenepoint == nullptr)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.CurrentScenepoint == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
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

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FPlaneConstraintSettings PlaneConstraint;
		PlaneConstraint.Normal = BehaviourComp.CurrentScenepoint.RightVector;
		PlaneConstraint.Origin = BehaviourComp.CurrentScenepoint.WorldLocation;
		PlaneLockComp.LockOwnerToPlane(PlaneConstraint);
	}
};
