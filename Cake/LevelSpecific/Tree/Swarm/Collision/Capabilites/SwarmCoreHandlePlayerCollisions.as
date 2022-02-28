

import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageResponseCapability;

class USwarmCoreHandlePlayerCollisionsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCollision");
	default CapabilityTags.Add(n"SwarmCollisionPlayer");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ASwarmActor SwarmActor = nullptr;

	FSwarmForceField ForceField;
	default ForceField.bLinearFalloff = false;
	default ForceField.Radius = 150.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SwarmActor.VictimComp.bCanAttackVictim == false && SwarmActor.VictimComp.bCanAlwaysAttackVictim == false)
			return EHazeNetworkActivation::DontActivate;

		if (SwarmActor.IsAboutToDie())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SwarmActor.VictimComp.bCanAttackVictim == false && SwarmActor.VictimComp.bCanAlwaysAttackVictim == false)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(SwarmActor.IsAboutToDie())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// We add it here - and not in setup - because the swarm 
		// might deactivate itself and leave the team after setup
		if(SwarmActor.BehaviourComp.Team != nullptr)
			SwarmActor.BehaviourComp.Team.AddPlayersCapability( USwarmPlayerTakeDamageResponseCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		TArray<AHazePlayerCharacter> OverlappedPlayers;
		if(SwarmActor.FindPlayersIntersectingSwarmBones(OverlappedPlayers))
		{
			for(int i = OverlappedPlayers.Num() - 1; i >= 0; --i)
			{
				// let player know about the attack
				OverlappedPlayers[i].SetCapabilityActionState(n"SwarmAttack", EHazeActionState::ActiveForOneFrame);
				OverlappedPlayers[i].SetCapabilityAttributeObject(n"SwarmAttacker", Owner);

				// Apply radial (visual) impulse to swarm
				ForceField.Strength = 500000.f * DeltaTime * 2.f;
				const FVector ForceFieldLocation = OverlappedPlayers[i].GetActorCenterLocation();
				SwarmActor.AddForceFieldAcceleration(ForceFieldLocation, ForceField);

				// notify others of the event
				SwarmActor.VictimComp.OnVictimHitBySwarm.Broadcast(OverlappedPlayers[i]);
			}

			SwarmActor.BehaviourComp.ReportAttack();
		}
	}
}


