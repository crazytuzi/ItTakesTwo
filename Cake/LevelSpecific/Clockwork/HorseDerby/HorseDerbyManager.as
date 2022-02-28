import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyObstacleManagerComponent;
import Vino.MinigameScore.ScoreHud;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyObstacleDoors;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyScrollingBackgroundSplineActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyScrollManager;
import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkDerbySpectator;

event void FOnDerbyStartedSignature();

AHorseDerbyManager GetHorseDerbyManager()
{
	TArray<AHorseDerbyManager> HorseDerbyArray;
	GetAllActorsOfClass(HorseDerbyArray);

	return HorseDerbyArray[0];
}

class AHorseDerbyManager : ADoubleInteractionActor
{
	default LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
	default RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
	default bPreventInteractionFromCompleting = true;
	default bPlayExitAnimationOnCompleted = false;
	default bTurnOffTickWhenNotWaiting = false;

	UPROPERTY(Category = "Settings")
	float GameActiveHorseSpeed = 125.f;

	UPROPERTY(Category = "Settings")
	float GameInactiveHorseSpeed = 450.f;

	UPROPERTY(Category = "Settings")
	float CloseBackgroundSpeed = 250.f;

	UPROPERTY(Category = "Settings")
	float FarBackgroundSpeed = 150.f;

	UPROPERTY(Category = "Settings")
	float CrouchSpeedMultiplier = 0.2f;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera GameActiveCamera;
	
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	float FOVActiveCamera = 25.f;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera ReadyActiveCamera;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TPerPlayer<ADerbyHorseSplineTrack> PlayerTracks;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHorseDerbyObstacleManagerComponent ObstacleComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 8500.f;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TPerPlayer<ADerbyHorseActor> DerbyHorses;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet DerbyHorseCapabilitySheet;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerHorseDerbySheet;

	UPROPERTY(Category = "Setup")
	TArray<AHorseDerbyObstacleDoors> ObstacleDoors;

	UPROPERTY(Category = "Setup")
	AStaticMeshActor Wheel1;

	UPROPERTY(Category = "Setup")
	AStaticMeshActor Wheel2;

	int MaxSequenceCount = 20;

	TPerPlayer<int> CurrentSequenceCount;

	UPROPERTY(Category = "Setup")
	TArray<int> ObstacleSpawnSequence;

	UPROPERTY()
	TArray<AHorseDerbyScrollManager> HorseDerbyScrollManagers;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::HorseDerby;
	
	///Audio
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompMachinery;

	//Triggered when game starts
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMachineryLoopEvent;

	//Triggers when game won/aborted
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMachineryLoopEvent;

	//Triggers when Game won/aborted
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartResetLoopEvent;

	//Triggers when players are in default/start positions.
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopResetLoopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerReachedStartLineEvent;

	AHazePlayerCharacter MayRef;
	AHazePlayerCharacter CodyRef;

	AHazePlayerCharacter HostPlayer;

	AHazePlayerCharacter PendingWinner;
	float AnnounceWinnerCountdown;
	
	FOnDerbyStartedSignature StartedEvent;
	EDerbyHorseState Gamestate = EDerbyHorseState::AwaitingStart;

	UPROPERTY(Category = "Settings")
	float ObstacleFrequency = 5.f;

	TPerPlayer<int> HitByObstacles;
	TPerPlayer<bool> bPlayerFinished;
	TPerPlayer<float> PlayerProgress;

	int MaxSequentialObjects = 2;

	//These can be put in struct
	float MayTimer = 0.f;
	float MayDifficultyModifier = 0.f;

	float CodyTimer = 0.f;
	float CodyDifficultyModifier = 0.f;

	float MaxCatchupDistance = 200.f;
	float LeaderProgress = 0.f;

	bool bDoorsOpen = false;
	bool AllObstaclesDisabled = false;
	bool bCalledWinner;
	bool bHaveReachedPos;

	float VOTimer;
	float RMin = 6.f;
	float RMax = 8.f;

