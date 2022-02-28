
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenDuoCapability : UQueenBaseCapability 
{
	bool bShouldRunDuoHands = true;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Duo)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Duo)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bShouldRunDuoHands = !bShouldRunDuoHands;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(const FCapabilityActivationParams& ActivationParams)
 	{
		if (Queen.HasControl())
		{
			EvaluateDuoSetup();
		}
		
	}

	void EvaluateDuoSetup()
	{
		if (bShouldRunDuoHands)
		{
			SetShieldAndHand();
		}
		else
		{
			SetDoubleHand();
		}
	}

	void SetShieldAndHand()
	{
		ASwarmActor SwarmHand = Queen.BehaviourComp.Swarms[0];
		ASwarmActor SwarmShield = Queen.BehaviourComp.Swarms[1];

		NetSwitchToShield(SwarmShield);
		NetSwitchToHandSmash(SwarmHand, ShouldUseRightHand(SwarmHand.VictimComp.CurrentVictim));

		SwarmShield.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);
	}

	void SetDoubleHand()
	{
		ASwarmActor SwarmHand_Left  = Queen.BehaviourComp.Swarms[0];
		ASwarmActor SwarmHand_Right = Queen.BehaviourComp.Swarms[1];

		SwarmHand_Right.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);
		SwarmHand_Left.VictimComp.OverrideClosestPlayer(Game::GetMay(), this);

		NetSwitchToHandSmash(SwarmHand_Right, ShouldUseRightHand(Game::GetCody()));
		NetSwitchToHandSmash(SwarmHand_Left, ShouldUseRightHand(Game::GetMay()));
	}
}