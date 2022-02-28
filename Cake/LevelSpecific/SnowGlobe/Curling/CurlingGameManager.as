import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingTargetPoint;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingTargetSpawn;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingCameraManager;
import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingEndSessionManager;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingResetVolume;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingInteractStart;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingTube;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStartingLine;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerOutOfBounds;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingObstacleManager;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingScoreLine;
import Vino.MinigameScore.MinigameStatics;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;
import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.SnowGlobe.MinigameReactionSnowFolk.ReactionSnowFolkManager;

enum EPlayerGameState
{
	Default,
	InPlay 
};

ACurlingGameManager GetCurlingGameManager()
{
	TArray<ACurlingGameManager> GameManagers;
	GetAllActorsOfClass(GameManagers);

	return GameManagers[0];
}

class ACurlingGameManager : ADoubleInteractionActor
{
	default bUsePredictiveAnimation = false;
	default LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
	default RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
	default bPreventInteractionFromCompleting = true;
	default bPlayExitAnimationOnCompleted = true;
	default bTurnOffTickWhenNotWaiting = false;

	ECurlingGameState CurlingGameState;
	TPerPlayer<EPlayerGameState> PlayerGameState;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::ShuffleBoard;
	
	UPROPERTY(Category = "Curling Setup")
	TPerPlayer<ACurlingTargetSpawn> CurlingStartingPoint;

	UPROPERTY(Category = "Curling Setup")
	TArray<ACurlingStone> CurlingStoneArrayMay;

	UPROPERTY(Category = "Curling Setup")
	TArray<ACurlingStone> CurlingStoneArrayCody;

	UPROPERTY(Category = "Curling Setup")
	TArray<ACurlingStone> ActiveStonesArrayMay;

	UPROPERTY(Category = "Curling Setup")
	TArray<ACurlingStone> ActiveStonesArrayCody;

	UPROPERTY(Category = "Curling Setup")
	TPerPlayer<ACurlingCameraManager> CurlingCameraManager;

	UPROPERTY(Category = "Curling Setup")
	ACurlingEndSessionManager CurlingEndSessionManager; 

	UPROPERTY(Category = "Curling Setup")
	ACurlingResetVolume CurlingResetVolume;

	UPROPERTY(Category = "Curling Setup")
	TPerPlayer<ACurlingDoor> CurlingDoors;

	UPROPERTY(Category = "Curling Setup")
	ACurlingInteractStart InteractStart1;

	UPROPERTY(Category = "Curling Setup")
	ACurlingInteractStart InteractStart2;

	UPROPERTY(Category = "Curling Setup")
	AReactionSnowFolkManager ReactionMaySide;
	
	UPROPERTY(Category = "Curling Setup")
	AReactionSnowFolkManager ReactionCodySide;

	UPROPERTY(Category = "Game Boundaries")
	ACurlingStartingLine CurlingStartingLine1;

	UPROPERTY(Category = "Game Boundaries")
	ACurlingPlayerOutOfBounds CurlingPlayerOutOfBounds;

	UPROPERTY(Category = "Game Boundaries")
	ACurlingObstacleManager ObstacleManager; 

	UPROPERTY(Category = "Game Boundaries")
	AActor EdgeTransform;

	TPerPlayer<ACurlingStone> InPlayCurlingStone;

	TPerPlayer<UCurlingPlayerComp> PlayerComps;

	UPROPERTY(Category = "Widget Setup")
	FScoreHudData CurlingHudData;
	default CurlingHudData.ShowHighScore = false;
	default CurlingHudData.HighScoreType = EHighScoreType::HighestScore;

	//*** GENERAL GAME INFO ***//
	int MaxPoints = 6.f;

	int BluePointBonus = 1;
	int RedPointBonus = 2;

	// int PlayersActive;
	bool bMayReady;
	bool bCodyReady;
	int DoorsOpen;
	int PlaysMade;

	//should be 6
	int MaxPlaysMade = 6;

	float ScoreCheckMay;
	float ScoreCheckCody;