	bool bPlayMayTauntVO;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto EditorBillboard = UBillboardComponent::Create(this);
		EditorBillboard.bIsEditorOnly = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		LeftInteraction.AttachToComponent(DerbyHorses[0].AttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		RightInteraction.AttachToComponent(DerbyHorses[1].AttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		
		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnPlayerCancelled");

		LeftInteraction.OnActivated.AddUFunction(this, n"OnHorseInteracted");
		RightInteraction.OnActivated.AddUFunction(this, n"OnHorseInteracted");

		ObstacleComp.Initialize();
		ObstacleComp.CloseDoorsEvent.AddUFunction(this, n"AllObstaclesCleared");

		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelForBothPlayers");
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialAccepted");

		if (HasControl())
			MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"NetCheckStartGame");	

		DerbyHorses[0].SetCapabilityAttributeObject(n"Manager", this);
		DerbyHorses[0].AddCapabilitySheet(DerbyHorseCapabilitySheet);
		DerbyHorses[1].SetCapabilityAttributeObject(n"Manager", this);
		DerbyHorses[1].AddCapabilitySheet(DerbyHorseCapabilitySheet);
		DerbyHorses[0].OnHorseDerbyMidGameExit.AddUFunction(this, n"CancelComplete");
		DerbyHorses[1].OnHorseDerbyMidGameExit.AddUFunction(this, n"CancelComplete");

		AddCapability(n"HorseDerbyManagerWheelTurnCapability");

		PopulateObstacleSequenceLists();

		SetActorTickEnabled(true);

		if (HasControl())
			VOTimer = FMath::RandRange(RMin, RMax); 

		if (Game::May.HasControl())
			HostPlayer = Game::May;
		else
			HostPlayer = Game::Cody;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if(Gamestate == EDerbyHorseState::GameActive)
		{
			HandleTimers(DeltaTime);
			CheckProgress();
			ScrollBackgrounds(DeltaTime);
			RaceVO(DeltaTime);

			if (HasControl())
			{
				if (AnnounceWinnerCountdown > 0.f)
				{
					AnnounceWinnerCountdown -= DeltaTime;

					if (AnnounceWinnerCountdown <= 0.f)
						NetFinishGame(PendingWinner);
				}
			}
		}
	}

