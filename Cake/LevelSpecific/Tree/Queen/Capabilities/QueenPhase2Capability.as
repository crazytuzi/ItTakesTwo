import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourSettingsContainer;

UCLASS()
class UQueenPhase2Capability : UQueenBaseCapability 
{

	bool bShouldRunPressureMode = false;
	bool bRunStartSpawningTimer = false;
	bool bShouldRunHammer = false;
	float StartSpawningTimer = 0;
	const float SpawningTimerLength = 10;
	const float TurnShieldToSwordTimer = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.QueenPhase == EQueenPhaseEnum::Phase2)
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
		if(Queen.QueenPhase != EQueenPhaseEnum::Phase2)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (Queen.HasControl())
		{
			Queen.BehaviourComp.OnSwarmSpawned.AddUFunction(this, n"OnSwarmSpawned");
			Queen.BehaviourComp.OnSwarmDied.AddUFunction(this, n"OnSwarmDied");
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Queen.HasControl())
		{
			Queen.BehaviourComp.OnSwarmSpawned.Unbind(this, n"OnSwarmSpawned");
			Queen.BehaviourComp.OnSwarmDied.Unbind(this, n"OnSwarmDied");
		}
	}

	UFUNCTION()
	void OnSwarmSpawned(ASwarmActor Swarm)
	{
		HandleSwarmSpawned();
	}

	void HandleSwarmSpawned()
	{
		//reset
		bSwitchToHandsAndShieldDeferred = false;

		if(Queen.BehaviourComp.Swarms.Num() == 2)
		{
			if (bShouldRunHammer)
			{
				SetShieldAndSword();
			}
			else
			{
				SetShieldAndHand();
			}
			if (!bShouldRunPressureMode)
			{
				NetStopSpawning();
			}
		}
		else if (Queen.BehaviourComp.Swarms.Num() == 3)
		{
			// don't change shapes on swarms that are attacking. 
			// It doesn't look good due to spring stiffness differences on the animations
//			if(!IsSwarmSwordAttacking())
//			{
				SetTwoHandsAndshield();
//			}
//			else
//			{
//				// The change will be deferred to be handled 
//				// on tick instead when the attack is over.
//				bSwitchToHandsAndShieldDeferred = true;
//				PrintToScreenScaled("Deferred SpaWNING Activated", 5.f, FLinearColor::Red, 2.f);
//			}
			NetStopSpawning();
		}
		else if (Queen.BehaviourComp.Swarms.Num() == 1)
		{
			if (bShouldRunHammer)
			{
				// SetSingleHammer();
				SetSingleHand();
				bShouldRunHammer = false;
			}
			else
			{
				SetSingleHand();
				bShouldRunHammer = true;
			}
		}
	}

	UFUNCTION()
	void OnSwarmDied(ASwarmActor Swarm)
	{
		// USE this
		if (Swarm.BehaviourComp.CurrentBehaviourSettings == Queen.Phase2Settings.Abilities.Hammer.SwarmSettings)
		{
			bShouldRunHammer = false;
		}
		else if (Swarm.BehaviourComp.CurrentBehaviourSettings == Queen.Phase2Settings.Abilities.HandSmash_Right.SwarmSettings || Swarm.BehaviourComp.CurrentBehaviourSettings == Queen.Phase2Settings.Abilities.HandSmash_Left.SwarmSettings)
		{
			bShouldRunHammer = true;
		}

		if(Queen.BehaviourComp.Swarms.Num() == 1)
		{
			bRunStartSpawningTimer = true;
		}
		else if(Queen.BehaviourComp.Swarms.Num() == 0)
		{
			NetStartSpawning();
		}
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		// defer sword to hand shape changes during the sword attack 
		// due to extreme spring stiffness differences between the animations
//		if(bSwitchToHandsAndShieldDeferred && !IsSwarmSwordAttacking())
//		{
//			HandleSwarmSpawned();
//			PrintToScreenScaled("Deferred SpaWNING Deactivated", 5.f, FLinearColor::Green, 2.f);
//		}

		// We'll switch to shield if players aren't attackable.
		// (which happens when they are grinding, jumping off the platform or dead)
		if(!IsAtleastOnePlayerAttackable())
		{
			if(!IsActioning(n"SpecialAttack") && AreBothPlayersAlive() && Time::GetGameTimeSince(TimeStampSwitchToShields) > 0.5f)
			{
				HaveAllSwarmsSwitchToShield();
			}
		}
		else
		{
			SwitchBackToPreviousShape();

			// Switch player victim when the player isn't targetable (but the other one is)
			// (for the swarms which we've override the player victim for)
			// yes, this is usually handled by the swarm but we do it here because 
			// we have specific conditions during the QueenBoss which makes it easier 
			// to implement here. And it makes it more explicit for everyone involved 
			// on what is going on.
			UpdatePlayerTargeting();
		}

		if (!bRunStartSpawningTimer)
			return;

		StartSpawningTimer += DeltaSeconds;

		if (StartSpawningTimer > TurnShieldToSwordTimer)
		{
			if (Queen.BehaviourComp.Swarms.Num() == 1)
			{
				if(IsShield(Queen.BehaviourComp.Swarms[0]))
				{
					NetSwitchToSword(Queen.BehaviourComp.Swarms[0]);
				}
			}
		}

		if (StartSpawningTimer > SpawningTimerLength)
		{
			NetStartSpawning();
		}

		if (Queen.ArmorComponentHandler.HealthyArmorComponents.Num() < 3 && bShouldRunPressureMode == false)
		{
			bShouldRunPressureMode = true;
		}

	}

	bool IsSwarmSwordAttacking() const
	{
		for(ASwarmActor IterSwarm : Queen.BehaviourComp.Swarms)
		{
			if(!IsSwordSlash(IterSwarm))
				continue;

			if(IterSwarm.BehaviourComp.StatePriorityRequested == ESwarmBehaviourState::Attack)
				continue;

			return true;
		}
		return false;
	}

	// We don't want to switch shapes while an attack is ongoing
	bool bSwitchToHandsAndShieldDeferred = false;

	UFUNCTION(NetFunction)
	void NetStartSpawning()
	{
		Queen.SwitchSettings(Queen.Phase2Settings);
		bRunStartSpawningTimer = false;
		StartSpawningTimer = 0;
	}

	UFUNCTION(NetFunction)
	void NetStopSpawning()
	{
		Queen.SwitchSettings(Queen.SpawnNoWaspsSettings);
	}

	void SetSingleHand()
	{
		ASwarmActor SwarmHand = Queen.BehaviourComp.Swarms[0];
		NetSwitchToHandSmash(SwarmHand, ShouldUseRightHand(SwarmHand.VictimComp.CurrentVictim));
	}

	void SetShieldAndSword()
	{
		ASwarmActor SwarmHammer = Queen.BehaviourComp.Swarms[0];
		ASwarmActor SwarmShield = Queen.BehaviourComp.Swarms[1];

		NetSwitchToShield(SwarmShield);
		SwarmShield.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);

		NetSwitchToSword(SwarmHammer);
	}

	void SetSingleHammer()
	{
		ASwarmActor SwarmHammer = Queen.BehaviourComp.Swarms[0];
		NetSwitchToHammer(SwarmHammer);
	}

	void SetShieldAndHand()
	{
		ASwarmActor SwarmHand = Queen.BehaviourComp.Swarms[0];
		ASwarmActor SwarmShield = Queen.BehaviourComp.Swarms[1];

		NetSwitchToShield(SwarmShield);
		SwarmShield.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);
		NetSwitchToHandSmash(SwarmHand, ShouldUseRightHand(SwarmHand.VictimComp.CurrentVictim));
	}

	void SetTwoHandsAndshield()
	{
		ASwarmActor SwarmHand = Queen.BehaviourComp.Swarms[0];
		ASwarmActor SwarmHand2 = Queen.BehaviourComp.Swarms[2];
		ASwarmActor SwarmShield = Queen.BehaviourComp.Swarms[1];

		NetSwitchToShield(SwarmShield);
		SwarmShield.VictimComp.OverrideClosestPlayer(Game::GetCody(), this);

		NetSwitchToHandSmash(SwarmHand, ShouldUseRightHand(SwarmHand.VictimComp.CurrentVictim));
		NetSwitchToHandSmash(SwarmHand2, ShouldUseRightHand(SwarmHand2.VictimComp.CurrentVictim));
	}

	void UpdatePlayerTargeting()
	{
		for(ASwarmActor IterSwarm : Queen.BehaviourComp.Swarms)
		{
			if(!IterSwarm.VictimComp.IsOverrideClosestPlayerActive(this))
				continue;

			if(IsPlayerAttackable(IterSwarm.VictimComp.CurrentVictim))
				continue;

			// we generally always want shields to target cody
			if(IsShield(IterSwarm))
				continue;

			IterSwarm.VictimComp.OverrideClosestPlayer(IterSwarm.VictimComp.GetOtherVictim(), this);
		}
	}

	bool bSwapedBackToPreviousShape = false;

	void SwitchBackToPreviousShape()
	{
		if(bSwapedBackToPreviousShape)
			return;

		// Switch back to previous shape
		for(ASwarmActor IterSwarm : Queen.BehaviourComp.Swarms)
		{
			if(WasHandSmash(IterSwarm) && !IsHandSmash(IterSwarm))
			{
				NetSwitchToHandSmash(IterSwarm, ShouldUseRightHand(IterSwarm.VictimComp.CurrentVictim));
			}
			else if(WasSwordSlash(IterSwarm) && !IsSwordSlash(IterSwarm))
			{
				NetSwitchToSword(IterSwarm);
			}
		}

		bSwapedBackToPreviousShape = true;
	}

	void HaveAllSwarmsSwitchToShield()
	{
		// if(!bSwapedBackToPreviousShape)
		// 	return;

		// have all active swarms go into shield mode while the players aren't targetable
		for(ASwarmActor IterSwarm : Queen.BehaviourComp.Swarms)
		{
			if(IsShield(IterSwarm))
				continue;

			// don't change while it is attacking. The spring stiffness differences are to great
			// the swarm will appear to explode briefly if we do the switch mid-attack
			if(IterSwarm.BehaviourComp.StatePriorityRequested == ESwarmBehaviourState::Attack)
				continue;

			NetSwitchToShield(IterSwarm);
		}

		bSwapedBackToPreviousShape = false;
		TimeStampSwitchToShields = Time::GetGameTimeSeconds();
	}

	float TimeStampSwitchToShields = -0.5f;

}