	TPerPlayer<bool> bFinalCamActive;
	bool bCanCalculateTurnCheck;
	bool bPlayerExitedGame;

	float SpeedPercentage;
	float VelocitySpeed;

	UPROPERTY(Category = "Point Score")
	float TargetBlueRadius = 1552.5f;
	
	UPROPERTY(Category = "Point Score")
	float TargetRedRadius = 610.5f;

	//*** GENERAL GAME INFO ***//
	UPROPERTY(Category = "Point Score")
	ACurlingScoreLine ScoreLine1;

	UPROPERTY(Category = "Point Score")
	ACurlingScoreLine ScoreLine2;

	UPROPERTY(Category = "Point Score")
	ACurlingScoreLine ScoreLine3;

	UPROPERTY(Category = "Point Score")
	ACurlingScoreLine EndLine;

	TPerPlayer<bool> bCanSetPlayerScore;

	float NetScoreTime;
	float NetScoreRate = 0.3f;

	int RoundCounter;
	int MaxRounds = 3;

	float NetTime;
	
	int SessionPlayCounter;

	bool bBlockedMayCancel;
	bool bBlockedCodyCancel;

	bool bPendingWin;

	//*** REACTIONS ***//

	TPerPlayer<float> ReactionTimer;
	TPerPlayer<bool> bCanReactionTimer;
	TPerPlayer<bool> bHaveReacted;
	float MaxReactionTimer = 1.2f;
	
	TPerPlayer<bool> bPlayedTaunt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetActorTickEnabled(true);

		RoundCounter = 1;
		
		for (ACurlingStone Stone : CurlingStoneArrayMay)
		{
			Stone.EventActivateStone.AddUFunction(this, n"AddToActiveStoneInPlay");
			Stone.EventStoneHasFallen.AddUFunction(this, n"StoneOutOfBounds");

			CurlingEndSessionManager.EndSessionStoneArray.Add(Stone);

			Stone.SetInitializedPosition();
			Stone.DisableActor(this);
		}

		for (ACurlingStone Stone : CurlingStoneArrayCody)
		{
			Stone.EventActivateStone.AddUFunction(this, n"AddToActiveStoneInPlay");
			Stone.EventStoneHasFallen.AddUFunction(this, n"StoneOutOfBounds");

			CurlingEndSessionManager.EndSessionStoneArray.Add(Stone);

			Stone.SetInitializedPosition();
			Stone.DisableActor(this);
		}
		
		CurlingCameraManager[0].ArenaForwardDirection = (CurlingDoors[0].ActorLocation - ActorLocation).GetSafeNormal();
		CurlingCameraManager[1].ArenaForwardDirection = (CurlingDoors[1].ActorLocation - ActorLocation).GetSafeNormal();

		CurlingResetVolume.EventNotifyDisableStone.AddUFunction(this, n"DisableStone");

