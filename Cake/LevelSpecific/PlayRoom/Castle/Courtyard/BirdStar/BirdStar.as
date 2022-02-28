import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.MovementSettings;
import Vino.Movement.MovementSystemTags;
import Vino.MinigameScore.ScoreHud;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Music.NightClub.RhythmActor;
import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.BirdStar.BirdStarBirdComponent;
import Vino.MinigameScore.MinigameComp;

class ABirdStarManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;
	
	// UPROPERTY(Category = "Setup")
	// TSubclassOf<UScoreHud> ScoreHudClass;

	UPROPERTY()
	AHazeCameraActor FullscreenCam;

	UPROPERTY()
	UAnimSequence DefaultCodyBirdAnim;

	UPROPERTY()
	UAnimSequence DefaultMayBirdAnim;

	UPROPERTY()
	UAnimSequence BirdWinDance;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::BirdStar;

	UPROPERTY()
	UHazeCapabilitySheet BirdStarSheet;

	UPROPERTY()
	ARhythmActor MayRhythmActor;

	UPROPERTY()
	ARhythmActor CodyRhythmActor;

	UPROPERTY()
	ASceneCapture2D SceneCapture;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY()
	AStaticMeshActor TVMesh;

	UPROPERTY()
	UMaterial DefaultScreen;

	UPROPERTY()
	UMaterial GameScreen;

	UPROPERTY()
	UMaterial AntWarScreen;

	UPROPERTY()
	AHazeSkeletalMeshActor MayBird;

	UPROPERTY()
	AHazeSkeletalMeshActor CodyBird;

	UPROPERTY()
	AHazeActor MayInteractBird;

	UPROPERTY()
	AHazeActor CodyInteractBird;

	EMinigameWinner GameWinner;
	
	bool BirdStarActive = false;

	int MayFinalNetworkScore;

	int CodyFinalNetworkScore;

	bool CodyScoreReceived;

	bool MayScoreReceived;

	int AmountOfTimesFunctionRun = 0;

	bool GameOver = false;
	
	bool AllowTaunt = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MayRhythmActor.SetControlSide(Game::GetMay());
		CodyRhythmActor.SetControlSide(Game::GetCody());

		MayRhythmActor.OnTempoSpawned.AddUFunction(this, n"Handle_OnTempoSpawned");
		CodyRhythmActor.OnTempoSpawned.AddUFunction(this, n"Handle_OnTempoSpawned");
	}

	UFUNCTION()
	void RemoveMayScore(float ScoreToRemove, FVector Location)
	{
		if (!GameOver && MinigameComp.GetMayScore() > 0)
		{
			MinigameComp.AdjustScore(Game::GetMay(), -ScoreToRemove, false);
			FMinigameWorldWidgetSettings WidgetSettingsMay;
			WidgetSettingsMay.MinigameTextColor = EMinigameTextColor::Attention;
			WidgetSettingsMay.MoveSpeed = 2.f;
			WidgetSettingsMay.TimeDuration = 0.5f;
			WidgetSettingsMay.TargetHeight = 100.f;
			WidgetSettingsMay.FadeDuration = 0.1f;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "-1", Location, WidgetSettingsMay);
		}
	}

	UFUNCTION()
	void RemoveCodyScore(float ScoreToRemove, FVector Location)
	{
		if (!GameOver && MinigameComp.GetCodyScore() > 0)
		{
			MinigameComp.AdjustScore(Game::GetCody(), -ScoreToRemove, false);
			FMinigameWorldWidgetSettings WidgetSettings;
			WidgetSettings.MinigameTextColor = EMinigameTextColor::Attention;
			WidgetSettings.MoveSpeed = 2.f;
			WidgetSettings.TimeDuration = 0.5f;
			WidgetSettings.TargetHeight = 100.f;
			WidgetSettings.FadeDuration = 0.1f;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "-1", Location, WidgetSettings);
		}
	}

	UFUNCTION()
	void BothPlayersAreReady()
	{
		
	}

	UFUNCTION()
	void ActivateBirdStar()
	{
		//Double interaction
		DoubleInteract.Disable(n"BothPlayersInteracted");

		Game::GetCody().BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetCody().BlockCapabilities(MovementSystemTags::Jump, this);
		Game::GetCody().BlockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetCody().BlockCapabilities(MovementSystemTags::Dash, this);
		Game::GetCody().BlockCapabilities(CapabilityTags::StickInput, this);
		Game::GetCody().BlockCapabilities(MovementSystemTags::SlopeSlide, this);

		Game::GetMay().BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetMay().BlockCapabilities(MovementSystemTags::Jump, this);
		Game::GetMay().BlockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetMay().BlockCapabilities(MovementSystemTags::Dash, this);
		Game::GetMay().BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Game::GetMay().BlockCapabilities(CapabilityTags::StickInput, this);

		UPlayerRhythmComponent::Get(Game::GetCody()).bRhythmActive = true;
		UPlayerRhythmComponent::Get(Game::GetCody()).RhythmDanceArea = CodyRhythmActor;

		UPlayerRhythmComponent::Get(Game::GetMay()).bRhythmActive = true;
		UPlayerRhythmComponent::Get(Game::GetMay()).RhythmDanceArea = MayRhythmActor;

		CodyRhythmActor.CurrentDancer = CodyRhythmActor.LastDancer = Game::GetCody();
		MayRhythmActor.CurrentDancer = MayRhythmActor.LastDancer = Game::GetMay();

		//Turn on scene capture every frame
		USceneCaptureComponent2D::Get(SceneCapture).bCaptureEveryFrame = true;
	
		//Refresh MH in bird
		CodyInteractBird.SetAnimBoolParam(n"bRefreshMH", true);
		MayInteractBird.SetAnimBoolParam(n"bRefreshMH", true);

		// Camera
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		FullscreenCam.ActivateCamera(Game::GetCody(), Blend, this, EHazeCameraPriority::Script);
		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);

		//Start TV screen
		TVMesh.StaticMeshComponent.SetMaterial(1, GameScreen);

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"TurnOnWidgetsAndCountdown");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelFromTutorial");
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownFinished");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"OnWinnerScreenFinished");
		MinigameComp.ActivateTutorial();
	}

	UFUNCTION()
	void CancelFromTutorial()
	{
		Game::GetCody().UnblockCapabilities(CapabilityTags::StickInput, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Dash, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		
		Game::GetMay().UnblockCapabilities(CapabilityTags::StickInput, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Dash, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::SlopeSlide, this);

		Game::GetCody().DeactivateCameraByInstigator(this);
		Game::GetCody().ClearViewSizeOverride(this);

		CodyBird.StopAllSlotAnimations();
		MayBird.StopAllSlotAnimations();

		MayBird.PlaySlotAnimation(Animation = DefaultMayBirdAnim, bLoop = true);
		CodyBird.PlaySlotAnimation(Animation = DefaultCodyBirdAnim, bLoop = true);

		DoubleInteract.Enable(n"BothPlayersInteracted");
		TVMesh.StaticMeshComponent.SetMaterial(1, AntWarScreen);

		UPlayerRhythmComponent::Get(Game::GetCody()).bRhythmActive = false;
		UPlayerRhythmComponent::Get(Game::GetMay()).bRhythmActive = false;

		//Turn off scene capture every frame
		USceneCaptureComponent2D::Get(SceneCapture).bCaptureEveryFrame = false;
		BirdStarActive = false;
	}

	UFUNCTION()
	void TurnOnWidgetsAndCountdown()
	{
		MinigameComp.StartCountDown();
		CodyRhythmActor.StartRhythm();
		CodyRhythmActor.CurrentDancer = CodyRhythmActor.LastDancer = Game::GetCody();
		MayRhythmActor.StartRhythm();
		MayRhythmActor.CurrentDancer = MayRhythmActor.LastDancer = Game::GetMay();
	}

	UFUNCTION()
	void CountdownFinished()
	{
		BirdStarActive = true;
		BP_SpawnNotes();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_OnTempoSpawned(ARhythmTempoActor NewTempoActor)
	{
		SceneCapture.CaptureComponent2D.ShowOnlyActors.Add(NewTempoActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
			//Check if player won
	
			if (BirdStarActive && MinigameComp.GetTimerValue() <= 0.f)
			{
				if (HasControl())
				{
					NetGameOver();
				}
				// if (Network::IsNetworked())
				// {
				// 	if(Game::Cody.HasControl())
				// 	{
				// 		NetGameOver();
				// 	}
				// }
				// else
				// {
				// 	GameWinner = EMinigameWinner::Cody;
				// 	WinnerHasBeenDecided(GameWinner);
				// }
			}
	}


	UFUNCTION()
	void AddCodyScore(float ScoreToAdd, FVector Location)
	{
		if (!GameOver)
		{
			MinigameComp.AdjustScore(Game::GetCody(), ScoreToAdd, false);
			FMinigameWorldWidgetSettings WidgetSettings;
			WidgetSettings.MinigameTextColor = EMinigameTextColor::Cody;
			WidgetSettings.MoveSpeed = 2.f;
			WidgetSettings.TimeDuration = 0.5f;
			WidgetSettings.TargetHeight = 100.f;
			WidgetSettings.FadeDuration = 0.1f;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+1", Location, WidgetSettings);
			TryToPlayTaunt(Game::GetCody());
		}
	}

	UFUNCTION()
	void AddMayScore(float ScoreToAdd, FVector Location)
	{
		if (!GameOver)
		{
			MinigameComp.AdjustScore(Game::GetMay(), ScoreToAdd, false);
			FMinigameWorldWidgetSettings WidgetSettingsMay;
			WidgetSettingsMay.MinigameTextColor = EMinigameTextColor::May;
			WidgetSettingsMay.MoveSpeed = 2.f;
			WidgetSettingsMay.TimeDuration = 0.5f;
			WidgetSettingsMay.TargetHeight = 100.f;
			WidgetSettingsMay.FadeDuration = 0.1f;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+1", Location, WidgetSettingsMay);
			TryToPlayTaunt(Game::GetMay());
		}
	}

	UFUNCTION()
	void TryToPlayTaunt(AHazePlayerCharacter Player)
	{
		if(AllowTaunt)
		{
			AllowTaunt = false;
			MinigameComp.PlayTauntUniqueVOBark(Player);
			System::SetTimer(this, n"ResetAllowTauntBool", 2.5f, false);
		}
	}

	UFUNCTION()
	void ResetAllowTauntBool()
	{
		AllowTaunt = true;
	}

	UFUNCTION(NetFunction)
	void NetGameOver()
	{
		if (GameOver)
		{
			return;
		}
		
		GameOver = true;

		if (Game::GetCody().HasControl())
			NetDecideWinner(Game::Cody, MinigameComp.ScoreData.CodyScore);

		if (Game::GetMay().HasControl())
			NetDecideWinner(Game::May, MinigameComp.ScoreData.MayScore);
	}

	UFUNCTION(NetFunction)
	void NetDecideWinner(AHazePlayerCharacter Player, int Score)
	{
		if (Player == Game::GetMay())
		{
			MayFinalNetworkScore = Score;
			MayScoreReceived = true;
		}
		
		if (Player == Game::GetCody())
		{
			CodyFinalNetworkScore = Score;
			CodyScoreReceived = true;
		}

		if (MayScoreReceived && CodyScoreReceived)
		{
			MinigameComp.ScoreData.MayScore = MayFinalNetworkScore;
			MinigameComp.ScoreData.CodyScore = CodyFinalNetworkScore;

			MinigameComp.SetScore(Game::GetCody(), MinigameComp.ScoreData.CodyScore);
			MinigameComp.SetScore(Game::GetMay(), MinigameComp.ScoreData.MayScore);

			if (CodyFinalNetworkScore == MayFinalNetworkScore)
			{
				GameWinner = EMinigameWinner::Draw;
				WinnerHasBeenDecided(GameWinner);
				return;
			}

			if (CodyFinalNetworkScore > MayFinalNetworkScore)
				GameWinner = EMinigameWinner::Cody;
			else
				GameWinner = EMinigameWinner::May;

			WinnerHasBeenDecided(GameWinner);
		}
	}

	UFUNCTION()
	void WinnerHasBeenDecided(EMinigameWinner MiniGameWinner)
	{
		AHazePlayerCharacter WinningPlayer = nullptr;
		AHazePlayerCharacter LosingPlayer = nullptr;

		switch(MiniGameWinner)
		{
			case EMinigameWinner::Cody:
				WinningPlayer = Game::GetCody();
				LosingPlayer = WinningPlayer.OtherPlayer;
				CodyBird.PlaySlotAnimation(Animation = BirdWinDance, bLoop = true);
				break;

			case EMinigameWinner::Draw:
				break;

			case EMinigameWinner::May:
				WinningPlayer = Game::GetMay();
				LosingPlayer = WinningPlayer.OtherPlayer;
				MayBird.PlaySlotAnimation(Animation = BirdWinDance, bLoop = true);
				break;
		}

		UBirdStarBirdComponent::Get(MayInteractBird).bPlayerExit = true;
		UBirdStarBirdComponent::Get(CodyInteractBird).bPlayerExit = true;
		
		System::SetTimer(this, n"ResetExitBool", 0.2f, false, 0.f, 0.f);
		
		BirdStarActive = false;

		
		//To remove the dancing animations when in rhythm sphere
		UPlayerRhythmComponent::Get(Game::GetCody()).bRhythmActive = false;
		UPlayerRhythmComponent::Get(Game::GetMay()).bRhythmActive = false;

		//Clear sing star board on TV
		MayRhythmActor.StopRhythm();
		CodyRhythmActor.StopRhythm();

		MinigameComp.AnnounceWinner(MiniGameWinner);
	

		// WinningPlayer.PlaySlotAnimation(Animation = WinningAnimation);
		// LosingPlayer.PlaySlotAnimation(Animation = LosingAnimation);

		AmountOfTimesFunctionRun = 0;
		CodyFinalNetworkScore = 0.f;
		MayFinalNetworkScore = 0.f;
		MayScoreReceived = false;
		CodyScoreReceived = false;
		GameOver = false;
	}
		
	UFUNCTION()
	void ResetExitBool()		
	{
		UBirdStarBirdComponent::Get(MayInteractBird).bPlayerExit = false;
		UBirdStarBirdComponent::Get(CodyInteractBird).bPlayerExit = false;
	}

	UFUNCTION()
	void OnWinnerScreenFinished()
	{
		// MinigameComp.EndGameHud();

		//Unblock capabilities for cody
		Game::GetCody().UnblockCapabilities(CapabilityTags::StickInput, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::Dash, this);
		Game::GetCody().UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		
		//Unblock capabilities for may
		Game::GetMay().UnblockCapabilities(CapabilityTags::StickInput, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Jump, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Crouch, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::Dash, this);
		Game::GetMay().UnblockCapabilities(MovementSystemTags::SlopeSlide, this);

		Game::GetCody().DeactivateCameraByInstigator(this);
		Game::GetCody().ClearViewSizeOverride(this);

		CodyBird.StopAllSlotAnimations();
		MayBird.StopAllSlotAnimations();

		MayBird.PlaySlotAnimation(Animation = DefaultMayBirdAnim, bLoop = true);
		CodyBird.PlaySlotAnimation(Animation = DefaultCodyBirdAnim, bLoop = true);

	
		TVMesh.StaticMeshComponent.SetMaterial(1, AntWarScreen);

		//Turn off scene capture every frame
		USceneCaptureComponent2D::Get(SceneCapture).bCaptureEveryFrame = false;
		MinigameComp.ResetScoreBoth();
		System::SetTimer(this, n"EnableDoubleInteract", 3.f, false);
	}

	UFUNCTION()
	void EnableDoubleInteract()
	{
		DoubleInteract.Enable(n"BothPlayersInteracted");
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnNotes(){}
} 