import Cake.LevelSpecific.Tree.PlungerGun.PlungerGun;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunTarget;
import Vino.MinigameScore.MinigameComp;
import Vino.Interactions.DoubleInteractComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;

enum EPlungerGunGameState
{
	Idle,
	Tutorial,
	Countdown,
	Active,
	Resetting
}

APlungerGunManager GetPlungerGunManager() property
{
	auto ManagerComp = UPlungerGunManagerComponent::Get(Game::May);

	// If there's no manager saved, create component and find the manager
	if (ManagerComp == nullptr)
	{
		ManagerComp = UPlungerGunManagerComponent::Create(Game::May);

		TArray<APlungerGunManager> Manager;
		GetAllActorsOfClass(Manager);

		ManagerComp.Manager = Manager[0];
	}

	return ManagerComp.Manager;
}

bool PlungerGunGameIsIdle()
{
	return PlungerGunManager.State == EPlungerGunGameState::Idle;
}

bool PlungerGunGameIsActive()
{
	return PlungerGunManager.State == EPlungerGunGameState::Active;
}

bool PlungerGunGameIsResetting()
{
	return PlungerGunManager.State == EPlungerGunGameState::Resetting;
}

AHazePlayerCharacter PlungerGunGetFrontPlayer()
{
	return PlungerGunManager.FrontGun.CurrentPlayer;
}

AHazePlayerCharacter PlungerGunGetBackPlayer()
{
	return PlungerGunManager.BackGun.CurrentPlayer;
}

FVector PlungerGunGetGameForward()
{
	auto Manager = PlungerGunManager;
	FVector Diff = Manager.FrontGun.ActorLocation - Manager.BackGun.ActorLocation;
	Diff = Diff.ConstrainToPlane(FVector::UpVector);
	Diff.Normalize();

	return Diff;
}

void PlungerGunTargetReachedEdge(APlungerGunTarget Target, bool bFront)
{
	PlungerGunManager.TargetReachedEdge(Target, bFront);
}

void PlungerGunIncreaseTargetCounter()
{
	PlungerGunManager.IncreaseTargetCounter();
}

void PlungerGunDecreaseTargetCounter()
{
	PlungerGunManager.DecreaseTargetCounter();
}

UFUNCTION(Category = "Minigames|PlungerGun")
void PlungerGunPlayShootBark(AHazePlayerCharacter Player)
{
	PlungerGunManager.Minigame.PlayTauntUniqueVOBark(Player);
}

UFUNCTION(Category = "Minigames|PlungerGun")
void PlungerGunPlayHitBark(AHazePlayerCharacter Player)
{
	PlungerGunManager.Minigame.PlayTauntGenericVOBark(Player);
}

UFUNCTION(Category = "Minigames|PlungerGun")
void PlungerGunPlayFailBark(AHazePlayerCharacter Player)
{
	PlungerGunManager.Minigame.PlayFailGenericVOBark(Player);
}

UFUNCTION(Category = "Minigames|PlungerGun")
void PlungerGunPlayPendingBark(AHazePlayerCharacter Player)
{
	auto Manager = PlungerGunManager;
	APlungerGun OtherGun = nullptr;

	if (Manager.FrontGun.CurrentPlayer == Player)
		OtherGun = Manager.BackGun;
	else
		OtherGun = Manager.FrontGun;

	PlungerGunManager.Minigame.PlayPendingStartVOBark(Player, OtherGun.ActorLocation);
}

class UPlungerGunManagerComponent : UActorComponent
{
	APlungerGunManager Manager;
}

class APlungerGunManager : AHazeActor
{
	int NumActivePlayers = 0;
	int ActiveTargetCounter = 0;

	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp Minigame;
	default Minigame.bPlayWinningAnimations = false;
	default Minigame.bPlayLosingAnimations = false;
	default Minigame.bPlayDrawAnimations = false;
	default Minigame.MinigameTag = EMinigameTag::PlungerDunger;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(EditInstanceOnly, Category = "Game")
	APlungerGun FrontGun;

	UPROPERTY(EditInstanceOnly, Category = "Game")
	APlungerGun BackGun;

	int MayScore;
	int CodyScore;
	float GameTime;

	EPlungerGunGameState State;

	TArray<APlungerGunTarget> Targets;
	float ShowTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(Targets);
		DoubleInteract.OnTriggered.AddUFunction(this, n"HandleDoubleInteractTriggered");
		Minigame.OnCountDownCompletedEvent.AddUFunction(this, n"HandleCountdownFinished");
		Minigame.OnTutorialCancel.AddUFunction(this, n"HandleTutorialCancelled");
		Minigame.OnMinigameTutorialComplete.AddUFunction(this, n"StartNewGame");
	}

	UFUNCTION()
	void HandleDoubleInteractTriggered()
	{		
		State = EPlungerGunGameState::Tutorial;
		Minigame.ActivateTutorial();
	}

	UFUNCTION()
	void HandleTutorialCancelled()
	{
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			auto PlayerComp = UPlungerGunPlayerComponent::Get(Player);
			PlayerComp.ExitGun();
		}

		State = EPlungerGunGameState::Resetting;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		switch(State)
		{
			// Wait for both players to enter the turrets
			// (double interact will trigger a game start)
			case EPlungerGunGameState::Idle:
			{
				break;
			}

			// Game is active and running
			case EPlungerGunGameState::Active:
			{
				GameTime -= DeltaTime;
				if (GameTime < 0.f)
				{
					if (HasControl())
						NetFinishGame(MayScore, CodyScore);
				}

				Minigame.ScoreHud.SetTime(GameTime);
				break;
			}

			// Wait until all targets have been reset, then go idle
			case EPlungerGunGameState::Resetting:
			{
				bool bEverythingIsReset = true;
				for(auto Target : Targets)
				{
					if (Target.State == EPlungerGunTargetState::Resetting)
					{
						bEverythingIsReset = false;
						break;
					}
				}

				if (bEverythingIsReset)
				{
					State = EPlungerGunGameState::Idle;

					// Enable interactions again!
					FrontGun.Interaction.Enable(n"GameActive");
					BackGun.Interaction.Enable(n"GameActive");

					// Minigame.EndGameHud();
				}

				break;
			}
		}
	}

