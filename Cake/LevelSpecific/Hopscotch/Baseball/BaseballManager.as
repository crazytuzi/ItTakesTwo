import Vino.Interactions.DoubleInteractionActor;
import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.Hopscotch.Baseball.BaseballToyFigurine;
import Vino.MinigameScore.MinigameComp;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureBaseBallToy;

class ABaseballManager : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MiniGameComp;
	default MiniGameComp.ScoreData.MinigameName = NSLOCTEXT("Minigames", "Baseball", "Baseball");
	default MiniGameComp.MinigameID = FName("Baseball");
	default MiniGameComp.MinigameTag = EMinigameTag::Baseball;
	// default MiniGameComp.bPlayWinningAnimations = false;
	// default MiniGameComp.bPlayLosingAnimations = false;
	// default MiniGameComp.bPlayDrawAnimations = false;

	UPROPERTY()
	ULocomotionFeatureBaseBallToy CodyFeature;
	UPROPERTY()
	ULocomotionFeatureBaseBallToy MayFeature;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent CodyBaseballSyncRotation;
	default CodyBaseballSyncRotation.NumberOfSyncsPerSecond = 20;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent MayBaseballSyncRotation;
	default MayBaseballSyncRotation.NumberOfSyncsPerSecond = 20;

	UPROPERTY()
	ABaseballToyFigurine MaysToyFigurine;
	UPROPERTY()
	ABaseballToyFigurine CodysToyFigurine;
	UPROPERTY()
	ABaseballRotatingBall CodysBaseball;
	UPROPERTY()
	ABaseballRotatingBall MaysBaseball;
	UPROPERTY()
	ADoubleInteractionActor DoubleInteraction;
	UPROPERTY()
	TSubclassOf<UHazeCapability> BaseballCapability;
	UPROPERTY()
	AHazeCameraActor CameraActor;
	AHazePlayerCharacter Cody;
	AHazePlayerCharacter May;

	UPROPERTY()
	AActor MayDisplayScoreInWorldLocation;
	UPROPERTY()
	AActor CodyDisplayScoreInWorldLocation;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAssetLevelSpecific;
	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAssetGeneric;

	UPROPERTY()
	UForceFeedbackEffect SuccessForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect FailForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FailCameraShake;

	UPROPERTY()
	float ScoreTimerOriginal;
	float ScoreTimer;
	int MayHighScore = 0;
	int CodyHighScore = 0;
	int MayScore = 0;
	int CodyScore = 0;
	float MiniGameEndingTimer = -1;
	float MiniGameTimer = -1;
	bool bMiniGameActive = false;
	bool bMiniGamePlaying = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cody = Game::GetCody();
		May = Game::GetMay();
		ScoreTimer = ScoreTimerOriginal;
		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"SetUpMiniGame");
		MiniGameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartCountDown");
		MiniGameComp.OnCountDownCompletedEvent.AddUFunction(this, n"ActivateMiniGame");
		MiniGameComp.OnTutorialCancel.AddUFunction(this, n"PlayerCanceledMiniGame");
		MiniGameComp.OnEndMinigameReactionsComplete.AddUFunction(this, n"DeactiveFigurines");
		// MiniGameComp.OnEndMinigameReactionsComplete.AddUFunction(this, n"DeactiveManager");
		//MiniGameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"DeactiveManager");
		//DoubleInteraction.LeftInteraction.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");
		//DoubleInteraction.RightInteraction.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		CodysBaseball.OnBallCodyImpacted.AddUFunction(this, n"OnCodyBallImpact");
		MaysBaseball.OnBallMayImpacted.AddUFunction(this, n"OnMayBallImpact");
	}

	UFUNCTION()
	void PreRefManagerToPlayers()
	{
		May.SetCapabilityAttributeObject(n"BaseballManager", this);
		Cody.SetCapabilityAttributeObject(n"BaseballManager", this);
	}

	UFUNCTION()
	void SetUpMiniGame()
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		CameraActor.ActivateCamera(May, Blend, this, EHazeCameraPriority::Script);
		May.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		Cody.AddCapability(BaseballCapability);
		May.AddCapability(BaseballCapability);
		bMiniGameActive = true;

		DoubleInteraction.DisableActor(this);
		MiniGameComp.ResetScoreBoth();
		MiniGameComp.SetTimer(ScoreTimer);
		System::SetTimer(this, n"ShowTutorial", 0.5f, false);
	}

	UFUNCTION()
	void ShowTutorial()
	{
		MiniGameComp.ActivateTutorial();
	}

	UFUNCTION() 
	void StartCountDown()
	{
		CodysBaseball.bHasBeenImpacted = false;
		CodysBaseball.bCountdownStarted = true;
		CodysBaseball.bMiniGameFinished = false;

		MaysBaseball.bHasBeenImpacted = false;
		MaysBaseball.bCountdownStarted = true;
		MaysBaseball.bMiniGameFinished = false;

		MaysToyFigurine.Activate();
		CodysToyFigurine.Activate();
		MiniGameComp.StartCountDown();
	}
	UFUNCTION()
	void ActivateMiniGame()
	{
		//MiniGameComp.StartTimer();
		MiniGameComp.OnTimerCompletedEvent.AddUFunction(this, n"StartFinishMiniGame");
		bMiniGamePlaying = true;
		CodysToyFigurine.FigurineHazeAkComp.HazePostEvent(CodysToyFigurine.PlaySwingRetractLoopAudioEvent);
		MaysToyFigurine.FigurineHazeAkComp.HazePostEvent(MaysToyFigurine.PlaySwingRetractLoopAudioEvent);
		CodysBaseball.BallHazeAkComp.HazePostEvent(CodysBaseball.PlayRotatingBallAudioEvent);
		MaysBaseball.BallHazeAkComp.HazePostEvent(MaysBaseball.PlayRotatingBallAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// PrintToScreen("AAAAAA" + Game::GetCody().GetActorLocation());
	//	PrintToScreen("BBBBBB " +  Game::GetCody().MovementComponent.IsAirborne());
	//	if(!bMiniGamePlaying)
	//		return;
	}

	UFUNCTION()
	void OnMayBallImpact(bool Front)
	{
		if(Game::GetMay().HasControl())
		{
			NetOnMayBallImpact(Front);
		}
	}
	UFUNCTION(NetFunction)
	void NetOnMayBallImpact(bool Front)
	{
		if(!bMiniGamePlaying)
			return;
		if(Front)
		{
			MayScore ++;
			MiniGameComp.SetScore(Game::GetMay(), MayScore);

			if(MayHighScore <= MayScore)
			{
				MayHighScore = MayScore;
			}

			FMinigameWorldWidgetSettings MinigameWorldSettingsMay;
			MinigameWorldSettingsMay.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
			MinigameWorldSettingsMay.TextJuice = EInGameTextJuice::BigChange;
			MinigameWorldSettingsMay.MoveSpeed = 30.f;
			MinigameWorldSettingsMay.TimeDuration = 0.5f;
			MinigameWorldSettingsMay.FadeDuration = 0.6f;
			MinigameWorldSettingsMay.TargetHeight = 140.f;
			MinigameWorldSettingsMay.MinigameTextColor = EMinigameTextColor::May;
			FString ScoreStringMay;
			ScoreStringMay = n"+1";
			MiniGameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, ScoreStringMay, MayDisplayScoreInWorldLocation.GetActorLocation(), MinigameWorldSettingsMay);

			if(HasControl())
			{
				if(MayScore > CodyScore)
				{
					NetPlayTauntVOLine(May, true);
				}
				else if(MayScore <= CodyScore)
				{
					NetPlayTauntVOLine(May, false);
				}
			}

			PlayForceFeedback(May, false);
		}
		else
		{
			PlayFailVO(May);
			PlayForceFeedback(May, true);
		}
	}

	UFUNCTION()
	void OnCodyBallImpact(bool Front)
	{
		if(Game::GetCody().HasControl())
		{
			NetOnCodyBallImpact(Front);
		}
	}
	UFUNCTION(NetFunction)
	void NetOnCodyBallImpact(bool Front)
	{
		if(!bMiniGamePlaying)
			return;
		if(Front)
		{
			CodyScore ++;
			MiniGameComp.SetScore(Game::GetCody(), CodyScore);

			if(CodyHighScore <= CodyScore)
			{
				CodyHighScore = CodyScore;
			}

			FMinigameWorldWidgetSettings MinigameWorldSettingsCody;
			MinigameWorldSettingsCody.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
			MinigameWorldSettingsCody.TextJuice = EInGameTextJuice::BigChange;
			MinigameWorldSettingsCody.MoveSpeed = 30.f;
			MinigameWorldSettingsCody.TimeDuration = 0.5f;
			MinigameWorldSettingsCody.FadeDuration = 0.6f;
			MinigameWorldSettingsCody.TargetHeight = 140.f;
			MinigameWorldSettingsCody.MinigameTextColor = EMinigameTextColor::Cody;
			FString ScoreStringCody;
			ScoreStringCody = n"+1";
			MiniGameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, ScoreStringCody, CodyDisplayScoreInWorldLocation.GetActorLocation(), MinigameWorldSettingsCody);

			if(HasControl())
			{
				if(CodyScore > MayScore)
				{
					NetPlayTauntVOLine(Cody, true);
				}
				else if(CodyScore <= MayScore)
				{
					NetPlayTauntVOLine(Cody, false);
				}
			}

			PlayForceFeedback(Cody, false);
		}
		else
		{
			PlayFailVO(Cody);
			PlayForceFeedback(Cody, true);
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayTauntVOLine(AHazePlayerCharacter PlayerTaunting, bool SpecialTaunt)
	{
		if(PlayerTaunting == Cody)
		{
			if(SpecialTaunt == true)
			{
				//Print("Cody special Taunt", 3.f);
				MiniGameComp.PlayTauntAllVOBark(Cody);
			}
			else
			{
				//Print("Cody Taunt", 3.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
				FName EventName = n"FoghornDBGameplayGlobalMinigameGenericTauntCody";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
		}
		else if(PlayerTaunting == May)
		{
			if(SpecialTaunt == true)
			{
				//Print("May special Taunt", 3.f);
				MiniGameComp.PlayTauntAllVOBark(May);
			}
			else
			{
				//Print("May Taunt", 3.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
				FName EventName = n"FoghornDBGameplayGlobalMinigameGenericTauntMay";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
		}
	}
	UFUNCTION()
	void PlayFailVO(AHazePlayerCharacter PlayerFailing)
	{
		if(PlayerFailing == Cody)
		{
			//Print("Cody Fail", 3.f);
			UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
			FName EventName = n"FoghornDBGameplayGlobalMinigameGenericFailCody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
		else if(PlayerFailing == May)
		{
			//Print("May Fail", 3.f);
			UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
			FName EventName = n"FoghornDBGameplayGlobalMinigameGenericFailMay";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
	}

	UFUNCTION()
	void StartFinishMiniGame()
	{
		if(this.HasControl())
		{
			NetStartFinishMiniGame();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartFinishMiniGame()
	{
		Cody.RemoveCapability(BaseballCapability);
		May.RemoveCapability(BaseballCapability);

		MaysToyFigurine.RetractSwing();
		CodysToyFigurine.RetractSwing();
		CodysBaseball.bCountdownStarted = false;
		CodysBaseball.bMiniGameFinished = true;
		CodysBaseball.bAcceleratedFloatSet = false;
		MaysBaseball.bCountdownStarted = false;
		MaysBaseball.bMiniGameFinished = true;
		MaysBaseball.bAcceleratedFloatSet = false;
		MaysToyFigurine.bPlayerTryingToSwing = false;
		CodysToyFigurine.bPlayerTryingToSwing = false;

		// System::SetTimer(this, n"DelayMinigameWinnerAnnouncement", 0.75f, false);
		MiniGameComp.AnnounceWinner();
		DeactiveManager();

		bMiniGamePlaying = false;
		CodysToyFigurine.FigurineHazeAkComp.HazePostEvent(CodysToyFigurine.StopSwingRetractLoopsAudioEvent);
	}

	// UFUNCTION()
	// void DelayMinigameWinnerAnnouncement()
	// {
	// }

	UFUNCTION(NetFunction)
	void FinishedMiniGameCountdownOver()
	{

	}

	UFUNCTION()
	void PlayerCanceledMiniGame()
	{
		MiniGameComp.EndGameHud();
		DeactiveManager();
		DeactiveFigurines();
	}

	UFUNCTION()
	void DeactiveManager()
	{
		bMiniGameActive = false;
		ScoreTimer = ScoreTimerOriginal;

		CodyScore = 0;
		MayScore = 0;
		CodysBaseball.BallHazeAkComp.HazePostEvent(CodysBaseball.StopRotatingBallLoopsAudioEvent);

		CameraActor.DeactivateCamera(May);
		May.ClearViewSizeOverride(this);
	}
	UFUNCTION()
	void DeactiveFigurines()
	{
		DoubleInteraction.EnableActor(this);
		MaysToyFigurine.Deactivate();
		CodysToyFigurine.Deactivate();
		MiniGameComp.ResetScoreBoth();
	}

	void PlayForceFeedback(AHazePlayerCharacter Player, bool bFail)
	{
		UForceFeedbackEffect Effect = SuccessForceFeedback;
		if (bFail)
		{
			Effect = FailForceFeedback;
			for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
				CurPlayer.PlayCameraShake(FailCameraShake, 2.f);
		}

		Player.PlayForceFeedback(Effect, false, true, n"BaseballHit");
	}
}
