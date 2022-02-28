import Cake.LevelSpecific.Hopscotch.SideContent.HoopsBall;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsTarget;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsStartInteraction;
import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsBallHoleFill;
import Vino.Pickups.PlayerPickupComponent;
import Vino.MinigameScore.MinigameComp;

struct FHoopsScore
{
	UPROPERTY()
	int CodyScore = 0;

	UPROPERTY()
	int MayScore = 0;
}

class AHoopsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MiniGameComp;
	default MiniGameComp.ScoreData.MinigameName = NSLOCTEXT("Minigames", "ThrowingHoops", "Throwing Hoops");
	default MiniGameComp.MinigameID = FName("Throwing Hoops");
	default MiniGameComp.MinigameTag = EMinigameTag::ThrowingHoops;

	UPROPERTY()
	TArray<AHoopsBall> BallArray;

	UPROPERTY()
	TArray<FVector> BallSpawnLocationArray;

	UPROPERTY()
	AHoopsStartInteraction StartInteraction;

	UPROPERTY()
	TArray<AHoopsTarget> TargetArray;

	UPROPERTY()
	FHoopsScore HoopsScore;

	UPROPERTY()
	float HoopsTimerDuration = 30.f;

	UPROPERTY()
	float HoopsTimer = 0.f; 

	UPROPERTY()
	TArray<AHoopsBallHoleFill> HoleFillArray;

	int SpawnedBallCount = 0;

	bool bShouldTickTimer = false;

	// Delay between start interaction and game start
	UPROPERTY()
	float StartDelayDuration = 2.f;

	float TeleportBallTimerDuration = 2.f;
	float TeleportBallTimer = 0.f;
	bool bShouldTickTeleportBallTimer = false;
	
	float StartDelay = 2.f; 
	bool bShouldTickStartDelay = false;

	bool bPlayerPickupDisabled = false;

	int PlayInterval;

	int MaxPlayInterval = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartInteraction.HoopsInteractedReady.AddUFunction(this, n"HoopsInteractionReady");
		MiniGameComp.OnTimerCompletedEvent.AddUFunction(this, n"TimerCompleted");
		MiniGameComp.OnTutorialCancel.AddUFunction(this, n"OnTutorialCancel");
		MiniGameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialComplete");
		MiniGameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"VictoryScreenComplete");
		MiniGameComp.OnMinigamePlayerLeftEvent.AddUFunction(this, n"PlayerLeftGame");

		for (auto Target : TargetArray)
			Target.HoopScoreEvent.AddUFunction(this, n"PlayerScored");

		bPlayerPickupDisabled = false;
	}

	UFUNCTION(CallInEditor)
	void SetBallArray()
	{
		GetAllActorsOfClass(BallArray);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickStartDelay)
		{
			StartDelay -= DeltaTime;
			if (StartDelay <= 0.f)
			{
				bShouldTickStartDelay = false;
				StartHoopsGame();
			}
		}

		if (bShouldTickTeleportBallTimer && HasControl())
		{
			TeleportBallTimer += DeltaTime;
			if (TeleportBallTimer >= TeleportBallTimerDuration)
			{
				bShouldTickTeleportBallTimer = false;
				NetTeleportBallsToStartingPosition();
			}
		}

		if(bShouldTickTimer && MiniGameComp.GetTimerValue() < 1.3f && !bPlayerPickupDisabled)
		{
			bPlayerPickupDisabled = true;
			for(auto Player : Game::GetPlayers())
				UPlayerPickupComponent::Get(Player).SetAllowPickUp(false);
		}
	}

	UFUNCTION()
	void HoopsInteractionReady()
	{
		MiniGameComp.ActivateTutorial();
		MiniGameComp.ResetScoreBoth();
		StartInteraction.EnableInteraction(false);
	}

	UFUNCTION()
	void StartHoopsGame()
	{
		StartTimer();	
		MiniGameComp.StartTimer();

		for (auto Target : TargetArray)
		{
			Target.StartMovingTarget();	
			Target.CreateWidgets();
		}
	}

	UFUNCTION()
	void PlayerScored(AHazePlayerCharacter Player, int NewScoreToAdd, FVector SpawnLocation)
	{
		if (!bShouldTickTimer && !HasControl())
			return;

		PlayInterval++;

		MiniGameComp.AdjustScore(Player, NewScoreToAdd);

		FMinigameWorldWidgetSettings MinigameText;
		MinigameText.FadeDuration = 1.f;
		MinigameText.MoveSpeed = 1100.f;
		MinigameText.TextJuice = EInGameTextJuice::BigChange;
		MinigameText.MinigameTextMovementType = EMinigameTextMovementType::ConstantToHeight;

		FString Text = FString("+" + String::Conv_IntToString(NewScoreToAdd));

		EMinigameTextPlayerTarget PlayerTarget;

		if (Player.IsMay())
		{
			PlayerTarget = EMinigameTextPlayerTarget::May;
			MinigameText.MinigameTextColor = EMinigameTextColor::May;
		}
		else
		{
			PlayerTarget = EMinigameTextPlayerTarget::Cody;
			MinigameText.MinigameTextColor = EMinigameTextColor::Cody;
		}

		MiniGameComp.CreateMinigameWorldWidgetText(PlayerTarget, Text, SpawnLocation, MinigameText);

		if (PlayInterval == MaxPlayInterval)
		{
			PlayInterval = 0;
			MiniGameComp.PlayTauntAllVOBark(Player);
		}
	}

	UFUNCTION()
	void StartTimer()
	{
		HoopsTimer = HoopsTimerDuration;
		bShouldTickTimer = true;
	}

	UFUNCTION()
	void OnTutorialCancel()
	{
		StartInteraction.EnableInteraction(true);
		StartInteraction.AllowInteractionToComplete(true);
	}

	UFUNCTION()
	void OnTutorialComplete()
	{
		StartInteraction.AllowInteractionToComplete(true);
		StartDelay = StartDelayDuration;
		bShouldTickStartDelay = true;
		BallSpawnLocationArray.Empty();
		
		for (auto Ball : BallArray)
			BallSpawnLocationArray.Add(Ball.GetActorLocation());
			
		for(int i = 0; i < BallArray.Num(); i++)
			BallArray[i].SetBallEnabled(true);

		for(auto Hole : HoleFillArray)
			Hole.SetHoleFillOpen(true);

		MiniGameComp.ShowGameHud();
		MiniGameComp.SetTimer(HoopsTimerDuration);
		MiniGameComp.ScoreData.ShowTimer = true;
		MiniGameComp.ScoreData.Timer = HoopsTimerDuration;
	}

	UFUNCTION(NotBlueprintCallable)
	void TimerCompleted()
	{
		if(HasControl())
			NetEndGame(nullptr);
	}

	UFUNCTION(NetFunction)
	void NetEndGame(AHazePlayerCharacter PlayerLeft)
	{
		bShouldTickTimer = false;
		HoopsTimer = 0.f;
		TeleportBallTimer = 0.f;
		bShouldTickTeleportBallTimer = true;
		StartInteraction.AllowInteractionToComplete(false);

		for(auto Target : TargetArray)
			Target.StopMovingTarget();

		for(auto Player : Game::GetPlayers())
			UPlayerPickupComponent::Get(Player).ForceDrop(false);

		for(auto Ball : BallArray)
		{
			Ball.SetBallEnabled(false);
			Ball.SetActorHiddenInGame(true);
		}

		for(auto Hole : HoleFillArray)
			Hole.SetHoleFillOpen(false);

		if (PlayerLeft == nullptr)
			MiniGameComp.AnnounceWinner();
		else
			MiniGameComp.AnnounceWinner(PlayerLeft.OtherPlayer);

		// Re-enable player pickups
		bPlayerPickupDisabled = false;
		for(auto Player : Game::GetPlayers())
			UPlayerPickupComponent::Get(Player).SetAllowPickUp(true);
	}

	UFUNCTION(NetFunction)
	void NetTeleportBallsToStartingPosition()
	{
		for(int i = 0; i < BallArray.Num(); i++)	
			BallArray[i].TeleportBallsToStartingPosition(BallSpawnLocationArray[i]);
	}

	UFUNCTION()
	void VictoryScreenComplete()
	{
		StartInteraction.EnableInteraction(true);
	}

	UFUNCTION()
	void PlayerLeftGame(AHazePlayerCharacter Player)
	{
		if (HasControl())
			NetEndGame(Player);		
	}
}