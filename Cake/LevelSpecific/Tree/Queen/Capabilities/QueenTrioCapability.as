
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenTrioCapability : UQueenBaseCapability 
{
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Trio)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Trio)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		if (Queen.HasControl())
		{
			ASwarmActor SwarmHand1 = Queen.BehaviourComp.Swarms[0];
			NetSwitchToHandSmash(SwarmHand1, ShouldUseRightHand(SwarmHand1.VictimComp.CurrentVictim));

			ASwarmActor SwarmHand2 = Queen.BehaviourComp.Swarms[1];
			NetSwitchToHandSmash(SwarmHand2, ShouldUseRightHand(SwarmHand2.VictimComp.CurrentVictim));

			NetSwitchToShield(Queen.BehaviourComp.Swarms[2]);
		}
	}
}