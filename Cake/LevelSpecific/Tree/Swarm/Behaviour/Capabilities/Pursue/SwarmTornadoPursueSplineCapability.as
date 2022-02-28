
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmTornadoPursueSplineCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::PursueSpline;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
 			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Tornado.PursueSpline.AnimSettingsDataAsset,
			this
		);

		BehaviourComp.NotifyStateChanged();
		MoveComp.InitMoveAlongSpline();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Pursue along spline 
		MoveComp.MoveAlongSpline(Settings.Tornado.PursueSpline.BaseSpeed, DeltaSeconds);

		// We'll do this until LVL BP switches behaviour. 
		BehaviourComp.FinalizeBehaviour();
	}

}
































