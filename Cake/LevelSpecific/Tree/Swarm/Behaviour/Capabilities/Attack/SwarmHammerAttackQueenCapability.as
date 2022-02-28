import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmHammerAttackCapability;

class USwarmHammerAttackQueenCapability : USwarmHammerAttackCapability
{
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
			return EHazeNetworkActivation::DontActivate;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkActivation::DontActivate;

		// Victim, States and Claims are already synced. No need to activeFromControl atm.
		// return EHazeNetworkActivation::ActivateFromControl;
		return EHazeNetworkActivation::ActivateLocal;
	}

	void HandleAttackPerformed() override
	{
		////
		// The difference here is that we switched to gentleman instead of recover and we removed switch to pursuemiddle
		////

		++NumAttacksPerformedTotal;
		++NumAttacksPerformedConsecutively;

		if(IsBlocked() || !IsActive())
		{
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
			return;
		}

		if (NumAttacksPerformedTotal >= Settings.Hammer.Attack.NumTotalAttacks)
		{
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
			PrioritizeState(ESwarmBehaviourState::Gentleman);
		} 
		else if (NumAttacksPerformedConsecutively >= Settings.Hammer.Attack.NumConsecutiveAttacks)
		// else if (VictimComp.CurrentVictim.HasControl() && NumAttacksPerformedConsecutively >= Settings.Hammer.Attack.NumConsecutiveAttacks)
		{
			const bool bAliveAndGrounded = VictimComp.IsVictimAliveAndGrounded();
			const bool bTelegraphIsClaimable = SwarmActor.IsVictimClaimable(ESwarmBehaviourState::TelegraphBetween);
			if(bAliveAndGrounded && bTelegraphIsClaimable)
			{
				SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphBetween, 1);
				PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
				// NetSwitchToTelegraphBetween();
			}
		}
		else 
		// else if(VictimComp.CurrentVictim.OtherPlayer.HasControl())
		{
			// alternate victim, every attack, if they are close enough to each other
			const float DistBetweenPlayers_SQ = Game::GetDistanceSquaredBetweenPlayers();
			const float DistThreshold_SQ = FMath::Square(Settings.Hammer.Attack.AlternateVictimDistanceBetweenPlayers);
			const bool bOtherVictimIsClaimable = SwarmActor.IsOtherVictimClaimable(ESwarmBehaviourState::Attack);
			if(DistBetweenPlayers_SQ <= DistThreshold_SQ && bOtherVictimIsClaimable)
			{
				SwarmActor.ClaimOtherVictim(ESwarmBehaviourState::Attack, 1);
				VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
				// NetSwitchPlayerVictim();
			}
		}
	}

}