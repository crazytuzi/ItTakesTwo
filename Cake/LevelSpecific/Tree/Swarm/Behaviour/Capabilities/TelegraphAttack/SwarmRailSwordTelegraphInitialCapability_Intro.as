
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.TelegraphAttack.SwarmRailSwordTelegraphInitialCapability;

class USwarmRailSwordTelegraphInitialAttackCapability_Intro : USwarmRailSwordTelegraphInitialAttackCapability
{
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);

		// flag that intro is done so that queen can start managing them
		ManagedSwarmComp.bIntroSwarm = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		//if (BehaviourComp.GetStateDuration() > 6.f)
		if (BehaviourComp.GetStateDuration() > Settings.RailSword.TelegraphInitial.TimeUntilWeSwitchState)
			PrioritizeState(ESwarmBehaviourState::Attack);

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}
}