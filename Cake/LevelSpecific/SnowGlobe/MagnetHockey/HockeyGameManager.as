import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyGoals;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyStartingPoint;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyBeepIndicator;
import Vino.Interactions.DoubleInteractComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;

enum EHockeyGameState
{
	Inactive,
	GameInPlay,
	AnnouncingWinner
};

class AHockeyGameManager : AHazeActor
{
	EHockeyGameState HockeyGameState;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;
	
	// UPROPERTY(Category = "Setup")
	// TPerPlayer<AHockeyStartingPoint> HockeyStartingPoints;

	UPROPERTY(Category = "Setup")
	TPerPlayer<AHockeyPaddle> HockeyPaddles;

	UPROPERTY(Category = "Setup")
	TPerPlayer<AHockeyGoals> HockeyGoals;

	UPROPERTY(Category = "Setup")
	AHockeyBeepIndicator HockeyBeepIndicator;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor GameCamera;

	TPerPlayer<AHazePlayerCharacter> PlayerReferences;

	TPerPlayer<UHockeyPlayerComp> PlayerComps;

	TArray<AHockeyPuck> HockeyPuckArray;

	AHockeyPuck HockeyPuck;

	FVector PuckStartingPos;

	float CameraPitchAddition = -30.f;

	int Players;
	int MaxPlayers = 2;

	int MayScore;
	int CodyScore;

	float MaxGameTime = 120.f;
	float CurrentGameTime;

	bool bIsCountingDown;

	float GameStartDelay = 0.8f;
	float CurrentGameStartTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(HockeyPuckArray);
		HockeyPuck = HockeyPuckArray[0];

		PuckStartingPos = HockeyPuck.ActorLocation;

		HockeyPaddles[0].InteractComp.OnActivated.AddUFunction(this, n"OnInteracting");
		HockeyPaddles[1].InteractComp.OnActivated.AddUFunction(this, n"OnInteracting");

		HockeyPaddles[0].OnHockeyPlayerLeftEvent.AddUFunction(this, n"OnCancelInteracting");
		HockeyPaddles[1].OnHockeyPlayerLeftEvent.AddUFunction(this, n"OnCancelInteracting");

		DoubleInteract.OnTriggered.AddUFunction(this, n"InitiateCountDown");

		PlayerReferences[0] = Game::GetMay();
		PlayerReferences[1] = Game::GetCody();

