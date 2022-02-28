import Vino.MinigameScore.ScoreHud;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightOutsideManager;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;

event void FOnCompletedSnowballArenaGameEventSignature();
event void FOnSnowballCountdownCompletedEventSignature();
event void FOnSnowballFightTutorialCancelledSignature();

class USnowballFightManagerComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	int ScorePerHit = 1;

	bool BothPlayersInArea = false;
	bool GameStarted = false;
	bool bAnnouncingWinner;

	FTimerHandle ResetTimer;

	FOnCompletedSnowballArenaGameEventSignature RoundCompletedEvent;
	FOnSnowballCountdownCompletedEventSignature CountdownCompletedEvent;
	FOnSnowballFightTutorialCancelledSignature TutorialCancelledEvent;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheetDefault;
	default PlayerCapabilitySheetDefault = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/SnowballFight/DA_SnowballFightDefault_CapabilitySheet");

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheetActive;
	default PlayerCapabilitySheetActive = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/SnowballFight/DA_SnowballFightActive_CapabilitySheet");

	TArray<ASnowballFightOutsideManager> OutsideManagerArray;
	ASnowballFightOutsideManager OutsideManager;

    UMinigameComp MinigameComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(OutsideManagerArray);

		MinigameComp = UMinigameComp::Get(Owner);

		if (MinigameComp != nullptr)
		{
			MinigameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"OnPlayerLeft");
		}

		if (OutsideManagerArray.Num() > 0)
			OutsideManager = OutsideManagerArray[0];

		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"VictoryScreenFinished");
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownFinished");
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartSnowballFight");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelTutorial");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (BothPlayersInArea)
		{
			Game::May.EnableOutlineByInstigator(this);
			Game::Cody.EnableOutlineByInstigator(this);			
		}
	}

	UFUNCTION()
	void CancelTutorial()
	{
		TutorialCancelledEvent.Broadcast();
	}

	UFUNCTION()
	void StartSnowballFight()
	{
		MinigameComp.StartCountDown();
		MinigameComp.ScoreHud.SetScoreBoxVisibility(false);

		BothPlayersInArea = true;
		
		Game::May.DisableOutlineByInstigator(this);
		Game::Cody.DisableOutlineByInstigator(this);
	}

	UFUNCTION()
	void OnPlayerLeft(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
			MinigameComp.AnnounceWinner(Game::GetCody());
		else
			MinigameComp.AnnounceWinner(Game::GetMay());
	}

	void StopSnowballFight()
	{
		BothPlayersInArea = false;

		Game::May.EnableOutlineByInstigator(this);
		Game::Cody.EnableOutlineByInstigator(this);
	}

	UFUNCTION()
	void CountdownFinished()
	{
		// We need to add the default capability sheet to both players _if_ they don't already exist
		// Relying on instigator wouldn't work well in this case, since we need to remove it later
		for (auto Player : Game::Players)
		{
			auto SnowballComp = USnowballFightComponent::Get(Player);

			if (SnowballComp == nullptr)
			{
				Player.AddCapabilitySheet(PlayerCapabilitySheetDefault);
				Player.AddCapabilitySheet(PlayerCapabilitySheetActive);
				SnowballComp = USnowballFightComponent::Get(Player);
				SnowballComp.bHasActiveSheet = true;
			}
			else if (!SnowballComp.bHasActiveSheet)
			{
				Player.AddCapabilitySheet(PlayerCapabilitySheetActive);
				SnowballComp.bHasActiveSheet = true;
			}
		}

		USnowballFightComponent PlayerComp1 = USnowballFightComponent::Get(Game::GetMay());
		USnowballFightComponent PlayerComp2 = USnowballFightComponent::Get(Game::GetCody());

		PlayerComp1.RefillSnowballs();
		PlayerComp2.RefillSnowballs();

		GameStarted = true;
		CountdownCompletedEvent.Broadcast();
	}

	UFUNCTION()
	void VictoryScreenFinished()
	{
		MinigameComp.EndGameHud();
		ResetMinigame();
	}

	UFUNCTION(NetFunction)
	void NetAddCodyScore(int ScoreToAdd)
	{
		if(!BothPlayersInArea || !GameStarted)
			return;

		if(MinigameComp.ScoreData.CodyScore >= MinigameComp.ScoreData.ScoreLimit)
			return;

		MinigameComp.AdjustScore(Game::GetCody(), ScoreToAdd);
		MinigameComp.PlayTauntAllVOBark(Game::Cody);
		FMinigameWorldWidgetSettings WidgetSettings;
		WidgetSettings.TimeDuration = 0.5f;
		WidgetSettings.FadeDuration = 0.5f;
		WidgetSettings.MinigameTextColor = EMinigameTextColor::Cody;

		MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Cody, "+1", Game::GetMay().ActorLocation, WidgetSettings);

		if(HasControl())
			VerifyScore();
	}

	UFUNCTION(NetFunction)
	void NetAddMayScore(int ScoreToAdd)
	{
		if(!BothPlayersInArea || !GameStarted)
			return;

		if(MinigameComp.ScoreData.MayScore >= MinigameComp.ScoreData.ScoreLimit)
			return;

		MinigameComp.AdjustScore(Game::GetMay(), ScoreToAdd);
		MinigameComp.PlayTauntAllVOBark(Game::May);
		FMinigameWorldWidgetSettings WidgetSettings;
		WidgetSettings.TimeDuration = 0.5f;
		WidgetSettings.FadeDuration = 0.5f;
		WidgetSettings.MinigameTextColor = EMinigameTextColor::May;

		MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::May, "+1", Game::GetCody().ActorLocation, WidgetSettings);

		if(HasControl())
			VerifyScore();
	}

	UFUNCTION()
	void VerifyScore()
	{
		if(MinigameComp.ScoreData.MayScore >= MinigameComp.ScoreData.ScoreLimit || MinigameComp.ScoreData.CodyScore >= MinigameComp.ScoreData.ScoreLimit)
		{
			if(MinigameComp.ScoreData.MayScore >= MinigameComp.ScoreData.ScoreLimit && MinigameComp.ScoreData.CodyScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				AnnounceWinner(EMinigameWinner::Draw);
			}
			else if(MinigameComp.ScoreData.MayScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				AnnounceWinner(EMinigameWinner::May);
			}
			else if(MinigameComp.ScoreData.CodyScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				AnnounceWinner(EMinigameWinner::Cody);
			}
			
			GameStarted = false;
			bAnnouncingWinner = true;
		}
	}

	UFUNCTION(NetFunction)
	void AnnounceWinner(EMinigameWinner Winner)
	{
		switch(Winner)
		{
			case(EMinigameWinner::Draw):
				MinigameComp.AnnounceWinner(EMinigameWinner::Draw);
				break;


			case(EMinigameWinner::May):
				MinigameComp.AnnounceWinner(EMinigameWinner::May);
				System::SetTimer(this, n"DelayedWinnerMayAnimation", 1.6f, false);
				break;


			case(EMinigameWinner::Cody):
				MinigameComp.AnnounceWinner(EMinigameWinner::Cody);
				System::SetTimer(this, n"DelayedWinnerCodyAnimation", 1.6f, false);
				break;

			default:
				MinigameComp.AnnounceWinner(EMinigameWinner::Draw);
				break;
		}
	}

	UFUNCTION()
	void DelayedWinnerMayAnimation()
	{
		if (!Game::May.IsAnyCapabilityActive(n"SnowballFightHitCapability"))
			MinigameComp.ActivateReactionAnimations(Game::May);
	}

	UFUNCTION()
	void DelayedWinnerCodyAnimation()
	{
		if (!Game::Cody.IsAnyCapabilityActive(n"SnowballFightHitCapability"))
			MinigameComp.ActivateReactionAnimations(Game::Cody);
	}

	UFUNCTION(NetFunction)
	void ResetMinigame()
	{
		MinigameComp.ResetScoreBoth();
		RoundCompletedEvent.Broadcast();
		bAnnouncingWinner = false;
	}
}