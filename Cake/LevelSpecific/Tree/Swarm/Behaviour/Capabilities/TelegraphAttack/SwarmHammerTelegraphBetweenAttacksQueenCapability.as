
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.TelegraphAttack.SwarmHammerTelegraphBetweenAttacksCapability;

class USwarmHammerTelegraphBetweenAttacksQueenCapability : USwarmHammerTelegraphBetweenAttacksCapability
{


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphBetween))
			return EHazeNetworkActivation::DontActivate;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkActivation::DontActivate;

		// Victim, States and Claims are already synced. No need to activeFromControl atm.
		return EHazeNetworkActivation::ActivateLocal;
		// return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		// Need to merge override with claiming
		// if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphBetween))
		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Hammer.TelegraphBetween.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}











