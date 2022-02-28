import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class UQueenRailHandCheckerCapability : UQueenBaseCapability 
{
	ASwarmActor GrabbingSwarm;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		const AHazePlayerCharacter PlayerThatIsGrinding = Queen.GrabSplinePosComp.GetPlayerGrinding(); 
		if(PlayerThatIsGrinding == nullptr)
			return EHazeNetworkActivation::DontActivate;

		const bool bAnySwarmIsGrabbingRail = Queen.GrabSplinePosComp.IsAnySwarmGrabbing(); 
		if(bAnySwarmIsGrabbingRail)
			return EHazeNetworkActivation::DontActivate;

		const ASwarmActor SwarmCandidate = FindRailHandSwarmCandidate(PlayerThatIsGrinding); 
		if(SwarmCandidate == nullptr)
			return EHazeNetworkActivation::DontActivate;

		const bool bSwarmCanGrabSplinePos = Queen.GrabSplinePosComp.CanGrabSplinePos(SwarmCandidate);
		if(!bSwarmCanGrabSplinePos)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		AHazePlayerCharacter VictimPlayer = GetGrindingPlayer();
		ASwarmActor SwarmThatCanGrab = FindRailHandSwarmCandidate(VictimPlayer);

		// We verified that we had a guy in ShouldActivate! Why is it failing!?
		ensure(SwarmThatCanGrab != nullptr);

		// or did the player die perhaps?
		ensure(VictimPlayer != nullptr);

		const int32 AssignedIndex = Queen.GrabSplinePosComp.FindBestVacantPositionIndex(SwarmThatCanGrab, VictimPlayer);

		OutParams.AddObject(n"PlayerVictim", VictimPlayer);
		OutParams.AddObject(n"SwarmThatCanGrab", SwarmThatCanGrab);
		OutParams.AddNumber(n"AssignedIndex", AssignedIndex);
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(const FCapabilityActivationParams& ActivationParams)
 	{
		AHazePlayerCharacter VictimPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"PlayerVictim"));
		GrabbingSwarm = Cast<ASwarmActor>(ActivationParams.GetObject(n"SwarmThatCanGrab"));

		ensure(GrabbingSwarm != nullptr);
		ensure(VictimPlayer != nullptr);

		int32 AssignedIndex = ActivationParams.GetNumber(n"AssignedIndex");

		Queen.GrabSplinePosComp.GrabSplinePos(
			AssignedIndex,
			GrabbingSwarm,
			VictimPlayer,
			Settings.Abilities.GrabSpline.SwarmSheet,
			Settings.Abilities.GrabSpline.SwarmSettings
		);

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		const AHazePlayerCharacter PlayerThatIsGrinding = Queen.GrabSplinePosComp.GetPlayerGrinding(); 
		if(PlayerThatIsGrinding == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		const bool BeingSpecial = IsActioning(n"SpecialAttack"); 
		if(BeingSpecial)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Queen.GrabSplinePosComp.ReleaseSplinePos(GrabbingSwarm);
		GrabbingSwarm = nullptr;
	}

	AHazePlayerCharacter GetGrindingPlayer() const
	{
		for (auto player : Game::GetPlayers())
		{
			if (Queen.GrabSplinePosComp.IsPlayerGrinding(player))
			{
				return player;
			}
		}

		return nullptr;
	}

	ASwarmActor FindRailHandSwarmCandidate(const AHazePlayerCharacter Player) const
	{
		if(Player == nullptr)
			return nullptr;

		// Priority order:
		// 1. Shields Targeting player
		// 2. Swarms Targeting Player
		// 3. null

		TArray<ASwarmActor> Shields;
		for (ASwarmActor Swarm : Queen.BehaviourComp.Swarms)
		{
			if(IsShield(Swarm)) 
			{
				Shields.Add(Swarm);
			}
		}

		if(Shields.Num() > 0)
		{
			TArray<ASwarmActor> ShieldsTargetingPlayer;
			for (int i = 0; i < Shields.Num(); i++)
			{
				if (Player == Shields[i].VictimComp.PlayerVictim)
				{
					ShieldsTargetingPlayer.Add(Shields[i]);
				}
			}

			if(ShieldsTargetingPlayer.Num() > 0)
			{
				ASwarmActor ClosestShieldTargetingPlayer = nullptr;
				float ClosestDistanceSQ = BIG_NUMBER;
				const FVector PlayerPos = Player.GetActorLocation();
				for (int i = 0; i < ShieldsTargetingPlayer.Num(); i++)
				{
					const FVector SwarmPos = ShieldsTargetingPlayer[i].GetActorLocation();
					const float DistSQ = PlayerPos.DistSquared(SwarmPos);
					if(DistSQ < ClosestDistanceSQ)
					{
						ClosestDistanceSQ = DistSQ;
						ClosestShieldTargetingPlayer = ShieldsTargetingPlayer[i];
					}
				}

				return ClosestShieldTargetingPlayer;
			}

			return Shields.Last();
		}

		for (ASwarmActor Swarm : Queen.BehaviourComp.Swarms)
		{
			if (Player == Swarm.VictimComp.PlayerVictim)
			{
				return Swarm;
			}
		}

//		return Queen.BehaviourComp.Swarms.Last();
		return nullptr;
	}
}