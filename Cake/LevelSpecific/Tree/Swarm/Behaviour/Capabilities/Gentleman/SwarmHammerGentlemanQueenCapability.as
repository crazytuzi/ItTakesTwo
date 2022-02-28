import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Gentleman.SwarmHammerGentlemanCapability;

class USwarmHammerGentlemanQueenCapability : USwarmHammerGentlemanCapability
{
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
		else if(ShouldSwapVictim(NewVictim))
			NewVictim = NewVictim.OtherPlayer;

		if(NewVictim != nullptr)
			RequestPlayerVictim(NewVictim);

		BehaviourComp.NotifyStateChanged();
	}

	bool ShouldSwapVictim(AHazePlayerCharacter InCurrentVictim) const override
	{
		if(!VictimComp.IsPlayerAliveAndGrounded(InCurrentVictim.OtherPlayer))
			return false;

		if(VictimComp.IsPlayerGrinding(InCurrentVictim.OtherPlayer))
			return false;

		return true;

		// if(!SwarmActor.IsClaimable(ESwarmBehaviourState::TelegraphInitial, InCurrentVictim.OtherPlayer))
		// 	return false;

		// const float TimeSinceVictimUpdate = Time::GetGameTimeSince(TimeStampVictimUpdate);
		// if(TimeSinceVictimUpdate > 3.f)
		// 	return true;
	}

}