		HockeyGoals[0].OnGoalScoredEvent.AddUFunction(this, n"UdpateScore");
		HockeyGoals[1].OnGoalScoredEvent.AddUFunction(this, n"UdpateScore");

		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"StartGame");

		HockeyBeepIndicator.OnTimerCompleteEvent.AddUFunction(this, n"StartNextPlay");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MinigameComp.CountDownSeconds <= 2.f && bIsCountingDown)
		{
			bIsCountingDown = false;
			HockeyBeepIndicator.BeepIndicatorState = EBeepIndicatorState::BeepTime; 
		}

		if (HockeyGameState == EHockeyGameState::GameInPlay)
		{
			CurrentGameTime -= DeltaTime;
			PrintToScreen("CurrentGameTime: " + CurrentGameTime);

			if(CurrentGameTime <= 0.f)
				AnnounceWinner();
		}
	}

	UFUNCTION()
	void OnInteracting(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(PlayerCapabilitySheet, EHazeCapabilitySheetPriority::High, this);
		
		if (Player == Game::GetMay())
		{
			PlayerComps[0] = UHockeyPlayerComp::Get(Player);
			PlayerComps[0].bCanCancel = true;
			PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::MovementBlocked;

			AHockeyPaddle HockeyPaddle = Cast<AHockeyPaddle>(InteractComp.Owner);
			PlayerComps[0].HockeyPaddle = HockeyPaddle;

			PlayerComps[0].GameCamera = GameCamera;
		}
		else
		{
			PlayerComps[1] = UHockeyPlayerComp::Get(Player);
			PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::MovementBlocked;
			PlayerComps[1].bCanCancel = true;

			AHockeyPaddle HockeyPaddle = Cast<AHockeyPaddle>(InteractComp.Owner);
			PlayerComps[1].HockeyPaddle = HockeyPaddle;

			PlayerComps[1].GameCamera = GameCamera;
		} 

		InteractComp.Disable(n"Hockey Gameplay");
		DoubleInteract.StartInteracting(Player);
	}

	UFUNCTION()
	void OnCancelInteracting(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		DoubleInteract.CancelInteracting(Player);
		Player.RemoveCapabilitySheet(PlayerCapabilitySheet, this);
		
		if (Player == Game::May)
			PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::Default;
		else
			PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::Default;

		InteractComp.Enable(n"Hockey Gameplay");
	}

	UFUNCTION()
	void InitiateCountDown()
	{
		PlayerComps[0].bCanCancel = false;
		PlayerComps[1].bCanCancel = false;

		PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::Countdown;
		PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::Countdown;

		MinigameComp.StartCountDown();

		HockeyBeepIndicator.BeepIndicatorState = EBeepIndicatorState::MoveDown; 
		HockeyBeepIndicator.bIsTimedWithCountdown = true;

		bIsCountingDown = true;
	}

	UFUNCTION()
	void StartGame()
	{
		MayScore = 0;
		CodyScore = 0;

		HockeyGameState = EHockeyGameState::GameInPlay;

		CurrentGameTime = MaxGameTime;

		PlayerComps[0] = UHockeyPlayerComp::Get(Game::GetMay());
		PlayerComps[1] = UHockeyPlayerComp::Get(Game::GetCody());

		PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::InPlay;
		PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::InPlay;

		HockeyGoals[0].bCanScore = true;
		HockeyGoals[1].bCanScore = true;

		HockeyBeepIndicator.bIsTimedWithCountdown = false;

		HockeyPuck.StartPuckPlay(1);
	}

	UFUNCTION()
	void SetPlayerReadyPosition(AHazePlayerCharacter Player, UHockeyPlayerComp PlayerComp, AHockeyStartingPoint StartingPoint)
	{
		Player.AddCapabilitySheet(PlayerCapabilitySheet, EHazeCapabilitySheetPriority::Normal, this);

		PlayerComp = UHockeyPlayerComp::Get(Player);

		PlayerComp.HockeyPlayerState = EHockeyPlayerState::MovementBlocked;
		
		FVector FacingDirection;

		FacingDirection = (HockeyPuck.ActorLocation - Player.ActorLocation).GetSafeNormal();

		// PlayerComp.SmoothRotation = FRotator::MakeFromX(FacingDirection);

		// PlayerComp.SmoothRotation += FRotator(CameraPitchAddition, 0.f, 0.f);

		PlayerComp.StartingPointRef = StartingPoint;
	}

	UFUNCTION()
	void StartNextPlay()
	{
		PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::InPlay;
		PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::InPlay;

		HockeyGoals[0].ResetbScoringState();
		HockeyGoals[1].ResetbScoringState();

		HockeyGoals[0].bCanScore = true;
		HockeyGoals[1].bCanScore = true;

		HockeyPuck.StartPuckPlay(-1);
	}

	UFUNCTION()
	void EndGame()
	{
		PlayerReferences[0].RemoveCapabilitySheet(PlayerCapabilitySheet, this);
		PlayerReferences[1].RemoveCapabilitySheet(PlayerCapabilitySheet, this);

		HockeyGameState = EHockeyGameState::Inactive;

		HockeyGoals[0].bCanScore = false;
		HockeyGoals[1].bCanScore = false;

		// MinigameComp.EndGameHud();

		HockeyGameState = EHockeyGameState::Inactive;

		SetPuckStartingPosition();

		PlayerComps[0].HockeyPaddle.InteractComp.Enable(n"Hockey Gameplay");
		PlayerComps[1].HockeyPaddle.InteractComp.Enable(n"Hockey Gameplay");
	}

	UFUNCTION()
	void AnnounceWinner()
	{
		// if (CodyScore > MayScore)
		// 	MinigameComp.ShowWinnerAndSetHighScore(EMinigameWinner::Cody);
		// else if (MayScore > CodyScore)
		// 	MinigameComp.ShowWinnerAndSetHighScore(EMinigameWinner::May);
		// else 
		// 	MinigameComp.ShowWinnerAndSetHighScore(EMinigameWinner::Draw);

		HockeyGameState = EHockeyGameState::AnnouncingWinner;

		System::SetTimer(this, n"EndGame", 1.f, false);
	}

	UFUNCTION()
	void AddPlayer()
	{
		Players++;

		if (Players == MaxPlayers)
		{
			if (HockeyGameState == EHockeyGameState::Inactive)
			{
				CurrentGameStartTimer = GameStartDelay;
				// bCanSetGameStartTimer = true;
			}
		}
	}

	UFUNCTION()
	void RemovePlayer()
	{
		Players--;
		// bCanSetGameStartTimer = false;
	}

	UFUNCTION()
	void UdpateScore(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
		{
			MayScore++;
			MinigameComp.SetScore(Game::GetMay(), MayScore);
		}
		else
		{
			CodyScore++;
			MinigameComp.SetScore(Game::GetCody(), CodyScore);
		}

		GameScoreEvent();
	}

	UFUNCTION()
	void GameScoreEvent()
	{
		// PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::ResetNextPlay;
		// PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::ResetNextPlay;
		System::SetTimer(this, n"SetPuckStartingPosition", 0.5f, false);
	}

	UFUNCTION()
	void SetPuckStartingPosition()
	{
		//Issues with resetting - perhaps net find middle location should be turned off temporarily, reset puck, then set back on
		HockeyPuck.SetActorLocation(PuckStartingPos);
		HockeyPuck.OtherVelocity = 0.f;
		HockeyPuck.OtherSidePosition = PuckStartingPos;

		HockeyPuck.ZeroOutPuckValues();

		// PlayerComps[0].HockeyPlayerState = EHockeyPlayerState::MovementBlocked;
		// PlayerComps[1].HockeyPlayerState = EHockeyPlayerState::MovementBlocked;

		HockeyBeepIndicator.BeepIndicatorState = EBeepIndicatorState::MoveDown;

		HockeyBeepIndicator.SetRed();
	}
}