/*
	void ShowRandomTarget()
	{
		TArray<APlungerGunTarget> HiddenTargets;
		for(auto Target : Targets)
		{
			if (Target.State == EPlungerGunTargetState::Hidden)
				HiddenTargets.Add(Target);
		}

		if (HiddenTargets.Num() == 0)
			return;

		int Index = FMath::RandRange(0, HiddenTargets.Num() - 1);
		HiddenTargets[Index].NetActivateTarget();
	}
	*/

	UFUNCTION()
	void StartNewGame()
	{
		GameTime = PlungerGun::GameDuration;

		State = EPlungerGunGameState::Countdown;
		Minigame.StartCountDown();
		Minigame.ResetScoreBoth();
		Minigame.ScoreHud.SetTime(GameTime);

		// Disable plungergun interactions until game is done
		FrontGun.Interaction.Disable(n"GameActive");
		BackGun.Interaction.Disable(n"GameActive");
	}

	UFUNCTION()
	void HandleCountdownFinished()
	{
		State = EPlungerGunGameState::Active;

		// Activate all the targets!
		for(auto Target : Targets)
			Target.ActivateTarget();
	}

	void TargetReachedEdge(APlungerGunTarget ReachTarget, bool bFront)
	{
		if (State != EPlungerGunGameState::Active)
			return;

		// The winner is the gun OPPOSITE of the edge the target reached
		// Since the side the target reached is the loser
		auto ScoringGun = bFront ? BackGun : FrontGun;

		FMinigameWorldWidgetSettings MinigameWorldSettings;
		
		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange; //Animation 'juice' that will be added later
		
		MinigameWorldSettings.MoveSpeed = 30.f; // Starting move speed
		MinigameWorldSettings.TimeDuration = 0.75f; // How long it should last for before it fades out or completely disappears
		MinigameWorldSettings.FadeDuration = 0.6f; // Opacity fade time
		MinigameWorldSettings.TargetHeight = 140.f; // If movement type is 'ToHeight', the height it will reach before stopping
		
		FVector DrawLocation = ReachTarget.SwingRoot.GetWorldLocation();
		DrawLocation.Z += 200.f;

		PlungerGunPlayFailBark(ScoringGun.CurrentPlayer.OtherPlayer);

		if (ScoringGun.CurrentPlayer.IsMay())
		{
			MayScore++;
			Minigame.SetScore(Game::May, MayScore);
			MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::May;	
		}
		else
		{
			CodyScore++;
			Minigame.SetScore(Game::Cody, CodyScore);
			MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::Cody;
		}

		Minigame.CreateMinigameWorldWidgetNumber(EMinigameTextPlayerTarget::Cody, 1, DrawLocation, MinigameWorldSettings);
		Minigame.CreateMinigameWorldWidgetNumber(EMinigameTextPlayerTarget::May, 1, DrawLocation, MinigameWorldSettings);
	}

	UFUNCTION(NetFunction)
	void NetFinishGame(int InMayScore, int InCodyScore)
	{
		MayScore = InMayScore;
		CodyScore = InCodyScore;
		
		Minigame.SetScore(Game::May, InMayScore);
		Minigame.SetScore(Game::Cody, InCodyScore);

		GameTime = 0.f;
		Minigame.ScoreHud.SetTime(GameTime);

		// if (MayScore == CodyScore)
		// 	Minigame.ShowWinnerAndSetHighScore(EMinigameWinner::Draw);
		// else
		// 	Minigame.ShowWinnerAndSetHighScore(MayScore > CodyScore ? EMinigameWinner::May : EMinigameWinner::Cody);

		Minigame.AnnounceWinner();

		// Reset all targets
		for(auto Target : Targets)
			Target.ResetTarget();

		MayScore = 0;
		CodyScore = 0;
		State = EPlungerGunGameState::Resetting;
	}

	UFUNCTION(NetFunction)
	void NetRequestGiveUp(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (State != EPlungerGunGameState::Active)
			return;

		NetEndGamePrematurely(Player.OtherPlayer);
	}

	UFUNCTION(NetFunction)
	void NetEndGamePrematurely(AHazePlayerCharacter Winner)
	{
		GameTime = 0.f;
		Minigame.AnnounceWinner(Winner);

		// Reset all targets
		for(auto Target : Targets)
			Target.ResetTarget();

		MayScore = 0;
		CodyScore = 0;
		State = EPlungerGunGameState::Resetting;
	}

	void IncreaseTargetCounter()
	{
		if (ActiveTargetCounter == 0)
			BP_OnTargetsActivate();

		ActiveTargetCounter++;
	}

	void DecreaseTargetCounter()
	{
		ActiveTargetCounter--;

		if (ActiveTargetCounter == 0)
			BP_OnTargetsDeactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTargetsActivate()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_OnTargetsDeactivate()
	{}
}