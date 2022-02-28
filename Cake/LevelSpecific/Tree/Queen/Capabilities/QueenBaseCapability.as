
import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(Abstract)
class UQueenBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SwarmQueen");

	AQueenActor Queen = nullptr;
	UQueenSettings Settings = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Queen = Cast<AQueenActor>(Owner);
		Settings = UQueenSettings::GetSettings(Queen);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool IsHandSmash(const ASwarmActor InSwarm) const
	{
		return InSwarm.IsShape(ESwarmShape::RightHand);
	}

	bool WasHandSmash(const ASwarmActor InSwarm) const
	{
		return InSwarm.BehaviourComp.PreviousShape == ESwarmShape::RightHand;
	}

	bool WasSwordSlash(const ASwarmActor InSwarm) const
	{
		return InSwarm.BehaviourComp.PreviousShape == ESwarmShape::Sword;
	}

	bool IsSwordSlash(const ASwarmActor InSwarm) const
	{
		return InSwarm.IsShape(ESwarmShape::Sword);
	}

	bool IsRailSword(const ASwarmActor InSwarm) const
	{
		return InSwarm.IsShape(ESwarmShape::RailSword);
	}

	bool IsShield(const ASwarmActor InSwarm) const
	{
		return InSwarm.IsShape(ESwarmShape::Shield);
	}

	bool AreBothPlayersAlive() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(!IsPlayerAlive(PlayerIter))
			{
				return false;
			}
		}
		return true;
	}

	bool AreBothPlayersDead() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(IsPlayerAlive(PlayerIter))
			{
				return false;
			}
		}
		return true;
	}

	bool AreBothPlayersGrinding() const
	{
		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if(!Queen.GrabSplinePosComp.IsPlayerGrinding(Player))
			{
				return false;
			}
		}
		return true;
	}

	bool IsAtleastOnePlayerAttackable() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(IsPlayerAttackable(PlayerIter))
			{
				return true;
			}
		}

		return false;
	}

	bool IsPlayerAttackable(AHazePlayerCharacter InPlayer) const
	{
		if(IsPlayerAliveAndGrounded(InPlayer))
		{
			// We placed it here so that we can debug it more easily. 
			// Don't merge it with the if statement above!
			if(!IsPlayerGrinding(InPlayer))
			{
				return true;
			}
		}
		return false;
	}

	bool AreBothPlayersAttackable() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(!IsPlayerAttackable(PlayerIter))
			{
				return false;
			}
		}

		return true;
	}

	bool AreBothPlayersGrounded() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(!IsPlayerGrounded(PlayerIter))
			{
				return false;
			}
		}

		return true;
	}

	bool IsPlayerAlive(AHazePlayerCharacter InPlayer) const
	{
		auto HealthComp = UPlayerHealthComponent::Get(InPlayer); 
		return !HealthComp.bIsDead;
	}

	bool IsPlayerGrounded(AHazePlayerCharacter InPlayer) const
	{
		return Queen.VictimComp.IsPlayerGrounded(InPlayer, 1000.f);
	}

	bool IsPlayerAliveAndGrounded(AHazePlayerCharacter InPlayer) const
	{
		return Queen.VictimComp.IsPlayerAliveAndGrounded(InPlayer);
	}

	bool IsPlayerGrinding(AHazePlayerCharacter InPlayer) const
	{
		return Queen.GrabSplinePosComp.IsPlayerGrinding(InPlayer);
	}

	bool ShouldUseRightHand(AHazePlayerCharacter InPlayer = nullptr) const
	{
		if (InPlayer == nullptr)
		{
        	UHazeAITeam SwarmTeam = HazeAIBlueprintHelper::GetTeam(n"SwarmTeam");

			if (SwarmTeam != nullptr)
			{
				for (AHazeActor TeamMember : SwarmTeam.GetMembers())
				{
					if (TeamMember == nullptr)
						continue;

					ASwarmActor OtherSwarm = Cast<ASwarmActor>(TeamMember);

					if (OtherSwarm == nullptr)
						continue;

					if (OtherSwarm.IsAboutToDie())
						continue;

					if (OtherSwarm.IsShape(ESwarmShape::RightHand))
						return false;
				}
			}

			// No hands in arena -> use right hand
			return true;
		}

		// based on which side of the 'arena' that the player is standing on
		const FVector PlayerToQueen = Queen.GetActorLocation() - InPlayer.GetActorLocation();
		return PlayerToQueen.DotProduct(FVector::RightVector) < 0.f;
	}

	UFUNCTION(NetFunction)
	void NetSwitchToHandSmash(ASwarmActor Swarm, bool bUseRightHand = true)
	{
		if (bUseRightHand)
		{
			Swarm.SwitchTo(Settings.Abilities.HandSmash_Right.SwarmSheet, Settings.Abilities.HandSmash_Right.SwarmSettings);
//			Print("Switching To hand - RIGHT");
//			System::DrawDebugBox(
//				Swarm.GetActorLocation(),
//				Swarm.SkelMeshComp.GetWorldBoundExtent(),
//				FLinearColor::Red,
//				Duration = 5.f
//			);
		}
		else
		{
			Swarm.SwitchTo(Settings.Abilities.HandSmash_Left.SwarmSheet, Settings.Abilities.HandSmash_Left.SwarmSettings);
//			Print("Switching To hand - LEFT");
//			System::DrawDebugBox(
//				Swarm.GetActorLocation(),
//				Swarm.SkelMeshComp.GetWorldBoundExtent(),
//				FLinearColor::Yellow,
//				Duration = 5.f
//			);
		}

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightSecondPhaseNewHandWaspQueen", Queen);
	}

	UFUNCTION(NetFunction)
	void NetSwitchToTornado(ASwarmActor Swarm)
	{
  		Swarm.SwitchTo(
			Settings.Abilities.Tornado.SwarmSheet,
			Settings.Abilities.Tornado.SwarmSettings
		);  
	}

	UFUNCTION(NetFunction)
	void NetSwitchToHammer(ASwarmActor Swarm)
	{
  		Swarm.SwitchTo(
			Settings.Abilities.Hammer.SwarmSheet,
			Settings.Abilities.Hammer.SwarmSettings
		);

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightFirstPhaseHammerWaspQueen", Queen);
	}

	UFUNCTION(NetFunction)
	void NetSwitchToSword(ASwarmActor Swarm)
	{
  		Swarm.SwitchTo(
			Settings.Abilities.Sword.SwarmSheet,
			Settings.Abilities.Sword.SwarmSettings
		);  

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightSecondPhaseSwordWaspQueen", Queen);
	}

	UFUNCTION(NetFunction)
	void NetSwitchToRailSword(ASwarmActor Swarm)
	{
		SwitchToRailSword(Swarm);
	}

	UFUNCTION(NetFunction)
	void NetSwitchToShield(ASwarmActor Swarm)
	{
		SwitchToShield(Swarm);
	}

	// DON'T PUT NETFUNCTION ON THESE! Look above.
	void SwitchToRailSword(ASwarmActor Swarm)
	{
  		Swarm.SwitchTo(
			Settings.Abilities.RailSword.SwarmSheet,
			Settings.Abilities.RailSword.SwarmSettings
		);  
		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightThirdPhaseSwordWaspQueen", Queen);
	}

	// DON'T PUT NETFUNCTION ON THESE! Look above.
	void SwitchToShield(ASwarmActor Swarm)
	{
  		Swarm.SwitchTo(
			Settings.Abilities.Shield.SwarmSheet,
			Settings.Abilities.Shield.SwarmSettings
		);

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightSecondPhaseInitialWaspQueen", Queen);
	}

}