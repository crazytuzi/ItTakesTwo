
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunPursueSplineCapability: USwarmBehaviourCapability
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
			Settings.HitAndRun.PursueSpline.AnimSettingsDataAsset,
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
		MoveComp.MoveAlongSpline(Settings.HitAndRun.PursueSpline.FollowSplineSpeed, DeltaSeconds);

		if(VictimComp.FindClosestLivingPlayerWithinRange(Settings.HitAndRun.PursueSpline.CloseEnoughToPlayerRadius) != nullptr)
			PrioritizeState(ESwarmBehaviourState::CirclePlayer);

		BehaviourComp.FinalizeBehaviour();
	}

}
































