
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

// This capability solves the problem of swarm attacking the same "area" due
// to both players sharing that area. We'll merge players GentlemanFightingCompData
// when the players are close to each other and use that 

class UQueenUpdateSharedGentlemanFightingCapability : UQueenBaseCapability 
{
	const float ThresholdSQ = FMath::Square(1500.f);

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.BehaviourComp.Swarms.Num() <= 1)
			return EHazeNetworkActivation::DontActivate;

		if(!UseSharedGentlemanFighting())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.BehaviourComp.Swarms.Num() <= 1)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!UseSharedGentlemanFighting())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(const FCapabilityActivationParams& ActivationParams)
 	{
		for(ASwarmActor Swarm : Queen.BehaviourComp.Swarms)
		{
			Swarm.VictimComp.ActivateSharedGentlemanBehaviour();
		}
		Queen.BehaviourComp.OnSwarmSpawned.AddUFunction(this, n"HandleSwarmSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for(ASwarmActor Swarm : Queen.BehaviourComp.Swarms)
		{
			Swarm.VictimComp.DeactivateSharedGentlemanBehaviour();
		}

		Queen.BehaviourComp.OnSwarmSpawned.Unbind(this, n"HandleSwarmSpawned");
	}

	UFUNCTION()
	void HandleSwarmSpawned(ASwarmActor InSwarm)
	{
		InSwarm.VictimComp.ActivateSharedGentlemanBehaviour();
	}

	// We'll use shared if they are close enough
	bool UseSharedGentlemanFighting() const
	{
		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);
		const float DistSQ = May.ActorLocation.DistSquared(Cody.ActorLocation);

		// Print("Distance: " + FMath::Sqrt(DistSQ), Duration = 0.f);
		// FLinearColor DebugColor = DistSQ < ThresholdSQ ? FLinearColor::Green : FLinearColor::Red;
		// System::DrawDebugSphere(Cody.ActorLocation, FMath::Sqrt(ThresholdSQ), 12, DebugColor);

		return DistSQ < ThresholdSQ;
	}

};