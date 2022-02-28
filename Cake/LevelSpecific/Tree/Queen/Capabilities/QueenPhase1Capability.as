
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.GrabSpline.QueenGrabSplinePosComponent;

UCLASS()
class UQueenPhase1Capability : UQueenBaseCapability 
{
	bool bSpawnedHammer;
	float LastTimePlayerWasGrindingTimeStamp = 0.f;
	ASwarmActor Swarm = nullptr;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.QueenPhase == EQueenPhaseEnum::Phase1)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.QueenPhase != EQueenPhaseEnum::Phase1)
		{
			Queen.BehaviourComp.OnSwarmSpawned.Unbind(this, n"OnSwarmSpawned");
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(const FCapabilityActivationParams& ActivationParams)
 	{
		if (Queen.HasControl())
		{
			Queen.BehaviourComp.OnSwarmSpawned.AddUFunction(this, n"OnSwarmSpawned");
			Swarm = Queen.BehaviourComp.Swarms[0];
			NetSwitchToHammer(Swarm);
		}
	}

	UFUNCTION()
	void OnSwarmSpawned(ASwarmActor InSwarm)
	{
		Swarm = InSwarm;

		if (!bSpawnedHammer)
		{
			bSpawnedHammer = true;
			NetSwitchToHammer(Swarm);
		}
		else
		{
			NetSwitchToHandSmash(Swarm, ShouldUseRightHand(Swarm.VictimComp.CurrentVictim));
			bSpawnedHammer = false;
		}
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		if(!HasControl())
			return;

		if(Swarm == nullptr)
			return;

		// only switch when they are alive and can see it
		if(AreBothPlayersDead())
			return;

		// We'll switch to shield if players aren't attackable.
		// (which happens when they are grinding, jumping off the platform or dead)
		if(IsAtleastOnePlayerAttackable())
		{
			if(IsShield(Swarm))
			{
				// Switch back to previous shape
				if(Swarm.BehaviourComp.PreviousShape == ESwarmShape::Hammer)
				{
					NetSwitchToHammer(Swarm);
				}
				else
				{
					NetSwitchToHandSmash(Swarm, ShouldUseRightHand(Swarm.VictimComp.CurrentVictim));
				}
			}
		}
		else if (!IsShield(Swarm))
		{
			// Switch to shield while the remaining player is grinding
			NetSwitchToShield(Swarm);
		}
	}

}