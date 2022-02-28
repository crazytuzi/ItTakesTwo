import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;

class UGardenSwingAnnounceWinCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AGardenSwingsActor Swings;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;

	UGardenSingleSwingComponent MaySwing;
	UGardenSingleSwingComponent CodySwing;

	bool bMaySwingStill = false;
	bool bCodySwingStill = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swings = Cast<AGardenSwingsActor>(Owner);
		MaySwing = Swings.MaySwing;
		CodySwing = Swings.CodySwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Swings.bMayScoreSet)
			return EHazeNetworkActivation::DontActivate;

		if(!Swings.bCodyScoreSet)
			return EHazeNetworkActivation::DontActivate;
		
		if(!HasPlayerFinishedAnims(Game::May))
			return EHazeNetworkActivation::DontActivate;

		if(!HasPlayerFinishedAnims(Game::Cody))
			return EHazeNetworkActivation::DontActivate;

		if(!Swings.bCompletedJump[0])
			return EHazeNetworkActivation::DontActivate;

		if(!Swings.bCompletedJump[1])
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Swings.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(Swings.bAwaitingScoreScreenSized)
		{
			Game::GetCody().ClearViewSizeOverride(Swings);
			Game::GetMay().ClearViewSizeOverride(Swings);
		}
		
		AnnounceWinner();

		ResetPlayerBool(Game::May);
		ResetPlayerBool(Game::Cody);
	}

	bool HasPlayerFinishedAnims(AHazePlayerCharacter Player) const
	{
		UGardenSwingPlayerComponent PlayerComp = UGardenSwingPlayerComponent::Get(Player);

		if (PlayerComp != nullptr)
			return PlayerComp.bPlayerFinishedAnimations;
		else
			return false;
	}

	void ResetPlayerBool(AHazePlayerCharacter Player)
	{
		UGardenSwingPlayerComponent PlayerComp = UGardenSwingPlayerComponent::Get(Player);

		if (PlayerComp != nullptr)
			PlayerComp.bPlayerFinishedAnimations = false;
	}

	UFUNCTION()
	void AnnounceWinner()
	{
		Swings.bShowScore = true;

		Swings.OnBeforeAnnouncingSwingWinner.Broadcast();

		Swings.MinigameComp.AnnounceWinner();

		if (Game::May.HasControl())
			NetMayWinReaction();

		if (Game::Cody.HasControl())
			NetCodyWinReaction();

		if(Swings.MinigameComp.GetCurrentlyWinningPlayer() != nullptr)
		{
			Swings.Winner = Swings.MinigameComp.GetCurrentlyWinningPlayer();

			Swings.WinnerCameraRoot.SetWorldLocation(Swings.Winner.ActorLocation);
			Swings.Winner.ActivateCamera(Swings.WinnerCamera, CameraBlend::Normal(), this, EHazeCameraPriority::High);
		}
	}

	UFUNCTION(NetFunction)
	void NetMayWinReaction()
	{
		Swings.MinigameComp.ActivateReactionAnimations(Game::GetMay());
	}
	
	UFUNCTION(NetFunction)
	void NetCodyWinReaction()
	{
		Swings.MinigameComp.ActivateReactionAnimations(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

}