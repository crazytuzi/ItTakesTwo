
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.TelegraphAttack.SwarmHammerTelegraphInitialAttackCapability;

class USwarmHammerTelegraphInitialAttackQueenCapability : USwarmHammerTelegraphInitialAttackCapability
{


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
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

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Hammer.TelegraphInitial.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		// if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}











