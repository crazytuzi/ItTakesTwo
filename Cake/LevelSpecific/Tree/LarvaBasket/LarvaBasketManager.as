import Vino.Interactions.DoubleInteractComponent;
import Vino.MinigameScore.MinigameComp;
import Vino.Camera.Actors.StaticCamera;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketHoop;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketCage;

enum ELarvaBasketGameState
{
	Idle,
	Tutorial,
	Countdown,
	Active,
	Finish,
}

ALarvaBasketManager GetLarvaBasketManager() property
{
	auto ManagerComp = ULarvaBasketManagerComponent::Get(Game::May);
	if (ManagerComp == nullptr)
	{
		ManagerComp = ULarvaBasketManagerComponent::Create(Game::May);

		TArray<ALarvaBasketManager> Managers;
		GetAllActorsOfClass(Managers);

		ManagerComp.Manager = Managers[0];
	}

	return ManagerComp.Manager;
}

void LarvaBasketPlayerGainScore(AHazePlayerCharacter Player, int Score)
{
	LarvaBasketManager.Minigame.AdjustScore(Player, Score);
}

bool LarvaBasketGameIsIdle()
{
	return LarvaBasketManager.State == ELarvaBasketGameState::Idle;
}

bool LarvaBasketIsCountdown()
{
	return LarvaBasketManager.State == ELarvaBasketGameState::Countdown;
}

bool LarvaBasketGameIsActive()
{
	return LarvaBasketManager.State == ELarvaBasketGameState::Active;
}

bool LarvaBasketGameIsFinished()
{
	return LarvaBasketManager.State == ELarvaBasketGameState::Finish;
}

FVector LarvaBasketGetForwardVector()
{
	return LarvaBasketManager.Arrow.ForwardVector;
}

UFUNCTION(BlueprintPure, Category = "Minigame|LarvaBasket")
float LarvaBasketGameSpeedMultiplier()
{
	auto Manager = LarvaBasketManager;
	if (Manager.State == ELarvaBasketGameState::Idle ||
		Manager.State == ELarvaBasketGameState::Finish)
		return 0.f;

	if (Manager.Timer < 30.f)
		return -1.5f;

	return 1.f;
}

UFUNCTION(Category = "Minigame|LarvaBasket")
void LarvaBasketPlayThrowBark(AHazePlayerCharacter Player)
{
	LarvaBasketManager.Minigame.PlayTauntUniqueVOBark(Player);
}

UFUNCTION(Category = "Minigame|LarvaBasket")
void LarvaBasketPlayHitBark(AHazePlayerCharacter Player)
{
	LarvaBasketManager.Minigame.PlayTauntGenericVOBark(Player);
}

UFUNCTION(Category = "Minigame|LarvaBasket")
void LarvaBasketPlayMissBark(AHazePlayerCharacter Player)
{
	LarvaBasketManager.Minigame.PlayFailGenericVOBark(Player);
}

UFUNCTION(Category = "Minigame|LarvaBasket")
void LarvaBasketPlayPendingBark(AHazePlayerCharacter Player)
{
	LarvaBasketManager.Minigame.PlayPendingStartVOBark(Player, LarvaBasketManager.ActorLocation);
}

class ULarvaBasketManagerComponent : UActorComponent
{
	ALarvaBasketManager Manager;
}

class ALarvaBasketManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	AStaticCamera Camera;

	UPROPERTY(DefaultComponent)
	UMinigameComp Minigame;
	default Minigame.bCodyAutoReactionAnimations = false;
	default Minigame.bMayAutoReactionAnimations = false;
	default Minigame.ScoreData.MinigameName = NSLOCTEXT("Minigames", "BumblebeeBasket", "Bumblebee Basket");
	default Minigame.MinigameID = FName("Bumblebee Basket");
	default Minigame.MinigameTag = EMinigameTag::BumblebeeBasket;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	TArray<ALarvaBasketHoopSpawner> HoopSpawners;
	TArray<ALarvaBasketCage> Cages;
	ELarvaBasketGameState State = ELarvaBasketGameState::Idle;
	float Timer = 0.f;

	TPerPlayer<bool> bCanPlayReaction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnTriggered.AddUFunction(this, n"HandleDoubleInteractTriggered");
		Minigame.OnCountDownCompletedEvent.AddUFunction(this, n"HandleCountdownFinished");
		Minigame.OnMinigameVictoryScreenFinished.AddUFunction(this, n"HandleVictoryScreenFinished");
		Minigame.OnMinigameTutorialComplete.AddUFunction(this, n"HandleTutorialFinished");
		Minigame.OnTutorialCancel.AddUFunction(this, n"HandleTutorialCancelled");

		GetAllActorsOfClass(HoopSpawners);
		GetAllActorsOfClass(Cages);

		// Hoop spawners are disabled by default
		for(auto Spawner : HoopSpawners)
			Spawner.DisableActor(this);
	}

	UFUNCTION()
	void HandleDoubleInteractTriggered()
	{
		State = ELarvaBasketGameState::Tutorial;
		Timer = LarvaBasket::GameDuration;
		Minigame.ActivateTutorial();

		BP_OnMinigameStart();
	}

	UFUNCTION()
	void HandleTutorialFinished()
	{
		StartNewGame();
	}

	UFUNCTION()
	void HandleTutorialCancelled()
	{
		State = ELarvaBasketGameState::Idle;
		BP_OnMinigameEnd();
	}

	UFUNCTION()
	void HandleCountdownFinished()
	{
		State = ELarvaBasketGameState::Active;
		//Doesn't really matter where this calls, as long as these start as true at the beginning of the game	
		bCanPlayReaction[0] = true;
		bCanPlayReaction[1] = true;
	}

	UFUNCTION()
	void HandleVictoryScreenFinished()
	{
		for(auto Cage : Cages)
			Cage.Interaction.Enable(n"GameInProgress");

		State = ELarvaBasketGameState::Idle;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		switch(State)
		{
			case ELarvaBasketGameState::Idle:
			{
				break;
			}

			case ELarvaBasketGameState::Countdown:
			{
				break;
			}

			case ELarvaBasketGameState::Active:
			{
				Timer -= DeltaTime;
				if (Timer <= 0.f)
				{
					if (HasControl())
						NetEndGame();

					Timer = 0.f;
				}

				Minigame.ScoreHud.SetTime(Timer);
				break;
			}
		}
	}

	void StartNewGame()
	{
		State = ELarvaBasketGameState::Countdown;
		Timer = LarvaBasket::GameDuration;

		Minigame.ResetScoreBoth();
		Minigame.StartCountDown();
		Minigame.ScoreHud.SetTime(Timer);

		for(auto Spawner : HoopSpawners)
			Spawner.EnableActor(this);

		for(auto Cage : Cages)
			Cage.Interaction.Disable(n"GameInProgress");

		//Bools set by LarvaBasketBallGrabCapability to ensure no conflict with animation if playing that animation
		if (bCanPlayReaction[0])
			PlayReactionAnimation(Game::May);

		if (bCanPlayReaction[1])
			PlayReactionAnimation(Game::Cody);
	}

	void RequestGiveUp(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (State != ELarvaBasketGameState::Active)
			return;

		NetGiveUp(Player);
	}

	UFUNCTION(NetFunction)
	void NetGiveUp(AHazePlayerCharacter GiveUpPlayer)
	{
		State = ELarvaBasketGameState::Finish;
		Minigame.AnnounceWinner(GiveUpPlayer.OtherPlayer);

		for(auto Spawner : HoopSpawners)
			Spawner.DisableActor(this);

		BP_OnMinigameEnd();
	}

	UFUNCTION(NetFunction)
	void NetEndGame()
	{
		State = ELarvaBasketGameState::Finish;
		Minigame.AnnounceWinner();

		Timer = 0.f;
		Minigame.ScoreHud.SetTime(Timer);

		for(auto Spawner : HoopSpawners)
			Spawner.DisableActor(this);

		BP_OnMinigameEnd();
	}

	//Manual call for reaction animations if not automatically called - come from onblendout delegate in LarvaBasketBallGrabCapability
	UFUNCTION()
	void PlayReactionAnimation(AHazePlayerCharacter Player)
	{
		Minigame.ActivateReactionAnimations(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMinigameStart() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnMinigameEnd() {}
}