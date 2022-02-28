import Vino.MinigameScore.MinigameCharacter;
import Vino.MinigameScore.MinigameCharacterComponent;
import Vino.MinigameScore.MinigameComp;

class UMinigameCharacterPlayerReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MinigameCharacterPlayerReactionCapability");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	TPerPlayer<AHazePlayerCharacter> Players;

	AMinigameCharacter MinigameCharacter;
	
	UMinigameCharacterComponent MinigameCharacterComp;

	UMinigameComp MinigameComp;

	TPerPlayer<float> Distances;

	bool bHasReactedToPlayer;

	float TimerAnnouncement = 1.7f;

	bool bTambHasAnnounced;

	bool bTambDisappearOnGameStart;

	bool bHasMadeFinalExit;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MinigameCharacter = Cast<AMinigameCharacter>(Owner);
		MinigameCharacterComp = UMinigameCharacterComponent::Get(MinigameCharacter);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Players[0] = Game::May;
		Players[1] = Game::Cody;
		MinigameComp = Cast<UMinigameComp>(MinigameCharacter.MinigameCompRef);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Distances[0] = (Players[0].ActorLocation - Owner.ActorLocation).Size();
		Distances[1] = (Players[1].ActorLocation - Owner.ActorLocation).Size();

		auto ClosestDistance = (Distances[0] < Distances[1]) ? Distances[0] : Distances[1];
		AHazePlayerCharacter DiscoveryPlayer = (Distances[0] < Distances[1]) ? Players[0] : Players[1];

		if (MinigameCharacter.bLoopingReaction)
		{
			MinigameCharacter.TambourineState = EMinigameCharacterState::LoopingHitReaction;
			return;
		}

		if (!MinigameCharacterComp.bHaveDiscoveredGame)
		{
			if (MinigameCharacter.bTambDisappear)
			{
				if (!bHasMadeFinalExit)
				{
					bHasMadeFinalExit = true;
					MinigameCharacter.TambourineState = EMinigameCharacterState::Exiting;
				}
			}
			else if (ClosestDistance > MinigameCharacter.MinDiscoveryDistance)
			{
				MinigameCharacter.TambourineState = EMinigameCharacterState::Waiting;
			}
			else 
			{
				if (MinigameComp.MayInRange == 0 &&	MinigameComp.CodyInRange == 0)
					return;
				
				if (!bHasReactedToPlayer)
					NetBroadcastVO(DiscoveryPlayer);
				
				if (bHasReactedToPlayer && !bTambHasAnnounced)
				{
					if (TimerAnnouncement > 0.f)
					{
						TimerAnnouncement -= DeltaTime;
						MinigameCharacter.TambourineState = EMinigameCharacterState::AnnouncesPlayerArrival;
					}
					else
					{
						bTambHasAnnounced = true;
						MinigameCharacter.OnAnnouncementCompletedEvent.Broadcast();
						MinigameCharacter.TambourineState = EMinigameCharacterState::Idle;
					}
				}
			}
		}
		else
		{
			if (MinigameCharacter.bTambDisappear)
			{
				if (!bHasMadeFinalExit)
				{
					bHasMadeFinalExit = true;
					MinigameCharacter.TambourineState = EMinigameCharacterState::Exiting;
				}
			}
			else
			{
				MinigameCharacter.TambourineState = EMinigameCharacterState::Idle;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetBroadcastVO(AHazePlayerCharacter DiscoveryPlayer)
	{
		if (bHasReactedToPlayer)
			return;
		
		bHasReactedToPlayer = true;
		MinigameCharacter.OnAnnouncementStarted.Broadcast(DiscoveryPlayer);
	}
}