
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmHammerBehaviourCapability;

class USwarmHammerTelegraphInitialAttackCapability : USwarmHammerBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphInitial;

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

		// if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.TelegraphInitial.AnimSettingsDataAsset,
			this,
			Settings.Hammer.TelegraphInitial.BlendInTime
		);

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);
		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);

		// (victim might be dead)
		if(VictimComp.CurrentVictim != nullptr)
			SwarmActor.UnclaimVictim(ESwarmBehaviourState::TelegraphInitial);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		// Request attack once we've telegraphed long enough.
		const float TimeElapsed = BehaviourComp.GetStateDuration();
		if (TimeElapsed >= Settings.Hammer.TelegraphInitial.TelegraphingTime)
		{
			if (SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
			{
				PrioritizeState(ESwarmBehaviourState::Attack);
			}
			else if(SwarmActor.IsVictimClaimable(ESwarmBehaviourState::Attack))
			{
				SwarmActor.ClaimVictim(ESwarmBehaviourState::Attack, 1);
			}
			else if(SwarmActor.IsOtherVictimClaimable(ESwarmBehaviourState::Attack))
			{
				SwarmActor.ClaimOtherVictim(ESwarmBehaviourState::Attack, 1);
				VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
			}
			else
			{
				PrioritizeState(ESwarmBehaviourState::PursueSpline);
			}
		}
		
		UpdateMovement_TelegraphInit(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

}











