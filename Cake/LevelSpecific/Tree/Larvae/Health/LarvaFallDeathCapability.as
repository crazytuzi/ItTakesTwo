import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;

class ULarvaFallDeathCapability : UHazeCapability
{
	ULarvaBehaviourComponent BehaviourComp;
	ULarvaMovementDataComponent MoveDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = ULarvaBehaviourComponent::Get(Owner);
		MoveDataComp = ULarvaMovementDataComponent::Get(Owner);
		ensure((BehaviourComp != nullptr) && (MoveDataComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;
		if (MoveDataComp.HatchPoint == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (Owner.ActorLocation.Z > MoveDataComp.HatchPoint.WorldLocation.Z - 1000.f)
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// We never need to tick
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BehaviourComp.Explode();
	}
}
