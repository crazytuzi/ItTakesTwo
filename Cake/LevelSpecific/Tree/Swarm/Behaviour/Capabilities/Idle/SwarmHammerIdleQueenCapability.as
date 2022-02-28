
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Idle.SwarmHammerIdleCapability;

class USwarmHammerIdleQueenCapability : USwarmHammerIdleCapability
{
	// Override because we want to check for grinding player
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
