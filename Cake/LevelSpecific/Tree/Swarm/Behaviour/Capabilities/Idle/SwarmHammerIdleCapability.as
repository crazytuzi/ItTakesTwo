
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHammerIdleCapability : USwarmBehaviourCapability
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
			Settings.Hammer.Idle.AnimSettingsDataAsset,
			this
			,2.f // procedural animation need more time
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
		// We'll either go searching for the player 
		if (MoveComp.HasSplineToFollow())
		{
			PrioritizeState(ESwarmBehaviourState::Search);
		}
		// or wait for one of them to come to us.
		else if(VictimComp.PlayerVictim != nullptr)
		{
			PrioritizeState(ESwarmBehaviourState::PursueSpline);
		}

		BehaviourComp.FinalizeBehaviour();
 	}
}
