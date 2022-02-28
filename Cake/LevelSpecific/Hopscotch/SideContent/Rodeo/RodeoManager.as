import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Hopscotch.SideContent.Rodeo.RodeoMechanicalBull;
import Vino.MinigameScore.ScoreHud;
import Vino.MinigameScore.MinigameStatics;
import Vino.MinigameScore.MinigameComp;
import Vino.Interactions.DoubleInteractionJumpTo;

class ARodeoManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::Rodeo;

	UPROPERTY()
	ARodeoMechanicalBull MayRodeoBull;

	UPROPERTY()
	ARodeoMechanicalBull CodyRodeoBull;

	UPROPERTY()
	ADoubleInteractionJumpTo DoubleInteraction;

	bool bGameActive = false;

	bool bMayOnBull = false;
	bool bCodyOnBull = false;

	bool bMayThrowOffCheckFinished = false;
	bool bCodyThrowOffCheckFinished = false;

	bool bMayThrownOff = false;
	bool bCodyThrownOff = false;

	bool bLocalDrawCheckStarted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MayRodeoBull.OnPlayerThrownOff.AddUFunction(this, n"PlayerThrownOff");
		CodyRodeoBull.OnPlayerThrownOff.AddUFunction(this, n"PlayerThrownOff");

		MayRodeoBull.OnPlayerSuccess.AddUFunction(this, n"PlayerSuccess");
		CodyRodeoBull.OnPlayerSuccess.AddUFunction(this, n"PlayerSuccess");
		MayRodeoBull.OnPlayerFail.AddUFunction(this, n"PlayerFail");
		CodyRodeoBull.OnPlayerFail.AddUFunction(this, n"PlayerFail");

		DoubleInteraction.LeftInteraction.DisableForPlayer(Game::GetCody(), n"Cody");
		DoubleInteraction.RightInteraction.DisableForPlayer(Game::GetMay(), n"May");
		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"DoubleInteractionCompleted");
		
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"TutorialCompleted");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialCancelled");

		System::SetTimer(this, n"AttachInteractionPoints", 0.2f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void AttachInteractionPoints()
	{
		DoubleInteraction.LeftInteraction.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		DoubleInteraction.RightInteraction.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	}

	UFUNCTION(NotBlueprintCallable)
	void DoubleInteractionCompleted()
	{
		StartCountdown();

		DoubleInteraction.LeftInteraction.Disable(n"RodeoActive");
		DoubleInteraction.RightInteraction.Disable(n"RodeoActive");

		bMayThrownOff = false;
		bMayThrowOffCheckFinished = false;
		bCodyThrownOff = false;
		bCodyThrowOffCheckFinished = false;
		bLocalDrawCheckStarted = false;
	}

	UFUNCTION()
	void StartCountdown()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			ARodeoMechanicalBull Bull = Player.IsMay() ? MayRodeoBull : CodyRodeoBull;
			Player.SetCapabilityAttributeObject(n"RodeoBull", Bull);
			Player.SetCapabilityActionState(n"RodeoMount", EHazeActionState::Active);
		}

		MinigameComp.ActivateTutorial();
	}

	UFUNCTION(NotBlueprintCallable)
	void TutorialCancelled()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.SetCapabilityActionState(n"Rodeo", EHazeActionState::Inactive);
			Player.SetCapabilityActionState(n"RodeoMount", EHazeActionState::Inactive);
		}

		DoubleInteraction.LeftInteraction.Enable(n"RodeoActive");
		DoubleInteraction.RightInteraction.Enable(n"RodeoActive");
	}

	UFUNCTION(NotBlueprintCallable)
	void TutorialCompleted()
	{
		MinigameComp.StartCountDown();
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownCompleted");
	}

	UFUNCTION(NotBlueprintCallable)
	void CountdownCompleted()
	{
		StartGame();
	}

	void StartGame()
	{
		bGameActive = true;
		MayRodeoBull.StartBucking();
		CodyRodeoBull.StartBucking();
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerSuccess(AHazePlayerCharacter Player)
	{
		NetPlaySuccessBark(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerFail(AHazePlayerCharacter Player)
	{
		NetPlayFailBark(Player);
	}

	UFUNCTION(NetFunction)
	void NetPlaySuccessBark(AHazePlayerCharacter Player)
	{
		MinigameComp.PlayTauntAllVOBark(Player);
	}

	UFUNCTION(NetFunction)
	void NetPlayFailBark(AHazePlayerCharacter Player)
	{
		MinigameComp.PlayFailGenericVOBark(Player);
	}

	UFUNCTION()
	void PlayerThrownOff(AHazePlayerCharacter Player)
	{
		if (Network::IsNetworked())
		{
			if (Player.HasControl())
			{
				if (Player.IsMay())
					bMayThrownOff = true;
				else
					bCodyThrownOff = true;

				NetGameOver();
			}
			return;
		}

		if (!bGameActive)
			return;

		if (Player == Game::GetMay())
			bMayThrownOff = true;
		else if (Player == Game::GetCody())
			bCodyThrownOff = true;

		if (!bLocalDrawCheckStarted)
		{
			bLocalDrawCheckStarted = true;
			System::SetTimer(this, n"LocalCheckWinner", 0.1f, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LocalCheckWinner()
	{
		bGameActive = false;

		if (bMayThrownOff && bCodyThrownOff)
			MinigameComp.AnnounceWinner(EMinigameWinner::Draw);
		else if (bMayThrownOff)
			MinigameComp.AnnounceWinner(Game::GetCody());
		else if (bCodyThrownOff)
			MinigameComp.AnnounceWinner(Game::GetMay());
		else
			MinigameComp.AnnounceWinner(EMinigameWinner::Draw);

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
			CurPlayer.SetCapabilityActionState(n"Rodeo", EHazeActionState::Inactive);

		EnableInteractions();
	}

	UFUNCTION(NetFunction)
	void NetGameOver()
	{
		if (!bGameActive)
			return;
		
		bGameActive = false;

		if (Game::GetCody().HasControl())
			NetDecideWinner(Game::GetCody(), bCodyThrownOff);

		if (Game::GetMay().HasControl())
			NetDecideWinner(Game::GetMay(), bMayThrownOff);
	}

	UFUNCTION(NetFunction)
	void NetDecideWinner(AHazePlayerCharacter Player, bool bPlayerThrownOff)
	{
		if (Player == Game::GetMay())
		{
			bMayThrownOff = bPlayerThrownOff;
			bMayThrowOffCheckFinished = true;
		}
		
		if (Player == Game::GetCody())
		{
			bCodyThrownOff = bPlayerThrownOff;
			bCodyThrowOffCheckFinished = true;
		}

		if (bMayThrowOffCheckFinished && bCodyThrowOffCheckFinished)
		{
			EnableInteractions();

			if (bCodyThrownOff && bMayThrownOff)
			{
				MinigameComp.AnnounceWinner(EMinigameWinner::Draw);
				return;
			}

			if (bMayThrownOff)
				MinigameComp.AnnounceWinner(EMinigameWinner::Cody);
			else
				MinigameComp.AnnounceWinner(EMinigameWinner::May);

			for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
				CurPlayer.SetCapabilityActionState(n"Rodeo", EHazeActionState::Inactive);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableInteractions()
	{
		DoubleInteraction.LeftInteraction.Enable(n"RodeoActive");
		DoubleInteraction.RightInteraction.Enable(n"RodeoActive");
	}
}