	void RaceVO(float DeltaTime)
	{
		if (!HasControl())
			return;
		
		VOTimer -= DeltaTime;

		if (VOTimer <= 0.f)
		{
			VOTimer = FMath::RandRange(RMin, RMax); 

			if (bPlayMayTauntVO)
			{
				NetPlayRaceVOBark(Game::May);
				bPlayMayTauntVO = false;
			}
			else if (!bPlayMayTauntVO)
			{
				NetPlayRaceVOBark(Game::Cody);
				bPlayMayTauntVO = true;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayRaceVOBark(AHazePlayerCharacter Player)
	{
		MinigameComp.PlayTauntAllVOBark(Player);
	}

	UFUNCTION()
	void OnHorseInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"DerbyHorseActor", DerbyHorses[Player]);
		Player.AddCapabilitySheet(PlayerHorseDerbySheet);

		DerbyHorses[Player].Collided = false;
		DerbyHorses[Player].HorseInteracted(Player);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		ReadyActiveCamera.ActivateCamera(Player, Blend);

		if (Player.IsMay())
			MayRef = Player;
		else
			CodyRef = Player;

		if (MayRef != nullptr && CodyRef != nullptr)
			bPreventInteractionFromCompleting = true;
	}

	void OnInteractingWithMayHorse(AHazePlayerCharacter Player)
	{
		DerbyHorses[0].HorseInteracted(Player);
	}

	UFUNCTION()
	void OnInteractingWithCodyHorse(AHazePlayerCharacter Player)
	{
		DerbyHorses[1].HorseInteracted(Player);
	}

	UFUNCTION()
	void OnPlayerCancelled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		Player.ClearViewSizeOverride(this);
		GameActiveCamera.DeactivateCamera(Player);
		Player.ClearCameraSettingsByInstigator(this, 3.5f);
		Player.ClearFieldOfViewByInstigator(this, 3.5f);
		Player.SetCapabilityActionState(n"HorseDerby", EHazeActionState::Inactive);
		Player.RemoveCapabilitySheet(PlayerHorseDerbySheet);
		
		if(Gamestate == EDerbyHorseState::GameActive)
		{
			Player.OtherPlayer.ClearViewSizeOverride(this);
			GameActiveCamera.DeactivateCamera(Player.OtherPlayer);
			Player.OtherPlayer.ClearCameraSettingsByInstigator(this, 3.5f);
			Player.OtherPlayer.ClearFieldOfViewByInstigator(this, 3.5f);
			StopGame();
		}
		else
		{
			if (Player.IsMay())
			{
				FHazeJumpToData JumpDataMay;
				JumpDataMay.TargetComponent = DerbyHorses[Player].JumpToLocation;
				JumpTo::ActivateJumpTo(Game::May, JumpDataMay);
				
				LeftInteraction.EnableAfterFullSyncPoint(n"Horse Interacting");
				DerbyHorses[Player].InteractionDisabled(Player);
				MayRef = nullptr;
			}
			else
			{
				FHazeJumpToData JumpDataCody;
				JumpDataCody.TargetComponent = DerbyHorses[Player].JumpToLocation;
				JumpTo::ActivateJumpTo(Game::Cody, JumpDataCody);

				RightInteraction.EnableAfterFullSyncPoint(n"Horse Interacting");
				DerbyHorses[Player].InteractionDisabled(Player);
				CodyRef = nullptr;
			}

			ReadyActiveCamera.DeactivateCamera(Player);
		}
	}

	UFUNCTION()
	void CancelForBothPlayers()
	{	
		bPreventInteractionFromCompleting = false;
		
		DerbyHorses[0].bCanCancelMidGame = false;
		DerbyHorses[1].bCanCancelMidGame = false;

		OnPlayerCancelled(Game::May, LeftInteraction, true);
		OnPlayerCancelled(Game::Cody, RightInteraction, false);

		CloseObstacleDoors();
	}

	void HandleTimers(float DeltaTime)
	{
		CodyTimer += (DeltaTime * CodyDifficultyModifier);

		if(CodyTimer >= ObstacleFrequency)
		{
			ChooseObstacle(Game::Cody);
			CodyTimer -= ObstacleFrequency;
		}

		MayTimer += (DeltaTime * MayDifficultyModifier);

		if(MayTimer >= ObstacleFrequency)
		{
			ChooseObstacle(Game::May);
			MayTimer -= ObstacleFrequency;
		}
	}

