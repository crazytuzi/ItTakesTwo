
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmTornadoIdleCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Idle;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
 		SwarmActor.PlaySwarmAnimation(
 			Settings.Tornado.Idle.AnimSettingsDataAsset,
 			this,
 			Settings.Tornado.Idle.TelegraphTime
 		);
 
 		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		if (VictimComp.PlayerVictim != nullptr && 
			BehaviourComp.GetStateDuration() > Settings.Tornado.Idle.TelegraphTime)
		{
			PrioritizeState(ESwarmBehaviourState::PursueSpline);
		}

		BehaviourComp.FinalizeBehaviour();
 	}
}














