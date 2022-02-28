

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmSwordIdleCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Idle;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Sword.Idle.AnimSettingsDataAsset,
			this,
			Settings.Sword.TelegraphInitial.TelegraphingTime
		);

		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{

		// in case our target jumps off or starts grinding
		if (!VictimComp.IsVictimAliveAndGrounded() || VictimComp.IsVictimGrinding())
		{
			auto May = Game::GetMay();
			auto Cody = Game::GetCody();
			AHazePlayerCharacter ClosestPlayerOverride = VictimComp.PlayerVictim == May ? Cody : May;
			VictimComp.OverrideClosestPlayer(ClosestPlayerOverride, this);
		}

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