		if (HasControl())
		{	
			CurlingResetVolume.EventNotifyEndSessionComplete.AddUFunction(this, n"EndGame");
			MinigameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"PlayerExitsGame");
			MinigameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"PlayerLeft");
			MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"NetAnnounceWinnerComplete");
		}

		OnDoubleInteractionCompleted.AddUFunction(this, n"InteractionCompleted");

		LeftInteraction.OnActivated.AddUFunction(this, n"LeftInteracted");
		RightInteraction.OnActivated.AddUFunction(this, n"RightInteracted");
		OnBothPlayersLockedIntoInteraction.AddUFunction(this, n"PlayersLockedIn");
		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnPlayerCancelledInteraction");

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartGame");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"GameCancelled");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (CurlingGameState != ECurlingGameState::Inactive)
		{
			if (HasControl())
			{
				CheckReactionPlay(0, DeltaTime);
				CheckReactionPlay(1, DeltaTime);

				if (CurlingGameState != ECurlingGameState::Complete)
					SetGameScore();
			}
		}	

		if (HasControl())
		{
			if (bPendingWin)
			{
				bPendingWin = false;
				// System::SetTimer()
				NetAnnounceWinner();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetValidateClient()
	{

	}

	UFUNCTION()
	void ApplyPOIToDoor(AHazePlayerCharacter Player)
	{
		FHazePointOfInterest POISettings;
		POISettings.Blend = 1.4f;

		if (Player.IsMay())
			POISettings.FocusTarget.Actor = CurlingDoors[0];
		else
			POISettings.FocusTarget.Actor = CurlingDoors[1];

		Player.ApplyPointOfInterest(POISettings, this);
	}

	void ApplyPOIToStonePuckFall(AHazePlayerCharacter Player)
	{
		FHazePointOfInterest POISettings;
		POISettings.Blend = 2.8f;

		if (Player.IsMay())
			POISettings.FocusTarget.Actor = CurlingStoneArrayMay[0];
		else
			POISettings.FocusTarget.Actor = CurlingStoneArrayCody[0];

		POISettings.FocusTarget.ViewOffset = FVector(0.f, 0.f, -800.f);

		Player.ApplyPointOfInterest(POISettings, this);
	}

	UFUNCTION()
	void InteractionCompleted()
	{
		bPreventInteractionFromCompleting = true;

		if (CurlingGameState == ECurlingGameState::Active)
		{
			LeftInteraction.Disable(n"GameInSession");
			RightInteraction.Disable(n"GameInSession");
		}
	}

	UFUNCTION()
	void PlayersLockedIn()
	{
		MinigameComp.ActivateTutorial();
		
		Game::May.ClearPointOfInterestByInstigator(this);
		Game::Cody.ClearPointOfInterestByInstigator(this);
	}

	void OnEnterAnimationStarted(AHazePlayerCharacter Player) override
	{
		if (Player.IsMay())
		{
			InteractStart1.PlayStartLeverAnim();
			InteractStart1.AudioLeverAction(Player);
		}
		else
		{
			InteractStart2.PlayStartLeverAnim();
			InteractStart2.AudioLeverAction(Player);
		}
	}

	void OnMHAnimationStarted(AHazePlayerCharacter Player) override
	{
		if (Player.IsMay())
			InteractStart1.PlayMHLeverAnim();
		else
			InteractStart2.PlayMHLeverAnim();
	}

	void OnExitAnimationStarted(AHazePlayerCharacter Player) override
	{
		if (Player.IsMay())
		{
			InteractStart1.PlayExitLeverAnim();
			InteractStart1.AudioLeverCancelAction(Player);
		}
		else
		{
			InteractStart2.PlayExitLeverAnim();
			InteractStart2.AudioLeverCancelAction(Player);
		}
	}

	UFUNCTION()
	void LeftInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		bMayReady = true;
		DoorActionMay();
		ApplyPOIToDoor(Game::May);
	}

	UFUNCTION()
	void RightInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		bCodyReady = true;
		DoorActionCody();
		ApplyPOIToDoor(Game::Cody);
	}

	UFUNCTION()
	void OnPlayerCancelledInteraction(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		if (Player == Game::GetMay())
		{
			bMayReady = false;
			Game::May.ClearPointOfInterestByInstigator(this);
			CurlingDoors[0].bCanActivateDoor = true;
			CurlingDoors[0].bIsOpening = false;
		}
		else
		{
			bCodyReady = false;
			Game::Cody.ClearPointOfInterestByInstigator(this);
			CurlingDoors[1].bCanActivateDoor = true;
			CurlingDoors[1].bIsOpening = false;
		}
	}

	UFUNCTION(NetFunction)
	void PlayerRemoved(AHazePlayerCharacter InPlayer)
	{
		if (InPlayer == Game::GetMay())
		{
			bMayReady = false;
			CurlingDoors[0].bCanActivateDoor = true;
			CurlingDoors[0].bIsOpening = false;
		}
		else
		{
			bCodyReady = false;
			CurlingDoors[1].bCanActivateDoor = true;
			CurlingDoors[1].bIsOpening = false;
		}
	}

	UFUNCTION()
	void DoorActionMay()
	{
		CurlingDoors[0].bCanActivateDoor = true;
		CurlingDoors[0].bIsOpening = true;
	}

	UFUNCTION()
	void DoorActionCody()
	{
		CurlingDoors[1].bCanActivateDoor = true;
		CurlingDoors[1].bIsOpening = true;
	}

	UFUNCTION()
	void StartGame()
	{
		MinigameComp.AddPlayerCapabilitySheets();
		MinigameComp.ResetScoreBoth();
		MinigameComp.ShowGameHud();

		bPreventInteractionFromCompleting = false;

		CurlingGameState = ECurlingGameState::Active;

		CurlingStartingLine1.SetPlayerCompReferences();

		PlayerComps[0] = UCurlingPlayerComp::Get(Game::May);
		PlayerComps[1] = UCurlingPlayerComp::Get(Game::Cody);

		bBlockedMayCancel = true;
		bBlockedCodyCancel = true;

		Game::May.ClearPointOfInterestByInstigator(this);
		Game::Cody.ClearPointOfInterestByInstigator(this);
		
		ApplyPOIToStonePuckFall(Game::May);
		ApplyPOIToStonePuckFall(Game::Cody);
		
		System::SetTimer(this, n"TimedDisableStoneFallPOI", 2.f, false);
		
		ActivatePlayerStone(Game::GetMay());
		ActivatePlayerStone(Game::GetCody());

		if (SessionPlayCounter >= 1)
			ObstacleManager.ActivateObstacles();

		SessionPlayCounter++;
	
		PlaysMade = 0;
		RoundCounter = 1;
	}

	UFUNCTION()
	void TimedDisableStoneFallPOI()
	{
		Game::May.ClearPointOfInterestByInstigator(this);
		Game::Cody.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(NetFunction)
	void NetAnnounceWinnerComplete()
	{
		MinigameComp.RemovePlayerCapabilitySheets();
	}

	UFUNCTION(NetFunction)
	void EndGame()
	{
		CurlingGameState = ECurlingGameState::Inactive;

		CurlingEndSessionManager.bActivateEndSession = false;

		ResetCurrentPlayerCompState();

		for (ACurlingStone Stone : CurlingStoneArrayMay)
			Stone.AllocatedPoints = 0;

		for (ACurlingStone Stone : CurlingStoneArrayCody)
			Stone.AllocatedPoints = 0;

		ActiveStonesArrayMay.Empty();
		ActiveStonesArrayCody.Empty();

		CurlingCameraManager[0].TargetStonesArray.Empty();
		CurlingCameraManager[1].TargetStonesArray.Empty();

		PlayerGameState[0] = EPlayerGameState::Default;
		PlayerGameState[1] = EPlayerGameState::Default;

		CurlingResetVolume.ResetStoneCount();

		CurlingDoors[0].bCanActivateDoor = true;
		CurlingDoors[0].bIsOpening = false;
		CurlingDoors[1].bCanActivateDoor = true;
		CurlingDoors[1].bIsOpening = false;

		WinnerAnnouncementComplete();

		bMayReady = false;
		bCodyReady = false;

		bPreventInteractionFromCompleting = true;
	}

	UFUNCTION()
	void WinnerAnnouncementComplete()
	{
		EnableAfterFullSyncPoint(n"GameInSession");
	}

	UFUNCTION(NetFunction)
	void PlayerExitsGame(AHazePlayerCharacter InputPlayer)
	{
		if (CurlingGameState == ECurlingGameState::Inactive)
			return;

		CurlingGameState = ECurlingGameState::Complete;	
		
		UCurlingPlayerComp PlayerComp1 = UCurlingPlayerComp::Get(Game::GetMay());
		UCurlingPlayerComp PlayerComp2 = UCurlingPlayerComp::Get(Game::GetCody());

		if (PlayerComp1 != nullptr)
			PlayerComp1.PlayerCurlState = EPlayerCurlState::Default;

		if (PlayerComp2 != nullptr)
			PlayerComp2.PlayerCurlState = EPlayerCurlState::Default;

		if (InputPlayer == Game::May)
		{
			MinigameComp.AnnounceWinner(Game::Cody);
			bHaveReacted[0] = true;
		}
		else if (InputPlayer == Game::Cody)
		{
			MinigameComp.AnnounceWinner(Game::May);
			bHaveReacted[1] = true;
		}

		TurnOffStoneRumble();

		bPreventInteractionFromCompleting = false;
		
		CurlingCameraManager[0].CamManagerState = ECurlingCamManagerState::Inactive;
		CurlingCameraManager[1].CamManagerState = ECurlingCamManagerState::Inactive;

		CurlingEndSessionManager.bActivateEndSession = true;
		CurlingEndSessionManager.bCanOpenDoor = true;

		ObstacleManager.DeactivateObstacles();

		bPlayerExitedGame = true;
	}

	UFUNCTION(NetFunction)
	void NetUpdatePlaysAndCheckGameState(AHazePlayerCharacter Player)
	{
		if (CurlingGameState != ECurlingGameState::Active)
			return;

		PlaysMade++;

		if (Player != nullptr)
		{
			if	(Player == Game::May)
				ReactionMaySide.ActivateReactions();
			else
				ReactionCodySide.ActivateReactions();
		}

		if (PlaysMade < MaxPlaysMade)
			return;

		bPendingWin = true;
	}  

	UFUNCTION(NetFunction)
	void NetAnnounceWinner()
	{		
		CurlingGameState = ECurlingGameState::Complete;

		CurlingEndSessionManager.bActivateEndSession = true;
		CurlingEndSessionManager.bCanOpenDoor = true;
		
		bPlayerExitedGame = false;
		MinigameComp.AnnounceWinner();
		
		ObstacleManager.DeactivateObstacles();

		TurnOffStoneRumble();
	}

	UFUNCTION()
	void GameCancelled()
	{
		bPreventInteractionFromCompleting = false;
		
		Game::May.ClearPointOfInterestByInstigator(this);
		Game::Cody.ClearPointOfInterestByInstigator(this);

		CurlingDoors[0].bCanActivateDoor = true;
		CurlingDoors[0].bIsOpening = false;
		CurlingDoors[1].bCanActivateDoor = true;
		CurlingDoors[1].bIsOpening = false;
	}

	UFUNCTION(NetFunction)
	void PlayerLeft(AHazePlayerCharacter InputPlayer)
	{
		if (CurlingGameState != ECurlingGameState::Inactive)
			return;

		if (InputPlayer == Game::GetMay())
		{
			CurlingDoors[0].bCanActivateDoor = true;
			CurlingDoors[0].bIsOpening = false;
		}
		else
		{
			CurlingDoors[1].bCanActivateDoor = true;
			CurlingDoors[1].bIsOpening = false;
		}
	}

	UFUNCTION()
	void AddToActiveStoneInPlay(ACurlingStone InputStone, AHazePlayerCharacter Player)
	{
		bPlayedTaunt[Player] = false;
		CurlingCameraManager[Player].ZValue = InputStone.ActorLocation.Z;
		CurlingCameraManager[Player].TargetStonesArray.Add(InputStone);
		PlayerGameState[Player] = EPlayerGameState::InPlay;
		InPlayCurlingStone[Player] = InputStone;
		ReactionTimer[Player] = MaxReactionTimer;
		bHaveReacted[Player] = false;

		if (Player == Game::GetMay())
			ActiveStonesArrayMay.Add(InputStone);
		else
			ActiveStonesArrayCody.Add(InputStone);
	}

	UFUNCTION()
	void CheckReactionPlay(int Index, float DeltaTime)
	{
		if (bHaveReacted[Index])
			return;

		if (InPlayCurlingStone[Index] == nullptr)
			return;

		FVector DeltaFromScoreLine1 = InPlayCurlingStone[Index].ActorLocation - ScoreLine1.ActorLocation;
		FVector DeltaFromScoreLine2 = InPlayCurlingStone[Index].ActorLocation - ScoreLine2.ActorLocation;
		FVector DeltaFromScoreLine3 = InPlayCurlingStone[Index].ActorLocation - ScoreLine3.ActorLocation;	

		float DistanceFromScoreLine1 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine1);
		float DistanceFromScoreLine2 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine2);
		float DistanceFromScoreLine3 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine3);	

		if (DistanceFromScoreLine3 > -162.f && !bCanReactionTimer[Index])
		{
			bCanReactionTimer[Index] = true;
			ReactionTimer[Index] = MaxReactionTimer;
		}
		else if (DistanceFromScoreLine3 < -162.f && bCanReactionTimer[Index])
			bCanReactionTimer[Index] = false;

		if (bCanReactionTimer[Index])
		{
			ReactionTimer[Index] -= DeltaTime;

			if (ReactionTimer[Index] <= 0.f)
			{
				if (!HasControl())
					return;
					
				if (Index == 0)
					ReactionMaySide.ActivateReactions();
				else
					ReactionCodySide.ActivateReactions();

				bHaveReacted[Index] = true;
			}
		}
	}

	UFUNCTION()
	void SetGameScore()
	{
		int MayScoreThisTick = 0.f;
		int MayInPlayTickThisScore = 0;

		for (ACurlingStone Stone : CurlingStoneArrayMay)
		{
			if (!ActiveStonesArrayMay.Contains(Stone))
				continue;

			FVector DeltaFromScoreLine1 = Stone.ActorLocation - ScoreLine1.ActorLocation;
			FVector DeltaFromScoreLine2 = Stone.ActorLocation - ScoreLine2.ActorLocation;
			FVector DeltaFromScoreLine3 = Stone.ActorLocation - ScoreLine3.ActorLocation;
			
			float DistanceFromScoreLine1 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine1);
			float DistanceFromScoreLine2 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine2);
			float DistanceFromScoreLine3 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine3);
			
			FVector DeltaFromEdgeLine = Stone.ActorLocation - EndLine.ActorLocation;
			float DistanceFromEdgeLine = EndLine.ForwardVector.DotProduct(DeltaFromEdgeLine);

			int AllocatedThisTick = 0;

			if (DistanceFromScoreLine1 > -162.f)	
			{
				MayScoreThisTick += 1;
				AllocatedThisTick += 1;
			}						
			
			if (DistanceFromScoreLine2 > -162.f)
			{
				MayScoreThisTick += 1;
				AllocatedThisTick += 1;
			}

			if (DistanceFromScoreLine3 > -162.f)
			{
				MayScoreThisTick += 2;
				AllocatedThisTick += 2;
			}

			if (DistanceFromEdgeLine > 80.f)
			{
				MayScoreThisTick -= 4;
				AllocatedThisTick = 0;
			}
					
			if (Stone == InPlayCurlingStone[0])
			{
				if (DistanceFromScoreLine1 > -162.f)							
					MayInPlayTickThisScore += 1;
				
				if (DistanceFromScoreLine2 > -162.f)
					MayInPlayTickThisScore += 1;

				if (DistanceFromScoreLine3 > -162.f)
					MayInPlayTickThisScore += 2;
			}

			// if (Stone.AllocatedPoints != AllocatedThisTick)
			// 	NetScoreWidgetFeedback(Game::May, AllocatedThisTick, Stone);
		}

		if (MayScoreThisTick != MinigameComp.GetMayScore())
		{
			MinigameComp.SetScore(Game::May, MayScoreThisTick); 
			NetScore(Game::May, MayScoreThisTick);
		}

		if (!bPlayedTaunt[0] && InPlayCurlingStone[0] != nullptr)
			if (MayInPlayTickThisScore >= 2 && InPlayCurlingStone[0].MoveComp.Velocity.Size() < 300.f)
			{
				MinigameComp.PlayTauntAllVOBark(Game::May);
				bPlayedTaunt[0] = true;
			}
		
		float CodyScoreThisTick = 0.f;
		int CodyInPlayTickThisScore = 0;

		for (ACurlingStone Stone : CurlingStoneArrayCody)
		{
			if (!ActiveStonesArrayCody.Contains(Stone))
				continue;

			FVector DeltaFromScoreLine1 = Stone.ActorLocation - ScoreLine1.ActorLocation;
			FVector DeltaFromScoreLine2 = Stone.ActorLocation - ScoreLine2.ActorLocation;
			FVector DeltaFromScoreLine3 = Stone.ActorLocation - ScoreLine3.ActorLocation;

			float DistanceFromScoreLine1 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine1);
			float DistanceFromScoreLine2 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine2);
			float DistanceFromScoreLine3 = ScoreLine1.ForwardVector.DotProduct(DeltaFromScoreLine3);

			FVector DeltaFromEdgeLine = Stone.ActorLocation - EndLine.ActorLocation;
			float DistanceFromEdgeLine = EndLine.ForwardVector.DotProduct(DeltaFromEdgeLine);

			int AllocatedThisTick = 0;

			if (DistanceFromScoreLine1 > -162.f)	
			{
				CodyScoreThisTick += 1;
				AllocatedThisTick += 1;
			}						
			
			if (DistanceFromScoreLine2 > -162.f)
			{
				CodyScoreThisTick += 1;
				AllocatedThisTick += 1;
			}

			if (DistanceFromScoreLine3 > -162.f)
			{
				CodyScoreThisTick += 2;
				AllocatedThisTick += 2;
			}

			if (DistanceFromEdgeLine > 80.f)
			{
				CodyScoreThisTick -= 4;
				AllocatedThisTick = 0;
			}

			if (Stone == InPlayCurlingStone[1])
			{
				if (DistanceFromScoreLine1 > -162.f)							
					CodyInPlayTickThisScore += 1;
				
				if (DistanceFromScoreLine2 > -162.f)
					CodyInPlayTickThisScore += 1;

				if (DistanceFromScoreLine3 > -162.f)
					CodyInPlayTickThisScore += 2;
			}
		}

		if (CodyScoreThisTick != MinigameComp.GetCodyScore())
		{
			MinigameComp.SetScore(Game::Cody, CodyScoreThisTick);
			NetScore(Game::Cody, CodyScoreThisTick);
		}

		if (!bPlayedTaunt[1] && InPlayCurlingStone[1] != nullptr)
			if (CodyInPlayTickThisScore >= 2 && InPlayCurlingStone[1].MoveComp.Velocity.Size() < 300.f)
			{
				MinigameComp.PlayTauntAllVOBark(Game::Cody);
				bPlayedTaunt[1] = true;
			}
	}

	UFUNCTION(NetFunction)
	void NetScore(AHazePlayerCharacter Player, int NetScore)
	{
		MinigameComp.SetScore(Player, NetScore);
	}

	UFUNCTION(NetFunction)
	void NetScoreWidgetFeedback(AHazePlayerCharacter Player, int AllocatedScore, ACurlingStone Stone)
	{
		int ScoreDiff = AllocatedScore - Stone.AllocatedPoints;

		FMinigameWorldWidgetSettings WidgetSettings;

		if (Player.IsCody())
			WidgetSettings.MinigameTextColor = EMinigameTextColor::Cody;
		else
			WidgetSettings.MinigameTextColor = EMinigameTextColor::May;
		
		WidgetSettings.MoveSpeed = 1350.f;
		WidgetSettings.TimeDuration = 1.f;
		WidgetSettings.TargetHeight = 2500.f;
		WidgetSettings.MinigameTextMovementType = EMinigameTextMovementType::DeccelerateToHeight;
		WidgetSettings.TextJuice = EInGameTextJuice::BigChange;

		FString InText("");

		if (ScoreDiff < 0)
			InText = String::Conv_IntToString(ScoreDiff);
		else
			InText = "+ " + String::Conv_IntToString(ScoreDiff);

		if (Player.IsCody())
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Cody, InText, Stone.ActorLocation, WidgetSettings);
		else
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::May, InText, Stone.ActorLocation, WidgetSettings);
		
		Stone.AllocatedPoints = AllocatedScore;
	}

	UFUNCTION(NetFunction)
	void ActivatePlayerStone(AHazePlayerCharacter Player)
	{			
		if (Player == Game::GetMay())
		{
			for (ACurlingStone Stone : CurlingStoneArrayMay)
			{
				if (Stone.IsActorDisabled())
				{
					EnableAndStartStone(Stone);
				}

				Stone.bCanPlayRumble = true;
			}
		}
		else		
		{
			for (ACurlingStone Stone : CurlingStoneArrayCody)
			{
				if (Stone.IsActorDisabled())
				{
					EnableAndStartStone(Stone);
				}
				
				Stone.bCanPlayRumble = true;
			}
		}

		UCurlingPlayerInteractComponent PlayerInteractComp = UCurlingPlayerInteractComponent::Get(Player);

		if (PlayerInteractComp != nullptr)
				PlayerInteractComp.bLookAtTube = true;
	}

	void EnableAndStartStone(ACurlingStone CurlingStone)
	{
		if (!CurlingStone.IsActorDisabled())
			return;

		CurlingStone.EnableActor(this);
		CurlingStone.InitializeStone();
	}

	UFUNCTION(NetFunction)
	void StoneOutOfBounds(ACurlingStone InputStone)
	{
		if (CurlingCameraManager[0].TargetStonesArray.Contains(InputStone))
		{
			CurlingCameraManager[0].TargetStonesArray.Remove(InputStone);
			ActiveStonesArrayMay.Remove(InputStone);

			if (CurlingGameState != ECurlingGameState::Complete || CurlingGameState != ECurlingGameState::Inactive)
				MinigameComp.PlayFailGenericVOBark(Game::May);
		}
		else if (CurlingCameraManager[1].TargetStonesArray.Contains(InputStone))
		{
			CurlingCameraManager[1].TargetStonesArray.Remove(InputStone);
			ActiveStonesArrayCody.Remove(InputStone);
			
			if (CurlingGameState != ECurlingGameState::Complete || CurlingGameState != ECurlingGameState::Inactive)
				MinigameComp.PlayFailGenericVOBark(Game::Cody);
		} 

		if (!InputStone.bHasPlayed && HasControl())
			NetUpdatePlaysAndCheckGameState(nullptr);
	}

	UFUNCTION()
	void DisableStone(ACurlingStone Stone)
	{
		Stone.DisableActor(this);
	}
	
	UFUNCTION(NetFunction)
	void NetReturnPlayerDefaultStates(AHazePlayerCharacter InputPlayer)
	{
		UCurlingPlayerComp PlayerComp;
 
		PlayerComp = UCurlingPlayerComp::Get(InputPlayer);
		PlayerComp.bCompleteCamera = true;

		if (InputPlayer == Game::GetMay())
		{
			System::SetTimer(this, n"SetDefaultMayState", 1.5f, false);
			PlayerGameState[0] = EPlayerGameState::Default;
		}
		else
		{
			System::SetTimer(this, n"SetDefaultCodyState", 1.5f, false);
			PlayerGameState[1] = EPlayerGameState::Default;
		} 
	}

	UFUNCTION()
	void SetDefaultMayState()
	{
		PlayerComps[0].PlayerCurlState = EPlayerCurlState::Default;
	}

	UFUNCTION()
	void SetDefaultCodyState()
	{
		PlayerComps[1].PlayerCurlState = EPlayerCurlState::Default;
	}

	float GetDistance(AHazeActor TargetActor, AHazeActor SubjectActor)
	{
		return (TargetActor.ActorLocation - SubjectActor.ActorLocation).Size();
	}

	void ResetCurrentPlayerCompState()
	{
		UCurlingPlayerComp PlayerComp1 = Cast<UCurlingPlayerComp>(Game::GetMay());
		UCurlingPlayerComp PlayerComp2 = Cast<UCurlingPlayerComp>(Game::GetCody());

		if (PlayerComp1 == nullptr || PlayerComp2 == nullptr)
			return; 

		PlayerComp1.PlayerCurlState = EPlayerCurlState::Default;
		PlayerComp2.PlayerCurlState = EPlayerCurlState::Default;
	}

	void TurnOffStoneRumble()
	{
		for (ACurlingStone Stone : CurlingStoneArrayCody)
			Stone.bCanPlayRumble = false;

		for (ACurlingStone Stone : CurlingStoneArrayMay)
			Stone.bCanPlayRumble = false;
	}
}