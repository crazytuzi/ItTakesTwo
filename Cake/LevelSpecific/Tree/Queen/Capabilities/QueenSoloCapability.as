
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenSoloCapability : UQueenBaseCapability 
{
	ASwarmActor Swarm = nullptr;
	float SwapToShieldTimer = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Solo)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.BehaviourComp.State != EQueenManagerState::Solo)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		if (Queen.HasControl())
		{
			SwapToShieldTimer = 0;
			Swarm = Queen.BehaviourComp.Swarms.Last();

			Swarm.VictimComp.OverrideClosestPlayer(Game::GetMay(), this);

			if(Swarm.BehaviourComp.DefaultBehaviourSheet == Settings.Abilities.Shield.SwarmSheet)
			{
				return;
			}
			else
			{
				NetSwitchToHandSmash(Swarm);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Swarm.VictimComp.RemoveClosestPlayerOverride(this);
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (Queen.HasControl())
		{
			if(Swarm.BehaviourComp.DefaultBehaviourSheet == Settings.Abilities.Shield.SwarmSheet)
			{
				SwapToShieldTimer += DeltaSeconds;

				if (SwapToShieldTimer > 8)
				{
					NetSwitchToHandSmash(Swarm);
				}
			}
		}
		
	}

}