	void CheckProgress()
	{
		PlayerProgress[0] = 0.f;
		PlayerProgress[1] = 0.f;
		
		PlayerProgress[0] = DerbyHorses[0].HorseComponent.CurrentProgress;
		SetDifficulty(true, PlayerProgress[0]);

		PlayerProgress[1] = DerbyHorses[1].HorseComponent.CurrentProgress;
		SetDifficulty(false, PlayerProgress[1]);

		//Set Catchup Speed
		float DeltaDistance = 0.f;
		DerbyHorses[0].HorseComponent.SpeedMultiplier = 1.f;
		DerbyHorses[1].HorseComponent.SpeedMultiplier = 1.f;

		if(PlayerProgress[0] > PlayerProgress[1])
		{
			DeltaDistance =  PlayerProgress[0] - PlayerProgress[1];
			if(DeltaDistance > MaxCatchupDistance)
			{
				DeltaDistance = MaxCatchupDistance;
				DerbyHorses[1].HorseComponent.SpeedMultiplier = DerbyHorses[1].HorseComponent.MaxSpeedMultiplier;
			}
			else
			{
				float DistancePercentage = MaxCatchupDistance / 100.f;
				float CurrentSpeedPercentage = DeltaDistance / DistancePercentage;
				DerbyHorses[1].HorseComponent.SpeedMultiplier = (1.f + (DerbyHorses[1].HorseComponent.SpeedMultiPercentage * CurrentSpeedPercentage));
			}

			LeaderProgress = PlayerProgress[0];
		}
		else if(PlayerProgress[1] > PlayerProgress[0])
		{
			DeltaDistance =  PlayerProgress[1] - PlayerProgress[0];
			if(DeltaDistance > MaxCatchupDistance)
			{
				DeltaDistance = MaxCatchupDistance;
				DerbyHorses[0].HorseComponent.SpeedMultiplier = DerbyHorses[0].HorseComponent.MaxSpeedMultiplier;
			}
			else
			{
				float DistancePercentage = MaxCatchupDistance / 100.f;
				float CurrentSpeedPercentage = DeltaDistance / DistancePercentage;
				DerbyHorses[0].HorseComponent.SpeedMultiplier = (1.f + (DerbyHorses[0].HorseComponent.SpeedMultiPercentage * CurrentSpeedPercentage));
			}

			LeaderProgress = PlayerProgress[1];
		}

		if (Gamestate == EDerbyHorseState::GameActive && !bPlayerFinished[HostPlayer])
		{
			if (Game::Cody.HasControl())
			{
				if (PlayerProgress[1] >= 100.f - KINDA_SMALL_NUMBER)
				{
					// float Difference = PlayerProgress[0] - PlayerProgress[1];
					// Difference = FMath::Abs(Difference);
					// Print("DIFFERENCE BETWEEN PLAYERS IN ABS: " + Difference, 20.f);
					NetCheckPlayerValidation(Game::Cody, HitByObstacles[Game::Cody]);
				}
			}

			if (Game::May.HasControl())
			{
				if (PlayerProgress[0] >= 100.f - KINDA_SMALL_NUMBER)
				{
					// float Difference = PlayerProgress[0] - PlayerProgress[1];
					// Difference = FMath::Abs(Difference);
					// Print("DIFFERENCE BETWEEN PLAYERS IN ABS: " + Difference, 20.f);
					NetCheckPlayerValidation(Game::May, HitByObstacles[Game::May]);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetCheckPlayerValidation(AHazePlayerCharacter Player, int ObstacleImpacts)
	{
		PlayerProgress[Player] = 100;
		bPlayerFinished[Player] = true;

		if (Player.OtherPlayer.HasControl())
		{
			float Difference = PlayerProgress[0] - PlayerProgress[1];
			Difference = FMath::Abs(Difference);

			if (Difference <= 2.f)
				NetPendingWinner(nullptr, Player);
			else if (bPlayerFinished[Player.OtherPlayer] && HitByObstacles[Player.OtherPlayer] > ObstacleImpacts)
				NetPendingWinner(Player, Player);
			else if (bPlayerFinished[Player.OtherPlayer] && HitByObstacles[Player.OtherPlayer] < ObstacleImpacts)
				NetPendingWinner(Player.OtherPlayer, Player);
			else if (!bPlayerFinished[Player.OtherPlayer])
				NetPendingWinner(Player, Player);
			else
				NetPendingWinner(nullptr, Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetPendingWinner(AHazePlayerCharacter Winner, AHazePlayerCharacter Validator)
	{
		if (Winner != nullptr)
		{
			DerbyHorses[Winner].HorseDerbyCollideState = EHorseDerbyCollideState::RaceComplete;
		}
		else
		{
			DerbyHorses[Game::May].HorseDerbyCollideState = EHorseDerbyCollideState::RaceComplete;
			DerbyHorses[Game::Cody].HorseDerbyCollideState = EHorseDerbyCollideState::RaceComplete;
		}

		if (!HasControl())
			return;
		
		if(Gamestate == EDerbyHorseState::GameWon)
			return;

		PendingWinner = Winner;
		
		if (AnnounceWinnerCountdown <= 0.f)
			AnnounceWinnerCountdown = 1.f;
		else 
			AnnounceWinnerCountdown = KINDA_SMALL_NUMBER;
	}

	void SetDifficulty(bool IsMay, float Progress)
	{
		float DifficultyModifier = 0.f;
		float MaxDifficulty = 4.f;

		//Make 100% difficulty appear around 75-80% progression.
		DifficultyModifier = FMath::Lerp(2.f, MaxDifficulty, Progress / 90.f);
		
		if(IsMay)
			MayDifficultyModifier = DifficultyModifier;
		else
			CodyDifficultyModifier = DifficultyModifier;
	}

	//Scroll Background actors.
	void ScrollBackgrounds(float DeltaTime)
	{
		for (AHorseDerbyScrollManager Manager : HorseDerbyScrollManagers)
		{
			Manager.MoveAndCheckScrollActors(DeltaTime);
		}
	}

//	Interaction / Validation

	//Function Called every time a player reaches a set destination (Inactive, startline, finish, etc)
	UFUNCTION(NetFunction)
	void ReachedPosition(AHazePlayerCharacter Player, EDerbyHorseState State)
	{
		switch(State)
		{
			case(EDerbyHorseState::AwaitingStart):

				if((DerbyHorses[0].HorseState == State && DerbyHorses[1].HorseState == State) && (MayRef != nullptr && CodyRef != nullptr))
				{
					VerifyStopResetAudio();
					
					if (HasControl())
						NetShowTutorial();
				}
				break;

			case(EDerbyHorseState::Inactive):
				{
					VerifyStopResetAudio();
					break;
				}

			default:
				break;
		}
	}

//	Audio Functions
	void VerifyStopResetAudio()
	{
		if((DerbyHorses[0].HorseState == EDerbyHorseState::AwaitingStart || DerbyHorses[0].HorseState == EDerbyHorseState::Inactive) &&
		 (DerbyHorses[1].HorseState == EDerbyHorseState::AwaitingStart || DerbyHorses[1].HorseState == EDerbyHorseState::Inactive))
		{
			HazeAkCompMachinery.HazePostEvent(StopResetLoopEvent);
		}
	}

	UFUNCTION(NetFunction)
	void NetShowTutorial()
	{
		if(MayRef != nullptr && CodyRef != nullptr)
			SetFullScreen();

		if(!bDoorsOpen)
			OpenObstacleDoors();

		MinigameComp.ActivateTutorial();
	}

	void SetFullScreen()
	{
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 1.6f;
		FHazeCameraBlendSettings FovBlend;
		FovBlend.BlendTime = 2.1f;

		ReadyActiveCamera.DeactivateCamera(Game::May);
		ReadyActiveCamera.DeactivateCamera(Game::Cody);

		if (Game::May.HasControl())
		{
			Game::May.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			GameActiveCamera.ActivateCamera(Game::May, CamBlend);
			Game::May.ApplyCameraSettings(CamSettings, CamBlend, this, EHazeCameraPriority::Script);
			Game::May.ApplyFieldOfView(FOVActiveCamera, FovBlend, this);
		}
		else
		{
			Game::Cody.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			GameActiveCamera.ActivateCamera(Game::Cody, CamBlend);
			Game::Cody.ApplyCameraSettings(CamSettings, CamBlend, this, EHazeCameraPriority::Script);
			Game::Cody.ApplyFieldOfView(FOVActiveCamera, FovBlend, this);
		}
	}

	UFUNCTION()
	void OnTutorialAccepted()
	{
		CurrentSequenceCount[0] = 0;
		CurrentSequenceCount[1] = 0;
		MinigameComp.StartCountDown();

		DerbyHorses[0].HorseDerbyCollideState = EHorseDerbyCollideState::Available;
		DerbyHorses[1].HorseDerbyCollideState = EHorseDerbyCollideState::Available;

		for (AHorseDerbyScrollManager Manager : HorseDerbyScrollManagers)
		{
			Manager.AccelMoveSpeed.SnapTo(0.f);
		}

		PopulateObstacleSequenceLists();
		bCalledWinner = false;
	}

	UFUNCTION(NetFunction)
	void NetCheckStartGame()
	{
		if (HasControl() && Network::IsNetworked())
			System::SetTimer(this, n"StartGame", Network::GetPingRoundtripSeconds() * 0.5f, false);
		else
			StartGame();
	}

	UFUNCTION()
	void StartGame()
	{
		HitByObstacles[0] = 0;
		HitByObstacles[1] = 0;

		bPlayerFinished[0] = false;
		bPlayerFinished[1] = false;

		CodyTimer = ObstacleFrequency;
		MayTimer = ObstacleFrequency;

		MayDifficultyModifier = 1.f;
		CodyDifficultyModifier = 1.f;

		Gamestate = EDerbyHorseState::GameActive;

		DerbyHorses[0].bCanCancelMidGame = true;
		DerbyHorses[1].bCanCancelMidGame = true;

		Game::May.ShowCancelPrompt(this);
		Game::Cody.ShowCancelPrompt(this);

		DerbyHorses[0].SwitchState(EDerbyHorseState::GameActive);
		DerbyHorses[1].SwitchState(EDerbyHorseState::GameActive);
		
		HazeAkCompMachinery.HazePostEvent(StartMachineryLoopEvent);

		TArray<ATownsfolkDerbySpectator> Spectators;
		GetAllActorsOfClass(Spectators);

		for (ATownsfolkDerbySpectator Spectator : Spectators)
			Spectator.PlayRaceActiveMh();
	}

	UFUNCTION(NetFunction)
	void NetFinishGame(AHazePlayerCharacter Winner)
	{
		if (Winner == nullptr)
			MinigameComp.AnnounceWinner(EMinigameWinner::Draw);
		else
			MinigameComp.AnnounceWinner(Winner);

		bCalledWinner = true;

		CancelForBothPlayers();

		FHazeJumpToData JumpDataCody;
		JumpDataCody.TargetComponent = DerbyHorses[Game::Cody].JumpToLocation;

		FHazeJumpToData JumpDataMay;
		JumpDataMay.TargetComponent = DerbyHorses[Game::May].JumpToLocation;

		Gamestate = EDerbyHorseState::GameWon;

		DerbyHorses[0].InteractionDisabled(Game::May);
		DerbyHorses[1].InteractionDisabled(Game::Cody);
		DerbyHorses[0].SwitchState(EDerbyHorseState::GameWon);
		DerbyHorses[1].SwitchState(EDerbyHorseState::GameWon);

		JumpTo::ActivateJumpTo(Game::Cody, JumpDataCody);
		JumpTo::ActivateJumpTo(Game::May, JumpDataMay);

		StopGame();
	}

	UFUNCTION()
	void CancelComplete(AHazePlayerCharacter CancelledPlayer)
	{
		if (HasControl())
			NetPlayerMidgameCancel(CancelledPlayer);
	}

	UFUNCTION(NetFunction)
	void NetPlayerMidgameCancel(AHazePlayerCharacter CancelledPlayer)
	{
		if (Gamestate == EDerbyHorseState::GameWon)
			return;
			
		MinigameComp.AnnounceWinner(CancelledPlayer.OtherPlayer);

		CancelForBothPlayers();

		FHazeJumpToData JumpDataCody;
		JumpDataCody.TargetComponent = DerbyHorses[Game::Cody].JumpToLocation;

		FHazeJumpToData JumpDataMay;
		JumpDataMay.TargetComponent = DerbyHorses[Game::May].JumpToLocation;

		JumpTo::ActivateJumpTo(Game::Cody, JumpDataCody);
		JumpTo::ActivateJumpTo(Game::May, JumpDataMay);

		Gamestate = EDerbyHorseState::GameWon;

		DerbyHorses[0].InteractionDisabled(Game::May);
		DerbyHorses[1].InteractionDisabled(Game::Cody);
		DerbyHorses[0].SwitchState(EDerbyHorseState::GameWon);
		DerbyHorses[1].SwitchState(EDerbyHorseState::GameWon);

		StopGame();
	}

	UFUNCTION()
	void StopGame()
	{
		Gamestate = EDerbyHorseState::AwaitingStart;

		Game::May.RemoveCancelPromptByInstigator(this);
		Game::Cody.RemoveCancelPromptByInstigator(this);

		ObstacleComp.BeginResetOfActiveObstacles(DerbyHorses[0], Game::May);
		ObstacleComp.BeginResetOfActiveObstacles(DerbyHorses[1], Game::Cody);
		
		HazeAkCompMachinery.HazePostEvent(StopMachineryLoopEvent);
		HazeAkCompMachinery.HazePostEvent(StartResetLoopEvent);

		TArray<ATownsfolkDerbySpectator> Spectators;
		GetAllActorsOfClass(Spectators);
		for (ATownsfolkDerbySpectator Spectator : Spectators)
			Spectator.PlayWaitMh();
	}

// 	Obstacle / Gameplay Functions
	UFUNCTION()
	void ChooseObstacle(AHazePlayerCharacter Player)
	{
		SpawnObstacle(Player, ObstacleSpawnSequence[CurrentSequenceCount[Player]]);

		if (CurrentSequenceCount[Player] < MaxSequenceCount - 1)
			CurrentSequenceCount[Player]++;
		else
			CurrentSequenceCount[Player] = 0;
	}

	void SpawnObstacle(AHazePlayerCharacter Player, int Index)
	{
		EHorseDerbyObstacle Type;

		if(Index == 0)
		{
			ObstacleComp.ActivateJumpObstacle(PlayerTracks[Player], DerbyHorses[Player], Player);
			Type = EHorseDerbyObstacle::Jump;
		}
		else
		{
			ObstacleComp.ActivateCrouchObstacle(PlayerTracks[Player], DerbyHorses[Player], Player);
			Type = EHorseDerbyObstacle::Crouch;
		}
	}

	void PopulateObstacleSequenceLists()
	{
		if (HasControl())
		{
			TArray<int> NewSequence;
			TArray<int> LastTwoRecorded;

			for (int i = 0; i < MaxSequenceCount; i++)
			{
				int RandomIndex = FMath::RandRange(0, 1);
				
				if (LastTwoRecorded.Num() < 2)
				{
					LastTwoRecorded.Add(RandomIndex);
				}
				else
				{
					//if last int is equal to the last two, set to opposite
					if (LastTwoRecorded[0] == LastTwoRecorded[1] && LastTwoRecorded[0] == RandomIndex)
					{
						if (RandomIndex == 0)
							RandomIndex = 1;
						else
							RandomIndex = 0;
					}

					LastTwoRecorded.Add(RandomIndex);

					LastTwoRecorded.RemoveAt(0);
				}

				NewSequence.Add(RandomIndex);
			}

			NetSetLists(NewSequence);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetLists(TArray<int> SequenceList)
	{
		ObstacleSpawnSequence = SequenceList;
	}

	void OpenObstacleDoors()
	{
		for(AHorseDerbyObstacleDoors Door : ObstacleDoors)
		{
			Door.OpenDoors();
			bDoorsOpen = true;
		}
	}

	void CloseObstacleDoors()
	{
		for(AHorseDerbyObstacleDoors Door : ObstacleDoors)
		{
			Door.CloseDoors();
			bDoorsOpen = false;
		}
	}

	UFUNCTION()
	void AllObstaclesCleared()
	{
		AllObstaclesDisabled = true;

		if(DerbyHorses[0].InteractingPlayer == nullptr || DerbyHorses[1].InteractingPlayer == nullptr)
			CloseObstacleDoors();
	}
}