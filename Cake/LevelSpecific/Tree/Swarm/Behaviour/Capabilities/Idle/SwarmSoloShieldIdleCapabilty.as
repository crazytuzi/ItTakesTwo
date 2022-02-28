
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmSoloShieldIdleCapability : USwarmBehaviourCapability
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
            Settings.SoloShield.Idle.AnimSettingsDataAsset,
			this,
            Settings.SoloShield.TelegraphDefence.TelegraphTime
		);

		BehaviourComp.NotifyStateChanged();

		PrioritizeState(ESwarmBehaviourState::TelegraphDefence);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}
}
