import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmHammerBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class USwarmHammerGentlemanCapability : USwarmHammerBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Gentleman;

	float TimeStampVictimUpdate = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ensure(SwarmActor != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;
		
		if(!IsAtleastOnePlayerAttackable())
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
            Settings.Hammer.Gentleman.AnimSettingsDataAsset,
			this,
			2.f
		);

		AHazePlayerCharacter NewVictim = VictimComp.PlayerVictim;
		if (NewVictim == nullptr)
			NewVictim = VictimComp.FindClosestLivingPlayerWithinRange();

		// might be null if both players are dead?
		if(NewVictim != nullptr)
		{
			if(ShouldSwapVictim(NewVictim))
				NewVictim = VictimComp.PlayerVictim.OtherPlayer;

			RequestPlayerVictim(NewVictim);
		}

		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VictimComp.RemoveClosestPlayerOverride(this);
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		if (VictimComp.PlayerVictim == nullptr)
		{
			RequestPlayerVictim(VictimComp.FindClosestLivingPlayerWithinRange());
		}
		else
		{
			UpdateMovement_TelegraphInit(DeltaSeconds);

			// We don't allow any gentleman formation during the hammer
			// encounter, So we limit the amount of telegraphers to 1
			if (SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
				PrioritizeState(ESwarmBehaviourState::TelegraphInitial);
			else
				SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphInitial, 1);
		}

		BehaviourComp.FinalizeBehaviour();
	}

	void RequestPlayerVictim(AHazePlayerCharacter InNewOverride)
	{
		if (InNewOverride == nullptr)
			return;

		VictimComp.OverrideClosestPlayer(InNewOverride, this);
		TimeStampVictimUpdate = Time::GetGameTimeSeconds();
	}

	bool ShouldSwapVictim(AHazePlayerCharacter InCurrentVictim) const
	{
		if(!VictimComp.IsPlayerAliveAndGrounded(InCurrentVictim.OtherPlayer))
			return false;

		// if(!SwarmActor.IsClaimable(ESwarmBehaviourState::TelegraphInitial, InCurrentVictim.OtherPlayer))
		// 	return false;

		// const float TimeSinceVictimUpdate = Time::GetGameTimeSince(TimeStampVictimUpdate);
		// if(TimeSinceVictimUpdate > 3.f)
		// 	return true;

		return false;
	}

}











