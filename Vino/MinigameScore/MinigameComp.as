import Vino.MinigameScore.ScoreHud;
import Vino.MinigameScore.MinigameCharacter;
import Vino.MinigameScore.PlayerMinigameTutorialComponent;
import Vino.MinigameScore.MinigameCharacterComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Objectives.ObjectivesStatics;
import Vino.Tutorial.TutorialPrompt;
import Peanuts.Animation.Features.LocomotionFeatureMiniGamePostState;
import Vino.MinigameScore.PlayerMinigameComponent;
import Vino.Interactions.DoubleInteractComponent;
import Peanuts.Foghorn.FoghornStatics;

const FConsoleVariable CVar_DebugDesyncMinigameData("Haze.DebugDesyncMinigameData", 0);

event void FMiniGameDiscovered();

event void FCountDownGo();

event void FOnShowHideScoreBoxes(bool bShouldShow);

event void FMinigameCountDownCompleted();

event void FMiniGameTutorialStarted();

event void FMiniGameTutorialPlayerReady(AHazePlayerCharacter Player);

event void FMiniGameTutorialEnded();

event void FScoreChanged(AHazePlayerCharacter Player, float Score);

event void FMinigameTimerCompleted();

event void FMiniGameShowWinner();

event void FMinigameVictoryScreenFinished();

event void FMinigamePlayerLeft(AHazePlayerCharacter Player);

event void FMinigameTutorialComplete();

event void FMinigameOnEndReactionsComplete();

event void FMinigameOnMayReactionComplete();

event void FMinigameOnCodyReactionComplete();

event void FMinigameOnHideGameHUD();

event void FOnCountDownBeingUsedConfirmation();

event void FOnMinigameStarted();

enum EOnEnterGameAreaState
{
	ShowBoth,
	ShowOnlyTambourineCharacter,
	ShowOnlyHighScores
};

enum EMinigameConfettiSettings
{
	AbovePlayer,
	AboveCamera
}

struct FMinigameMenuScoreCount
{
	int MayWins;
	int CodyWins;
	int Draws;
}

class UMinigameComp : UActorComponent 
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PrePhysics;

	//*** VO SETUP ***//
	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;
	UPROPERTY(Category = "VOBank")
	bool bAutoPlayApproach = true;
	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOGenericBank;
	default VOGenericBank = Asset("/Game/Blueprints/Minigame/MinigameGenericVOBank.MinigameGenericVOBank");
	UPROPERTY(Category = "VOBank")
	float MinPendingPlayDistance = 500.f;
	UPROPERTY(Category = "VOBank")
	bool bEnableFoghornMinigameMode;
	
	//If player dies on game complete, Foghorn win/lose VO gets a 1 second delay to give players time to respawn for for Foghorn to unpause itself
	UPROPERTY(Category = "VOBank")
	bool bDeathOnVictoryCheck;

	int drawPlayIndex;

	//*** GENERAL SETUP ***//
	UScoreHud ScoreHud;

	UPROPERTY(Category = "MiniGame Setup")
	FName MinigameID;
	UPROPERTY(Category = "Minigame Setup")
	EMinigameTag MinigameTag;
	UPROPERTY(Category = "MiniGame Setup")
	TSubclassOf<UScoreHud> ScoreHudClass;
	default ScoreHudClass = Asset("/Game/GUI/Minigames/WBP_MinigameScoreHud.WBP_MinigameScoreHud_C");
	UPROPERTY(Category = "Minigame Tutorial", Meta = (Multiline=true))
	FText TutorialInstructionsMay;
	UPROPERTY(Category = "Minigame Tutorial")
	TArray<FTutorialPrompt> TutorialPromptsMay;
	UPROPERTY(Category = "Minigame Tutorial", Meta = (Multiline=true))
	FText TutorialInstructionsCody;
	UPROPERTY(Category = "Minigame Tutorial")
	TArray<FTutorialPrompt> TutorialPromptsCody;
	UPROPERTY(Category = "Minigame Setup")
	FScoreHudData ScoreData;
	UPROPERTY(Category = "Minigame Setup")
	private TSubclassOf<UMinigameInGameText> InWorldWidgetClass;
	default InWorldWidgetClass = Asset("/Game/GUI/Minigames/WBP_InGameScoreWidget.WBP_InGameScoreWidget_C");
	UPROPERTY(Category = "Minigame Setup")
	EMinigameConfettiSettings ConfettiSettings;

	UPROPERTY(Category = "Tambourine Settings")
	bool bDisableTambourineCharacter;
	UPROPERTY(Category = "Tambourine Settings")
	AActor TambourineSpawnLocation;
	UPROPERTY(Category = "Tambourine Settings")
	FVector TambourineSpawnRelativeOffset = FVector::ZeroVector;

	UPROPERTY()
	TSubclassOf<AMinigameCharacter> TambourineCharacterClass;
	default TambourineCharacterClass = Asset("/Game/Blueprints/Minigame/BP_TambourineCharacter.BP_TambourineCharacter_C");

	UPROPERTY(Category = "Minigame References")
	TArray<AVolume> EnterMinigameAreaVolumes;
	UPROPERTY(Category = "Minigame References")
	TArray<AVolume> HudAreaVolumes;
	UPROPERTY(Category = "Minigame References")
	TArray<AVolume> LeaveDuringMinigameVolumes;
	UPROPERTY(Category = "Minigame References")
	UNiagaraSystem TambourinePuffSystem;
	default TambourinePuffSystem = Asset("/Game/Effects/Niagara/GameplayTamboPop_01");
	UPROPERTY(Category = "Minigame References")
	UNiagaraSystem MayConfetti;
	default MayConfetti = Asset("/Game/Effects/Niagara/GameplayConfettiMayWin_01");
	UPROPERTY(Category = "Minigame References")
	UNiagaraSystem CodyConfetti;
	default CodyConfetti = Asset("/Game/Effects/Niagara/GameplayConfettiCodyWin_01");
	
	UPROPERTY(Category = "Capabilities")	
	UHazeCapabilitySheet TambourineCapabilitySheet; 
	default TambourineCapabilitySheet = Asset("/Game/Blueprints/Minigame/DA_TambourineCharacter_CapabilitySheet.DA_TambourineCharacter_CapabilitySheet");
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet TutorialCapabilitySheet;
	default TutorialCapabilitySheet = Asset("/Game/Blueprints/Minigame/DA_PlayerMinigameTutorialSheet.DA_PlayerMinigameTutorialSheet");
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet MinigameReactionCapabilitySheet = Asset("/Game/Blueprints/Minigame/DA_PlayerMinigameReaction_CapabilitySheet.DA_PlayerMinigameReaction_CapabilitySheet");;
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerBlockMovementCapabilitySheet;
	default PlayerBlockMovementCapabilitySheet = Asset("/Game/Blueprints/Minigame/DA_PlayerMinigameBlockMovementStandard.DA_PlayerMinigameBlockMovementStandard");
	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayWinnerConfettiAudioEvent;
	default PlayWinnerConfettiAudioEvent = Asset("/Game/Audio/UI/UI_OnScreen_SideContent/MiniGame/Play_UI_OnScreen_SideContent_MiniGame_Screen_WinningConfetti");

	UPROPERTY()
	FMiniGameDiscovered OnMinigameDiscovered;

	UPROPERTY()
	FCountDownGo OnCountdownStartedEvent;

	UPROPERTY()
	FMinigameCountDownCompleted OnCountDownCompletedEvent;

	UPROPERTY()
	FOnCountDownBeingUsedConfirmation OnCountDownBeingUsedConfirmation;

	UPROPERTY()
	FOnMinigameStarted OnMinigameStarted;

	UPROPERTY()
	FOnShowHideScoreBoxes OnShowHideScoreBoxes;

	UPROPERTY()
	FMiniGameShowWinner OnMiniGameShowWinner;

	UPROPERTY()
	FMinigameTimerCompleted OnTimerCompletedEvent; 

	UPROPERTY()
	FScoreChanged OnScoreChangeEvent;

	UPROPERTY()
	FMinigamePlayerLeft OnMinigamePlayerLeftEvent;

	UPROPERTY()
	FMinigameVictoryScreenFinished OnMinigameVictoryScreenFinished;

	UPROPERTY()
	FMinigameOnEndReactionsComplete OnEndMinigameReactionsComplete;
	
	UPROPERTY()
	FMinigameOnMayReactionComplete OnMayReactionComplete;

	UPROPERTY()
	FMinigameOnCodyReactionComplete OnCodyReactionComplete;

	UPROPERTY()
	FMinigameOnHideGameHUD OnHideGameHUD;

	UPROPERTY()
	FMiniGameTutorialStarted OnMinigameTutorialStarted;

	UPROPERTY()
	FMiniGameTutorialPlayerReady OnTutorialPlayerReady;

	UPROPERTY()
	FMinigameTutorialComplete OnMinigameTutorialComplete;

	UPROPERTY()
	FOnTutorialCancel OnTutorialCancel;

	UPROPERTY()
	FOnTutorialCancelFromPlayer OnTutorialCancelFromPlayer;

	UPROPERTY(ShowOnActor, meta = (MakeEditWidget))
	FVector TambourineCharacterLoc;

	FVector TambourineCharacterWorldStartLoc;

	UPROPERTY(Category = "Animations")
	ULocomotionFeatureMiniGamePostState MayLocoData;
	default MayLocoData = Asset("/Game/Blueprints/Animation/LocomotionFeatureAssets/DA_MiniGamePostStateFeature_May.DA_MiniGamePostStateFeature_May");

	UPROPERTY(Category = "Animations")
	ULocomotionFeatureMiniGamePostState CodyLocoData;
	default CodyLocoData = Asset("/Game/Blueprints/Animation/LocomotionFeatureAssets/DA_MiniGamePostStateFeature_Cody.DA_MiniGamePostStateFeature_Cody");

	int MaxPlayIndexWin = 13;

	AMinigameCharacter TambourineCharacter;

	AHazePlayerCharacter WinningPlayer;
	AHazePlayerCharacter LosingPlayer;

	TArray<AHazePlayerCharacter> PlayersCheck;

	//*** GAME HUD INFO***//

	int PlayersInRange;
	int CountCheck = 1;

	// int PlayerHudInRange; //Remove if below vars work
	int MayInRange;
	int CodyInRange;

	int PlayerInAreaRange;

	bool bPlayersInRange;
	bool bCanDeactivateGameHud;
	// bool bHasDelayedDeactivationActive = false;

	// bool bAnnouncingWinnerCheck;

	EMinigameWinner CurrentMinigameWinner;

	bool bMayBlocked;
	bool bCodyBlocked;

	//Player sequencer on win and pipe in player to get location etc.
	float CountDownSeconds = 1.f;

	float MaxCountDownSeconds = 6.f;

	float CurrentTimer;

	float VictoryScreenTimer = 4.75f;

	UPROPERTY(Category = "MiniGame Setup")
	bool bDontSpawnTambourineCharacter;

	UPROPERTY(Category = "MiniGame Setup")
	bool bStartTimerOnCountDownFinshed;

	UPROPERTY(Category = "MiniGame Setup")
	bool bReversedTimer;

	UPROPERTY(Category = "MiniGame Setup")
	float CharacterMinReactionDistance = 1700.f;

	UPROPERTY(Category = "MiniGame Setup")
	float StartingScore = 0;
	
	UPROPERTY(Category = "MiniGame Setup")
	bool bMayAutoReactionAnimations = true;

	UPROPERTY(Category = "MiniGame Setup")
	bool bCodyAutoReactionAnimations = true;

	UPROPERTY(Category = "MiniGame Setup")
	bool bPlayWinningAnimations = true;

	UPROPERTY(Category = "MiniGame Setup")
	bool bPlayLosingAnimations = true;

	UPROPERTY(Category = "MiniGame Setup")
	bool bPlayDrawAnimations = true;

	bool bCanCountDown;
	bool bShowTimerDuringCountdown;
	bool bPlayersHaveSheet;
	bool bCanTimer;

	bool bTambourineActivePending;
	bool bTambourineIsActive; 
	bool bTambourineExiting;
	bool bCanTransitionHudExit;
	bool bWaitingForExitTransition;
	bool bWaitingForHighScoreTransition;
	bool bGameHudIsActive;
	bool bPlayerInHudArea;
	
	float PendingTime;
	float MaxPendingTime = 1.f;
	float TransitionTimeHudExit;	
	float TransitionTimeHudTarget = 1.f;
	float TransitionTambourineExit;
	float TransitionTambourineTarget = 0.85f;
	
	// private int PlayersTutorialReady;
	bool bMayReady;
	bool bCodyReady;
	private int PlayerCompleteVictoryAnimation;

	private bool bShowScoreBoxesDefault;
	private bool bShowHighScoreDefault;
	private bool bShowTimerDefault;
	bool bEnteredTutorialMode;

	//decides whether high score should show when player is near
	private bool bGameHasBeenDiscovered;

	private bool bHavePlayed;
	
	bool bTelemetryGameModeStarted;

	//*** LEAVE VOLUME ***//
	bool bLeaveTriggerFired;

	//*** AUDIO INFO ***//

	bool bCountDownInUseConfirmed;
	bool bCanScoreAudioEvent;
	float CurrentScoreEventTimer;
	float DefaultScoreEventTimer = 0.3f;

	//*** TUTORIAL WIDGET ***//

	UPlayerMinigameTutorialComponent MayTutorialComp;
	UPlayerMinigameTutorialComponent CodyTutorialComp;

	//*** IN-WORLD WIDGET ***//

	TArray<UMinigameInGameText> MayWidgetPool;
	TArray<UMinigameInGameText> CodyWidgetPool;

	//*** SAVED DATA ***//

 	FName CodyHighScoreData;
	FName MayHighScoreData;
	FName HaveDiscoveredData;
	FName HavePlayedData;

	FName MayWinsData;
	FName CodyWinsData;
	FName DrawData;
	
	//LAPS
	FName MayBestLapData;
	FName CodyBestLapData;
	FName MayLastLapData;
	FName CodyLastLapData;

	int TambourineSpawnCounter = 0;

	FName TelemetryMinigameName;
	FName TelemetryWinnerMinigameName;
	FName TelemetryGameExitViaMenu;

	TPerPlayer<AHazePlayerCharacter> CurrentPlayers;

	float CurrentMayLapTime;
	float CurrentCodyLapTime;

	//Main Menu Saved Scores
	FMinigameMenuScoreCount MenuScores;

	AHazePlayerCharacter TelemtryWinningPlayer;
	
	UMinigameCharacterComponent MinigameCharacterComp;

	TPerPlayer<UPlayerMinigameComponent> PlayerMinigameComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilitySheetRequest(MinigameReactionCapabilitySheet);
		
		PlayerMinigameComps[0] = UPlayerMinigameComponent::Get(Game::May); 
		PlayerMinigameComps[1] = UPlayerMinigameComponent::Get(Game::Cody); 
		PlayerMinigameComps[0].LocoData = MayLocoData;
		PlayerMinigameComps[1].LocoData = CodyLocoData;

		if (EnterMinigameAreaVolumes.Num() > 0)
		{
			for (AVolume Volume : EnterMinigameAreaVolumes)
			{
				if (Volume == nullptr)
					continue;

				Volume.OnActorBeginOverlap.AddUFunction(this, n"MainAreaVolumeBeginOverlap");
				Volume.OnActorEndOverlap.AddUFunction(this, n"MainAreaVolumeEndOverlap");
			}
		}
		else
		{
			devEnsure(false, "No EnterMinigameArea volumes have been added to " + Owner.Name + 
			". An overlap volume for the player is required here so that the MinigameComp knows when to spawn the Tamboruine");
		}

		if (LeaveDuringMinigameVolumes.Num() > 0)
		{
			for (AVolume Volume : LeaveDuringMinigameVolumes)
			{
				if (Volume == nullptr)
					continue;

				Volume.OnActorEndOverlap.AddUFunction(this, n"ActorAreaVolumeEndOverlap");
			}
		}

		if (HudAreaVolumes.Num() > 0)
		{
			for (AVolume Volume : HudAreaVolumes)
			{
				if (Volume == nullptr)
					continue;

				Volume.OnActorBeginOverlap.AddUFunction(this, n"ActorHudAreaBeginOverlap");
				Volume.OnActorEndOverlap.AddUFunction(this, n"ActorHudAreaEndOverlap");
			}
		}
		else
		{
			devEnsure(false, "No HudAreaVolumes volumes have been added to " + Owner.Name + 
			". An overlap volume for the player is required here so that the 'Discovered Minigame' event can occur. If no discovery is made, the ActivateTutorial function won't run");
		}

		OnMinigameVictoryScreenFinished.AddUFunction(this, n"ShowHighScoreOnVictory");

		InitializePersistentData();

		bCanDeactivateGameHud = true;

		drawPlayIndex = FMath::RandRange(0, 1);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{

#if EDITOR
		if(EndPlayReason == EEndPlayReason::EndPlayInEditor)
			return;
#endif
		// bHasDelayedDeactivationActive = false;

		if (bTelemetryGameModeStarted)
		{
			Telemetry::EndGameMode(TelemetryMinigameName);
			Telemetry::TriggerGameEvent(Game::May, TelemetryGameExitViaMenu);
			bTelemetryGameModeStarted = false;
		}

		Capability::RemovePlayerCapabilitySheetRequest(MinigameReactionCapabilitySheet);

		bTambourineExiting = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CountdownCheck(DeltaTime);
		TimerCheck(DeltaTime);
		TambourineTransitions(DeltaTime);

		RunScoreEventTimer(DeltaTime);
	}

	void InitializePersistentData()
	{
		MayHighScoreData = FName(MinigameID + "_MayHighScore");
		CodyHighScoreData = FName(MinigameID + "_CodyHighScore");

		MayBestLapData = FName(MinigameID + "_MayBestLap");
		CodyBestLapData = FName(MinigameID + "_CodyBestLap");
		MayLastLapData = FName((MinigameID + "_MayLastLap"));
		CodyLastLapData = FName(MinigameID + "_CodyLastLap");
		
		HaveDiscoveredData = FName(MinigameID + "_HaveDiscovered");
		HavePlayedData = FName(MinigameID + "_HavePlayed");

		MayWinsData = FName(MinigameID + "_MayWinsData");
		CodyWinsData = FName(MinigameID + "_CodyWinsData");
		DrawData = FName(MinigameID + "_DrawData");

		if (CVar_DebugDesyncMinigameData.GetInt() == 0)
		{
			if (Save::CanAccessProfileData())
			{
				ScoreData.MayHighScore = Save::GetPersistentProfileCounter(MayHighScoreData, Type = EHazeSaveDataType::MinigameLocal);
				ScoreData.CodyHighScore = Save::GetPersistentProfileCounter(CodyHighScoreData, Type = EHazeSaveDataType::MinigameLocal);

				ScoreData.MayBestLap = Save::GetPersistentProfileCounter(MayBestLapData, Type = EHazeSaveDataType::MinigameLocal);
				ScoreData.CodyBestLap = Save::GetPersistentProfileCounter(CodyBestLapData, Type = EHazeSaveDataType::MinigameLocal);
				ScoreData.MayLastLap = Save::GetPersistentProfileCounter(MayLastLapData, Type = EHazeSaveDataType::MinigameLocal);
				ScoreData.CodyLastLap = Save::GetPersistentProfileCounter(CodyLastLapData, Type = EHazeSaveDataType::MinigameLocal);

				MenuScores.MayWins = Save::GetPersistentProfileCounter(MayWinsData, Type = EHazeSaveDataType::MinigameLocal);
				MenuScores.CodyWins = Save::GetPersistentProfileCounter(CodyWinsData, Type = EHazeSaveDataType::MinigameLocal);
				MenuScores.Draws = Save::GetPersistentProfileCounter(DrawData, Type = EHazeSaveDataType::MinigameLocal);

				bGameHasBeenDiscovered = Save::IsPersistentProfileFlagSet(EHazeSaveDataType::MinigameLocal, HaveDiscoveredData);
				bHavePlayed = Save::IsPersistentProfileFlagSet(EHazeSaveDataType::MinigameLocal, HavePlayedData);
			}
		}
		else
		{
			ScoreData.MayHighScore = FMath::RandRange(0, 10);
			ScoreData.CodyHighScore = FMath::RandRange(0, 10);

			ScoreData.MayBestLap = FMath::RandRange(1, 60);
			ScoreData.CodyBestLap = FMath::RandRange(1, 60);
			ScoreData.MayLastLap = FMath::RandRange(1, 60);
			ScoreData.CodyLastLap = FMath::RandRange(1, 60);

			if (CVar_DebugDesyncMinigameData.GetInt() == 1)
			{
				bGameHasBeenDiscovered = FMath::RandBool();
				bHavePlayed = FMath::RandBool();
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 2)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = Network::HasWorldControl();
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 3)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = !Network::HasWorldControl();
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 4)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = !Network::HasWorldControl();
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 5)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = Network::HasWorldControl();
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 6)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = false;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 7)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = false;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 8)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = false;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 9)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = false;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 10)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = true;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 11)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = true;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 12)
			{
				bGameHasBeenDiscovered = Network::HasWorldControl();
				bHavePlayed = true;
			}
			else if (CVar_DebugDesyncMinigameData.GetInt() == 13)
			{
				bGameHasBeenDiscovered = !Network::HasWorldControl();
				bHavePlayed = true;
			}
		}

		bShowTimerDefault = ScoreData.ShowTimer;
		bShowScoreBoxesDefault = ScoreData.ShowScoreBoxes;
		bShowHighScoreDefault = ScoreData.ShowHighScore;

		TelemetryMinigameName = FName(MinigameID);
		TelemetryWinnerMinigameName = FName("Winner_" + MinigameID);
		TelemetryGameExitViaMenu = FName("Exited Game Via Menu_" + MinigameID);
	}

	void CheckCountDownBinding()
	{
		if (OnCountDownCompletedEvent.IsBound() && !bCountDownInUseConfirmed)
		{
			OnCountDownBeingUsedConfirmation.Broadcast();
			bCountDownInUseConfirmed = true;	
		}
	}

	void CountdownCheck(float DeltaTime)
	{
		if (bCanCountDown)
		{	
			CountDownSeconds -= DeltaTime;

			if (bShowTimerDuringCountdown && CountDownSeconds < 1.2f)
			{
				if (ScoreData.ScoreMode == EScoreMode::Laps && bShowScoreBoxesDefault)
					ShowLapsScoreBox(true);
				else if (bShowScoreBoxesDefault)
					ScoreHud.SetScoreBoxVisibility(true);

				bShowTimerDuringCountdown = false;
			}

			if (CountDownSeconds <= 0.f)
			{
				OnCountDownCompletedEvent.Broadcast();

				ShowGameHud(true);

				if (bStartTimerOnCountDownFinshed)
					StartTimer();

				bCanCountDown = false;
			}
		}
	}

	void TimerCheck(float DeltaTime)
	{
		if (bCanTimer)
		{
			if (bReversedTimer)
				TimerUp(DeltaTime);
			else
				TimerDown(DeltaTime);
		}
	}

	void TambourineTransitions(float DeltaTime)
	{
		if (bWaitingForExitTransition)
		{
			if (!bCanTransitionHudExit && bPlayersInRange)
			{
				EnterMinigameCreateHud();
				
				if (!bTambourineExiting)
				{
					if (!bGameHasBeenDiscovered)
						ActivateTambourineCharacter();
					else
						EnsureDiscoveredOnBothSides();

					bWaitingForExitTransition = false;
				}
			}
		}

		if (bTambourineExiting)
		{
			TransitionTambourineExit -= DeltaTime;

			if (TransitionTambourineExit <= 0.f)
			{
				TambourineSystemSpawnOn();
				DestroyTambourine();
				bTambourineExiting = false;
			}
		}
		else if (bTambourineActivePending && !bTambourineExiting)
		{
			PendingTime -= DeltaTime;

			if (PendingTime <= 0.f)
			{
				if (bPlayersInRange)
				{
					bTambourineIsActive = true;
					bTambourineActivePending = false;
				}
				else
				{
					bTambourineIsActive = false;
					bTambourineActivePending = false;
				}
			}
		}

		if (bTambourineIsActive && !bTambourineExiting)
		{
			if (!bGameHasBeenDiscovered || !bHavePlayed)
			{
				if (TambourineCharacter == nullptr)
					NetSpawnTambourineCharacter();
			}
		}	
	}

	//*** FOR TRIGGERING TAMBOURINE CHARACTER ***//
	UFUNCTION()
    void MainAreaVolumeBeginOverlap(AActor OverlappedActor, AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			if (PlayerInAreaRange < 2)
				PlayerInAreaRange++;

			if (!bHavePlayed)
				ActivateTambourineCharacter();

			ReachedMinigameArea();
		}
    }

    UFUNCTION()
    void MainAreaVolumeEndOverlap(AActor OverlappedActor, AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			if (HasControl())
				NetLeftMinigameArea();

			if (!bPlayersInRange && HasControl())
			{
				if (!bGameHasBeenDiscovered && !bDisableTambourineCharacter)
					NetDeactivateTambourineCharacter();
				else if (!bHavePlayed)
					NetDeactivateTambourineCharacter();
			}
		}
    }

	//DEALS WITH HUD AND OTHER MINIGAME ASPECTS
	UFUNCTION()
	void ActorHudAreaBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;
		
		if (Player == Game::May)
			MayInRange++;
		else if (Player == Game::Cody)
			CodyInRange++;

		if (!bCanDeactivateGameHud)
			return;

		if (ScoreHud == nullptr)
			EnterMinigameCreateHud();

		if (bGameHasBeenDiscovered)
		{
			if (MayInRange == 0 || CodyInRange == 0)
			{
				ScoreHud.SetDiscoveryHudAlreadyOn();

				if (bHavePlayed)
				{
					ScoreHud.SetHighScoreVisibility(true);
					ScoreHud.SetHighScoreVisuals(true);
					ScoreHud.SetMayHighScore(ScoreData.MayHighScore);
					ScoreHud.SetCodyHighScore(ScoreData.CodyHighScore);
				}
			}
		}
		else if (!bGameHasBeenDiscovered)
		{
			ScoreHud.SetHighScoreVisuals(false);
		}

		SetWidgetAnchorPoint(Player);
		
		if (Player == Game::May)
			CurrentPlayers[0] = Player;
		else
			CurrentPlayers[1] = Player;
	}

	UFUNCTION()
	void ActorHudAreaEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;
		
		if (Player == Game::May)
			MayInRange--;

		if (Player == Game::Cody)
			CodyInRange--;

		if (ScoreHud == nullptr)
			return;

		if (!bCanDeactivateGameHud)
			return;

		if (bHavePlayed && MayInRange + CodyInRange == 0)
		{
			ScoreHud.SetHighScoreVisuals(false);
			ScoreHud.ShowTimeCounter(false);
		}

		if (MayInRange + CodyInRange == 0)
			ScoreHud.SetDiscoveryHudAlreadyOff();

		SetWidgetAnchorPoint(Player);

		if (PlayerInAreaRange > 0)
			PlayerInAreaRange--;

		if (Player == Game::May)
		{
			if (CurrentPlayers[0] != nullptr)
				CurrentPlayers[0] = nullptr;
		}
		else
		{
			if (CurrentPlayers[1] != nullptr)
				CurrentPlayers[1] = nullptr;
		}
	}

	//*** FOR WHEN PLAYER LEAVES GAME AREA MID-GAME ***//
    UFUNCTION()
    void ActorAreaVolumeEndOverlap(AActor OverlappedActor, AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			if (HasControl())
				NetPlayerLeftMinigame(Player);
		}
    }

	UFUNCTION(NetFunction)
	void NetPlayerLeftMinigame(AHazePlayerCharacter LeavingPlayer)
	{
		if (!bGameHudIsActive || bLeaveTriggerFired)
			return;

		bLeaveTriggerFired = true;
		OnMinigamePlayerLeftEvent.Broadcast(LeavingPlayer);
	}

	//*** These are be used for keeping track of when a player is within range of the minigame area via volumes ***//
	UFUNCTION()
	void ReachedMinigameArea()
	{
		PlayersInRange++;

		if (!bPlayersInRange)
		{
			bPlayersInRange = true;

			if (bCanTransitionHudExit)
			{
				bWaitingForExitTransition = true;
				return;
			}

			if (MayInRange + CodyInRange == 0 && bCanDeactivateGameHud)
				EnterMinigameCreateHud();
		}
	}

	UFUNCTION(NetFunction)
	void NetLeftMinigameArea()
	{
		PlayersInRange--;
		if (PlayersInRange <= 0)
		{
			bPlayersInRange = false;
			if(bCanDeactivateGameHud/* && !bHasDelayedDeactivationActive*/)
				RemoveHud();
		}
	}

	void SetWidgetAnchorPoint(AHazePlayerCharacter Player)
	{
		if (ScoreHud == nullptr)
			return;

		if (Player == Game::May)
		{
			if (CurrentPlayers[1] == nullptr && MayInRange == 1)
				ScoreHud.SnapHeadTargetPosition(EScoreHudPosition::Left);
			if (CodyInRange == 0)
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Left);
			else if (MayInRange == 0)
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Right);
			else
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Centre);
		}
		else
		{
			if (CurrentPlayers[0] == nullptr && CodyInRange == 1)
				ScoreHud.SnapHeadTargetPosition(EScoreHudPosition::Right);
			if (MayInRange == 0)
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Right);
			else if (CodyInRange == 0)
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Left);
			else
				ScoreHud.SetHeaderTargetPosition(EScoreHudPosition::Centre);
		}
	}

	//*** These will be used for playing the tambourine sound and activating the character when player is near the minigame ***//
	UFUNCTION()
	void ActivateDiscovery(AHazePlayerCharacter DiscoveryPlayer)
	{
		if (!bGameHasBeenDiscovered)
		{
			bGameHasBeenDiscovered = true;
			TriggerUnlockMinigame();

			if (TambourineCharacter != nullptr)
				TambourineCharacter.bGameDiscovered = true;

			if(ScoreHud == nullptr)
				EnterMinigameCreateHud();

			ScoreHud.ShowOnDiscoveryHud();

			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileFlag(EHazeSaveDataType::MinigameLocal, HaveDiscoveredData, bGameHasBeenDiscovered);
			
			FName Discovered(TelemetryMinigameName + " Discovered");

			if (CurrentPlayers[0] != nullptr)
				Telemetry::TriggerGameEvent(CurrentPlayers[0], Discovered);

			if (CurrentPlayers[1] != nullptr)
				Telemetry::TriggerGameEvent(CurrentPlayers[1], Discovered);
			
			if (TambourineCharacter != nullptr && MinigameCharacterComp != nullptr)
				MinigameCharacterComp.bHaveDiscoveredGame = bGameHasBeenDiscovered;

			OnMinigameDiscovered.Broadcast();

			if (bAutoPlayApproach)
				MinigameVOPlayApproach(DiscoveryPlayer, MinigameTag, VOLevelBank);
		}
	}

	void TriggerUnlockMinigame()
	{
		Save::UnlockMinigame(MinigameID);

		// Unlock achievement if all minigames have been found
		if (Save::AreAllMinigamesUnlocked())
		{
			for (auto Player : Game::Players)
				Online::UnlockAchievement(Player, n"MinigameFanatic");
		}
	}

	UFUNCTION()
	void BlockGameHudDeactivation()
	{
		bCanDeactivateGameHud = false;
	}

	UFUNCTION()
	void UnblockGameHudDeactivation()
	{
		bCanDeactivateGameHud = true;

		if (MayInRange + CodyInRange == 0 && ScoreHud != nullptr)
		{
			ScoreHud.SetHighScoreVisuals(false);
			ScoreHud.SetScoreBoxVisibility(false);
			ScoreHud.ShowTimeCounter(false);
		}
		else if (MayInRange + CodyInRange != 0)
		{
			if (ScoreHud == nullptr)
				EnterMinigameCreateHud();
			
			// ScoreHud.SetDiscoveryHudAlreadyOn(); //TODO be instant instead?
			ScoreHud.SetDiscoveryHudOnInstant();

			ScoreHud.SetHighScoreVisibility(true);
			ScoreHud.SetHighScoreVisuals(true);
			ScoreHud.SetMayHighScore(ScoreData.MayHighScore);
			ScoreHud.SetCodyHighScore(ScoreData.CodyHighScore);
		}

		if (MayInRange > 0)
			SetWidgetAnchorPoint(Game::May);
		else if (CodyInRange > 0)
			SetWidgetAnchorPoint(Game::Cody);

		if (!bPlayersInRange && bGameHudIsActive)
		{
			RemoveHud();
		}
	}

	UFUNCTION()
	void ActivateTambourineCharacter()
	{
		if (!bTambourineExiting)
			bTambourineIsActive = true;
		else
		{
			PendingTime = MaxPendingTime;
			bTambourineActivePending = true;
		}
	}

	void EnsureDiscoveredOnBothSides()
	{
		// Even if we aren't spawning the tambourine we need to make sure both sides
		// read this as discovered, because this might be the first time the client sees the minigame
		if (HasControl())
			NetEnsureDiscovered();
	}

	UFUNCTION(NetFunction)
	private void NetEnsureDiscovered()
	{
		ActivateDiscovery(
			Game::May.GetDistanceTo(Owner) < Game::Cody.GetDistanceTo(Owner) ? Game::May : Game::Cody
		);
	}

	UFUNCTION(NetFunction)
	void NetSpawnTambourineCharacter()
	{
		if (TambourineCharacter != nullptr)
			return;

		TPerPlayer<AHazePlayerCharacter> Players;
		
		Players[0] = Game::May;
		Players[1] = Game::Cody;

		FVector LookLocation = (Players[0].ActorLocation + Players[1].ActorLocation) * 0.5f - Owner.ActorLocation;
		LookLocation.Normalize();
		LookLocation.ConstrainToPlane(FVector::UpVector);
		FRotator MakeRot = FRotator::MakeFromX(LookLocation);

		if (TambourineCharacterClass.IsValid())
			TambourineCharacter = Cast<AMinigameCharacter>(SpawnActor(TambourineCharacterClass, GetTambourineSpawnPosition(), MakeRot, NAME_None, true)); 
		else
			devEnsure(false, "Tambourine character class is not set. Set the correct class for your level - 
			EXAMPLE: If in SnowGlobe, set to BP_Tambourine_SnowGlobe. If there is no Tambourine for your level assign BP_TambourineCharacter instead");
		
		if (TambourineCharacter != nullptr)
		{
			TambourineCharacter.TambHazeAkComp.HazePostEvent(TambourineCharacter.SpawnAudioEvent);
			TambourineCharacter.SetCharacterReactionMinDistance(CharacterMinReactionDistance, this);
			// TambourineCharacter.OnAnnouncementCompletedEvent.AddUFunction(this, n"ActivateDiscoveryHud");
			TambourineCharacter.OnAnnouncementStarted.AddUFunction(this, n"ActivateDiscovery");

			TambourineCharacter.MakeNetworked(this, TambourineSpawnCounter++);
			
			TambourineCharacter.FinishSpawningActor();

			TambourineCharacter.AddCapabilitySheet(TambourineCapabilitySheet);	
			MinigameCharacterComp = UMinigameCharacterComponent::Get(TambourineCharacter);

			MinigameCharacterComp.bHaveDiscoveredGame = bGameHasBeenDiscovered;
			
			bTambourineIsActive = true;
			TambourineSystemSpawnOn();
		}
	}

	FVector GetTambourineSpawnPosition() const
	{
		FTransform SpawnTransform = Owner.GetActorTransform();

		if (TambourineSpawnLocation != nullptr)
			SpawnTransform = TambourineSpawnLocation.GetActorTransform();

		FVector SpawnPosition =  SpawnTransform.TransformPosition(TambourineSpawnRelativeOffset);
		return SpawnPosition;
	}

	UFUNCTION(NetFunction)
	void NetDeactivateTambourineCharacter()
	{
		if (TambourineCharacter != nullptr)
		{
			TambourineCharacter.OnTambDespawned();
			
			TransitionTambourineExit = TransitionTambourineTarget;
			TambourineCharacter.bTambDisappear = true;
			
			bTambourineExiting = true;
			bTambourineIsActive = false;
		}
	}

	UFUNCTION()
	void TambourineSystemSpawnOn()
	{
		if (TambourinePuffSystem != nullptr && TambourineCharacter != nullptr)
		{
			FVector SpawnLoc = GetTambourineSpawnPosition() + FVector(0.f, 0.f, 600.f);
			Niagara::SpawnSystemAtLocation(TambourinePuffSystem, SpawnLoc);
			UHazeAkComponent::HazePostEventFireForget(TambourineCharacter.PoofAudioEvent, Owner.GetActorTransform());
		}
	}

	UFUNCTION()
	void DestroyTambourine()
	{
		if (TambourineCharacter != nullptr && !bTambourineIsActive)
		{
			TambourineCharacter.DestroyActor();
			TambourineCharacter = nullptr;
		}
	}

	//*** HUD stuff ***//
	UFUNCTION()
	void CountDownShowScoreBox()
	{
		if (bShowScoreBoxesDefault)
		{
			ScoreHud.SetScoreBoxVisibility(true);
		}
	}

	UFUNCTION()
	void ShowGameHud(bool bWasCountDownStarted = false)
	{
		OnMinigameStarted.Broadcast();

		PlayerMinigameComps[0].OnMinigameReactionAnimationComplete.AddUFunction(this, n"VictoryAnimationComplete");
		PlayerMinigameComps[1].OnMinigameReactionAnimationComplete.AddUFunction(this, n"VictoryAnimationComplete");
		PlayerMinigameComps[0].bMinigameActive = true;
		PlayerMinigameComps[1].bMinigameActive = true;

		bGameHudIsActive = true;

		ScoreHud.SetHighScoreVisuals(false);

		WinningPlayer = nullptr;
		LosingPlayer = nullptr;

		if (!bWasCountDownStarted)
		{
			if (ScoreData.ScoreMode == EScoreMode::Laps && bShowScoreBoxesDefault)
				ShowLapsScoreBox(true);
			else if (bShowScoreBoxesDefault)
				ScoreHud.SetScoreBoxVisibility(true);
		}

		if (bShowTimerDefault)
		{
			ScoreHud.ShowTimeCounter(true);
		}

		if (HasControl() && TambourineCharacter != nullptr)
			NetDeactivateTambourineCharacter();

		if (!bHavePlayed)
		{
			bHavePlayed = true;
			

			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileFlag(EHazeSaveDataType::MinigameLocal, HavePlayedData, bHavePlayed);
		}

		if (!bTelemetryGameModeStarted)
		{
			Telemetry::StartGameMode(TelemetryMinigameName);
			bTelemetryGameModeStarted = true;
		}

		TriggerUnlockMinigame();
	}

	UFUNCTION()
	void EndGameHud()
	{
		PlayerMinigameComps[0].bMinigameActive = false;
		PlayerMinigameComps[1].bMinigameActive = false;

		bGameHudIsActive = false;
		bLeaveTriggerFired = false;

		if (ScoreData.ScoreMode == EScoreMode::Laps && bShowScoreBoxesDefault)
			ShowLapsScoreBox(false);
		else if (bShowScoreBoxesDefault && ScoreHud != nullptr)
			ScoreHud.SetScoreBoxVisibility(false);
		
		if (bShowTimerDefault && ScoreHud != nullptr)
			ScoreHud.ShowTimeCounter(false);

		if (bTelemetryGameModeStarted)
		{
			Telemetry::EndGameMode(TelemetryMinigameName);
			Telemetry::TriggerGameEvent(WinningPlayer, TelemetryWinnerMinigameName);
			bTelemetryGameModeStarted = false;
		}

		UnblockObjectivesHUD(Game::May, this);
		UnblockObjectivesHUD(Game::Cody, this);

		if (bEnableFoghornMinigameMode)
			SetFoghornMinigameModeEnabled(false);

		OnHideGameHUD.Broadcast();
	}

	UFUNCTION()
	void ShowHighScoreOnVictory()
	{
		if (bShowHighScoreDefault && ScoreHud != nullptr)
		{
			ScoreHud.SetHighScoreVisibility(true);
			ScoreHud.SetHighScoreVisuals(true);
		}
	}

	UFUNCTION()
	void HideAllHud()
	{
		bGameHudIsActive = false;

		if (ScoreHud == nullptr)
			return;

		ScoreHud.SetHighScoreVisuals(false);

		if (bShowScoreBoxesDefault)
			ScoreHud.SetScoreBoxVisibility(false);

		if (bShowTimerDefault)
			ScoreHud.ShowTimeCounter(false);

		if (ScoreData.ScoreMode == EScoreMode::Laps)
			ScoreHud.ShowLapsScore(false);
	}

	UFUNCTION()
	private void EndHud()
	{
		if(ScoreHud != nullptr)
		{
			HideAllHud();
			System::SetTimer(this, n"RemoveHud", 2.f, false);
		}
	}
	
	UFUNCTION()
	private void RemoveHud()
	{
		if (ScoreHud != nullptr && PlayersInRange <= 0)
		{
			Widget::RemoveFullscreenWidget(ScoreHud);
			ScoreHud = nullptr;
		}
	}

	UFUNCTION()
	void EnterMinigameCreateHud()
	{
		if(ScoreHud != nullptr)
			Widget::RemoveFullscreenWidget(ScoreHud);

		ScoreHud = Cast<UScoreHud>(Widget::AddFullscreenWidget(ScoreHudClass, EHazeWidgetLayer::Gameplay));
		ScoreHud.SetupScore(ScoreData);
		ScoreHud.OnScoreBoxVisibilityChanged.AddUFunction(this, n"OnToggleScoreboxVisiblity");
		ScoreHud.SetMinigameName(ScoreData.MinigameName, bGameHasBeenDiscovered);
		ScoreHud.ShowTimeCounter(false);
		ScoreHud.SetScoreBoxVisibility(false);
		ScoreHud.SetDiscoveryHudAlreadyOff();
	}

	UFUNCTION()
	void ShowHighScore()
	{
		ScoreHud.ShowHighScore(true);
		ScoreHud.SetupScore(ScoreData);		
	}

	UFUNCTION()
	void RemoveDiscoveryHud()
	{
		if(ScoreHud != nullptr)
			ScoreHud.RemoveOnDiscoveryHud();
	}

	UFUNCTION()
	void SetCountdownFinishedText(FText Text)
	{
		if (ScoreHud != nullptr)
			ScoreHud.SetCountdownFinishedText(Text);
	}

	UFUNCTION()
	void AddPlayerCapabilitySheets()
	{
		if (bPlayersHaveSheet)
			return;

		if (PlayerCapabilitySheet == nullptr)
			return;

		Game::GetMay().AddCapabilitySheet(PlayerCapabilitySheet, EHazeCapabilitySheetPriority::High);
		Game::GetCody().AddCapabilitySheet(PlayerCapabilitySheet, EHazeCapabilitySheetPriority::High);
	
		bPlayersHaveSheet = true;
	}

	UFUNCTION()
	void RemovePlayerCapabilitySheets()
	{
		if (!bPlayersHaveSheet)
			return;

		if (PlayerCapabilitySheet == nullptr)
			return;

		Game::GetMay().RemoveCapabilitySheet(PlayerCapabilitySheet);
		Game::GetCody().RemoveCapabilitySheet(PlayerCapabilitySheet);

		bPlayersHaveSheet = false;
	} 

	void ResetScoreBoth()
	{
		ScoreData.MayScore = StartingScore;
		ScoreData.CodyScore = StartingScore;

		ScoreHud.ResetScoreMay(ScoreData.MayScore);
		ScoreHud.ResetScoreCody(ScoreData.CodyScore);
	}

	void ResetScore(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
		{
			ScoreData.MayScore = StartingScore;

			if (ScoreHud != nullptr)
				ScoreHud.ResetScoreMay(ScoreData.MayScore);
		}
		else
		{
			ScoreData.CodyScore = StartingScore;

			if (ScoreHud != nullptr)
				ScoreHud.ResetScoreCody(ScoreData.MayScore);
		}
	}

	UFUNCTION()
	void SetScore(AHazePlayerCharacter Player, float Score)
	{
		if (Player == Game::GetMay())
		{
			ScoreData.MayScore = Score;
			
			if (ScoreHud != nullptr)
			{
				if (ScoreData.ScoreMode == EScoreMode::Laps && ScoreData.MayScore > ScoreData.ScoreLimit)
					ScoreHud.SetMayScore(ScoreData.ScoreLimit);
				else
					ScoreHud.SetMayScore(ScoreData.MayScore);
			}
		}
		else
		{
			ScoreData.CodyScore = Score;
			
			if (ScoreHud != nullptr)
			{
				if (ScoreData.ScoreMode == EScoreMode::Laps && ScoreData.CodyScore > ScoreData.ScoreLimit)
					ScoreHud.SetCodyScore(ScoreData.ScoreLimit);			
				else
					ScoreHud.SetCodyScore(ScoreData.CodyScore);			
			}
		}

		if (bCanScoreAudioEvent)
		{
			OnScoreChangeEvent.Broadcast(Player, Score);
			ScoreChangeEventTimer();
		}
	}

	UFUNCTION()
	void AdjustScore(AHazePlayerCharacter Player, float Score = 1, bool bCanGoNegative = false)
	{
		if (Player.IsCody())
		{
			if (!bCanGoNegative && ScoreData.CodyScore <= 0)
				ScoreData.CodyScore = 0;

			ScoreData.CodyScore += Score;
			
			if (ScoreHud != nullptr)
			{
				if (ScoreData.ScoreMode == EScoreMode::Laps && ScoreData.CodyScore > ScoreData.ScoreLimit)
					ScoreHud.SetCodyScore(ScoreData.ScoreLimit);			
				else
					ScoreHud.SetCodyScore(ScoreData.CodyScore);			
			}
		}
		else
		{
			if (!bCanGoNegative && ScoreData.MayScore <= 0)
				ScoreData.MayScore = 0;

			ScoreData.MayScore += Score;
			
			if (ScoreHud != nullptr)
			{
				if (ScoreData.ScoreMode == EScoreMode::Laps && ScoreData.MayScore > ScoreData.ScoreLimit)
					ScoreHud.SetMayScore(ScoreData.ScoreLimit);
				else
					ScoreHud.SetMayScore(ScoreData.MayScore);
			}
		} 

		if (bCanScoreAudioEvent)
		{
			OnScoreChangeEvent.Broadcast(Player, Score);
			ScoreChangeEventTimer();
		}
	}

	UFUNCTION()
	void ScoreChangeEventTimer()
	{
		CurrentScoreEventTimer = DefaultScoreEventTimer;
		bCanScoreAudioEvent = false;
	}

	UFUNCTION()
	void RunScoreEventTimer(float DeltaTime)
	{
		if (!bCanScoreAudioEvent)
		{
			CurrentScoreEventTimer -= DeltaTime;

			if (CurrentScoreEventTimer <= 0.f)
				bCanScoreAudioEvent = true;
		}
	}

	UFUNCTION()
	void OnToggleScoreboxVisiblity(bool bShouldShow)
	{
		OnShowHideScoreBoxes.Broadcast(bShouldShow);
	}

	UFUNCTION()
	float GetMayScore()
	{
		return ScoreData.MayScore;
	}

	UFUNCTION()
	float GetCodyScore()
	{
		return ScoreData.CodyScore;
	}

	void SetWinningThenLosingPlayer(EMinigameWinner WinState)
	{
		switch(WinState)
		{
			case EMinigameWinner::May:
				WinningPlayer = Game::May;
				LosingPlayer = Game::Cody;	
				if (bDeathOnVictoryCheck)
					System::SetTimer(this, n"DelayedPlayWinVOMay", 1.f, false);
				else
					MinigameVOPlayWin(Game::May, MinigameTag, VOLevelBank, VOGenericBank);
			break;

			case EMinigameWinner::Cody: 
				WinningPlayer = Game::Cody;
				LosingPlayer = Game::May;		
				if (bDeathOnVictoryCheck)
					System::SetTimer(this, n"DelayedPlayWinVOCody", 1.f, false);
				else
					MinigameVOPlayWin(Game::Cody, MinigameTag, VOLevelBank, VOGenericBank);
			break;

			case EMinigameWinner::Draw:
				WinningPlayer = nullptr;
				LosingPlayer = nullptr;	
				if (drawPlayIndex == 0)
				{
					drawPlayIndex = 1;
					MinigameVOPlayGenericDraw(VOGenericBank, true);
				}
				else
				{
					drawPlayIndex = 0;
					MinigameVOPlayGenericDraw(VOGenericBank, false);
				}
			break;
		}
	}

	UFUNCTION()
	void DelayedPlayWinVOMay()
	{
		MinigameVOPlayWin(Game::May, MinigameTag, VOLevelBank, VOGenericBank);
	}

	UFUNCTION()
	void DelayedPlayWinVOCody()
	{
		MinigameVOPlayWin(Game::Cody, MinigameTag, VOLevelBank, VOGenericBank);
	}
	/* If TotalScore or FirstTo score modes, will returning currently winning player. Otherwise, this will only return the winning or losing player after AnnounceWinner 
	 and before the next game is started when ShowGameHud is called. */
	AHazePlayerCharacter GetCurrentlyWinningPlayer()
	{
		if (WinningPlayer == nullptr)
		{
			if (ScoreData.ScoreMode == EScoreMode::TotalScore || ScoreData.ScoreMode == EScoreMode::FirstTo)
			{
				if (ScoreData.CodyScore > ScoreData.MayScore)
					return Game::Cody;
				else if (ScoreData.MayScore > ScoreData.CodyScore)
					return Game::May;
				else if (ScoreData.MayScore == ScoreData.CodyScore)
					return nullptr;
			}

			return nullptr;
		}

		return WinningPlayer;
	}

	/* If TotalScore or FirstTo score modes, will returning currently losing player. Otherwise, this will only return the winning or losing player after AnnounceWinner 
	 and before the next game is started when ShowGameHud is called. */
	AHazePlayerCharacter GetLosingPlayer()
	{
		if (LosingPlayer == nullptr)
		{
			if (ScoreData.ScoreMode == EScoreMode::TotalScore || ScoreData.ScoreMode == EScoreMode::FirstTo)
			{
				if (ScoreData.CodyScore > ScoreData.MayScore)
					return Game::May;
				else if (ScoreData.MayScore > ScoreData.CodyScore)
					return Game::Cody;
				else if (ScoreData.MayScore == ScoreData.CodyScore)
					return nullptr;
			}

			return nullptr;		
		}

		return LosingPlayer;		
	}

	void AnnounceWinner()
	{
		if (ScoreData.CodyScore > ScoreData.MayScore)
			ShowWinnerAndSetHighScore(EMinigameWinner::Cody);
		else if (ScoreData.MayScore > ScoreData.CodyScore)
			ShowWinnerAndSetHighScore(EMinigameWinner::May);
		else if (ScoreData.MayScore == ScoreData.CodyScore)
			ShowWinnerAndSetHighScore(EMinigameWinner::Draw);

		StopTimer();
	}

	void AnnounceWinner(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
			ShowWinnerAndSetHighScore(EMinigameWinner::Cody);
		else if (Player == Game::GetMay()) 
			ShowWinnerAndSetHighScore(EMinigameWinner::May);

		StopTimer();

		WinningPlayer = Player;
	}

	void AnnounceWinner(EMinigameWinner Winner)
	{
		ShowWinnerAndSetHighScore(Winner);
		StopTimer();
	}

	UFUNCTION()
	void BP_AnnounceWinner(EMinigameWinner Winner)
	{
		ShowWinnerAndSetHighScore(Winner);
		StopTimer();
	}

	UFUNCTION()
	void WinnerEventCall()
	{
		OnMinigameVictoryScreenFinished.Broadcast();
	}

	UFUNCTION()
	void VictoryAnimationComplete(AHazePlayerCharacter Player)
	{
		PlayerCompleteVictoryAnimation++;

		if (Player == Game::May)
			OnMayReactionComplete.Broadcast();
		else
			OnCodyReactionComplete.Broadcast();
			
		if (PlayerCompleteVictoryAnimation >= 2)
		{
			PlayerCompleteVictoryAnimation = 0;
			OnEndMinigameReactionsComplete.Broadcast();

			PlayerMinigameComps[0].OnMinigameReactionAnimationComplete.Clear();
			PlayerMinigameComps[1].OnMinigameReactionAnimationComplete.Clear();
		}
	}

	UFUNCTION()
	void PlayWinnerConfetti(AHazePlayerCharacter Player, EMinigameConfettiSettings Settings)
	{
		AHazePlayerCharacter Winner = WinningPlayer;

		FVector PlayerLocation = Player.ActorLocation;

		UHazeCameraComponent CamComp = UHazeCameraComponent::Get(Player);

		FVector CameraLoc = CamComp.ViewLocation;
		FVector CamDirectionToPlayer = PlayerLocation - CameraLoc;
		CamDirectionToPlayer.Normalize(); 

		FVector CamForwardLocation = Winner.ViewLocation + (CamDirectionToPlayer * 100.f);

		float PlayerCameraDistance = (PlayerLocation - CameraLoc).Size();
		PlayerCameraDistance = FMath::Abs(PlayerCameraDistance);
		PlayerCameraDistance *= 1.2f;

		FVector SpawnLoc = FVector(0.f); 
		FRotator SpawnRot = FRotator(0.f);

		UHazeAkComponent::HazePostEventFireForget(PlayWinnerConfettiAudioEvent, FTransform()); 

		if (Settings == EMinigameConfettiSettings::AbovePlayer)
		{
			SpawnLoc = Winner.ActorLocation + (FVector(0.f, 0.f, PlayerCameraDistance));
			SpawnRot = FRotator::MakeFromX(-Winner.ActorUpVector);
		}
		else
		{
			SpawnLoc = CamForwardLocation + (FVector(0.f, 0.f, 250.f));
			SpawnRot = FRotator::MakeFromX(-Winner.ActorUpVector);
		}

		if (Winner == Game::May)
			Niagara::SpawnSystemAtLocation(MayConfetti, SpawnLoc, SpawnRot);
		else
			Niagara::SpawnSystemAtLocation(CodyConfetti, SpawnLoc, SpawnRot);
	}

	UFUNCTION()
	void ActivateReactionAnimations(AHazePlayerCharacter Player)
	{
		UPlayerMinigameComponent PlayerMinigameComp;

		if (Player == Game::May)
			PlayerMinigameComp = PlayerMinigameComps[0];
		else
			PlayerMinigameComp = PlayerMinigameComps[1];

		if (Player == WinningPlayer && bPlayWinningAnimations)
		{
			PlayerMinigameComp.SetAnimationWinnerState(EMinigameAnimationPlayerState::WinnerAnim);
			PlayerMinigameComp.SetReactionState(EPlayerMinigameReactionState::Active);
			PlayWinnerConfetti(Player, ConfettiSettings);
		}
		else if (Player != WinningPlayer && bPlayLosingAnimations)
		{
			PlayerMinigameComp.SetAnimationWinnerState(EMinigameAnimationPlayerState::LoserAnim);
			PlayerMinigameComp.SetReactionState(EPlayerMinigameReactionState::Active);
		}
	}

	UFUNCTION()
	private void ShowWinnerAndSetHighScore(EMinigameWinner MinigameWinner)
	{
		if (ScoreHud == nullptr)
			return;

		SetWinningThenLosingPlayer(MinigameWinner);

		System::SetTimer(this, n"DelayedEndGameHud", 2.5f, false);
		ScoreHud.ShowWinner(MinigameWinner);
		OnMiniGameShowWinner.Broadcast();

		if (bMayAutoReactionAnimations)
		{
			if (MinigameWinner == EMinigameWinner::May && bPlayWinningAnimations)
			{
				ActivateReactionAnimations(Game::May);
			}
			if (MinigameWinner == EMinigameWinner::Cody && bPlayLosingAnimations)
			{
				ActivateReactionAnimations(Game::May);
			}
			else if (MinigameWinner == EMinigameWinner::Draw && bPlayDrawAnimations)
			{
				ActivateReactionAnimations(Game::May);
			}
		}
		
		if (bCodyAutoReactionAnimations)
		{
			if (MinigameWinner == EMinigameWinner::Cody && bPlayWinningAnimations)
			{
				ActivateReactionAnimations(Game::Cody);
			}
			if (MinigameWinner == EMinigameWinner::May && bPlayLosingAnimations)
			{
				ActivateReactionAnimations(Game::Cody);
			}
			else if (MinigameWinner == EMinigameWinner::Draw && bPlayDrawAnimations)
			{
				ActivateReactionAnimations(Game::Cody);
			}
		}

		System::SetTimer(this, n"WinnerEventCall", VictoryScreenTimer, false);

		if (ScoreData.HighScoreType == EHighScoreType::HighestScore)
		{
			if (ScoreData.MayScore > ScoreData.MayHighScore)
			{
				ScoreData.MayHighScore = ScoreData.MayScore; 

				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(MayHighScoreData, ScoreData.MayHighScore, Type = EHazeSaveDataType::MinigameLocal);
			}

			if (ScoreData.CodyScore > ScoreData.CodyHighScore)
			{
				ScoreData.CodyHighScore = ScoreData.CodyScore; 
				
				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(CodyHighScoreData, ScoreData.CodyHighScore, Type = EHazeSaveDataType::MinigameLocal);
			}
		}
			
		if (ScoreData.HighScoreType == EHighScoreType::RoundsWon)
		{
			if (MinigameWinner == EMinigameWinner::May)
			{
				ScoreData.MayHighScore += 1;
			
				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(MayHighScoreData, ScoreData.MayHighScore, Type = EHazeSaveDataType::MinigameLocal);
			}
			else if (MinigameWinner == EMinigameWinner::Cody)
			{
				ScoreData.CodyHighScore += 1;

				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(CodyHighScoreData, ScoreData.CodyHighScore, Type = EHazeSaveDataType::MinigameLocal);
			}
		}

		if (ScoreData.HighScoreType == EHighScoreType::TimeElapsed)
		{
			if (ScoreData.MayHighScore != 0)
			{
				if (ScoreData.MayScore < ScoreData.MayHighScore)
					ScoreData.MayHighScore = ScoreData.MayScore;
			}
			else 
			{
				if (MinigameWinner == EMinigameWinner::May)
					ScoreData.MayHighScore = ScoreData.MayScore;
				else
					ScoreData.MayHighScore = ScoreData.DefaultHighscoreTimer;
			}

			if (ScoreData.CodyHighScore != 0)
			{
				if (ScoreData.CodyScore < ScoreData.CodyHighScore)
					ScoreData.CodyHighScore = ScoreData.CodyScore;
			}
			else
			{
				if (MinigameWinner == EMinigameWinner::Cody)
					ScoreData.CodyHighScore = ScoreData.CodyScore;
				else
					ScoreData.CodyHighScore = ScoreData.DefaultHighscoreTimer;
			}
			
			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileCounter(MayHighScoreData, ScoreData.MayHighScore, Type = EHazeSaveDataType::MinigameLocal);			
	
			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileCounter(CodyHighScoreData, ScoreData.CodyHighScore, Type = EHazeSaveDataType::MinigameLocal);				
		}

		switch (MinigameWinner)
		{
			case EMinigameWinner::May:
				MenuScores.MayWins++;
				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(MayWinsData, MenuScores.MayWins, Type = EHazeSaveDataType::MinigameLocal);
			break;

			case EMinigameWinner::Cody:
				MenuScores.CodyWins++;
				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(CodyWinsData, MenuScores.CodyWins, Type = EHazeSaveDataType::MinigameLocal);
			break;

			case EMinigameWinner::Draw:
				MenuScores.Draws++;
				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(DrawData, MenuScores.Draws, Type = EHazeSaveDataType::MinigameLocal);
			break;
		}

		ScoreHud.SetMayHighScore(ScoreData.MayHighScore);
		ScoreHud.SetCodyHighScore(ScoreData.CodyHighScore);
	}

	UFUNCTION()
	void DelayedEndGameHud()
	{
		if (bPlayersInRange)
		{
			EndGameHud();

			if (bCanDeactivateGameHud)
			{
				if (MayInRange == 1)
					SetWidgetAnchorPoint(Game::May);
				else if (CodyInRange == 1)	
					SetWidgetAnchorPoint(Game::Cody);
			}
		}
		else
			EndHud();
	}

	UFUNCTION()
	void ActivateTutorial()
	{
		CheckCountDownBinding();
		
		if (ScoreHud == nullptr)
		{
			devEnsure(false, " ScoreHud is Nullptr. Ensure that EnterMinigameAreaVolumes and HudAreaVolumes volumes are referenced properly so that ScoreHud can be created");
			return;
		}

		if (!bGameHasBeenDiscovered)
			devEnsure(false, "bGameHasBeenDiscovered returns false. Ensure that the minigame can be discovered before players are able to interact with it");
		
		System::SetTimer(this, n"DelayedActivateTutorial", 0.3f, false);
		
		bEnteredTutorialMode = true;

		if (!bMayBlocked)
			BlockPlayerTags(Game::May);
		
		if (!bCodyBlocked)
			BlockPlayerTags(Game::Cody);

		ScoreHud.SetHighScoreVisuals(false);

		BlockObjectivesHUD(Game::May, this);
		BlockObjectivesHUD(Game::Cody, this);
	}

	UFUNCTION()
	private void DelayedActivateTutorial()
	{
		if (!bEnteredTutorialMode)
			return;

		ScoreHud.ShowTutorialWindow();

		ScoreHud.BP_SetTutorialMay(TutorialPromptsMay, TutorialInstructionsMay);
		ScoreHud.BP_SetTutorialCody(TutorialPromptsCody, TutorialInstructionsCody);

		Game::May.AddCapabilitySheet(TutorialCapabilitySheet, Instigator = this);
		Game::Cody.AddCapabilitySheet(TutorialCapabilitySheet, Instigator = this);

		MayTutorialComp = UPlayerMinigameTutorialComponent::Get(Game::May);
		CodyTutorialComp = UPlayerMinigameTutorialComponent::Get(Game::Cody);

		MayTutorialComp.OnTutorialCancelFromPlayer.Clear();
		CodyTutorialComp.OnTutorialCancelFromPlayer.Clear();
		MayTutorialComp.OnMinigamePlayerReady.Clear();
		CodyTutorialComp.OnMinigamePlayerReady.Clear();

		MayTutorialComp.OnMinigamePlayerReady.AddUFunction(this, n"PlayerCheckTutorialReady");
		CodyTutorialComp.OnMinigamePlayerReady.AddUFunction(this, n"PlayerCheckTutorialReady");
		MayTutorialComp.OnTutorialCancelFromPlayer.AddUFunction(this, n"PlayerCancelledTutorial");
		CodyTutorialComp.OnTutorialCancelFromPlayer.AddUFunction(this, n"PlayerCancelledTutorial");

		OnMinigameTutorialStarted.Broadcast();
	}

	UFUNCTION()
	void PlayerCheckTutorialReady(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
		{
			ScoreHud.PlayerReadyMay();
			bMayReady = true;
		}
		else
		{
			ScoreHud.PlayerReadyCody();
			bCodyReady = true;	
		}

		OnTutorialPlayerReady.Broadcast(Player);

		if (!bEnteredTutorialMode)
			return;

		if (HasControl())
		{
			if (bCodyReady && bMayReady)
			{
				NetTutorialBothPlayersReady();
				bCodyReady = false;
				bMayReady = false;
			}
		}
	}

	UFUNCTION()
	void PlayerCancelledTutorial(AHazePlayerCharacter Player)
	{
		if (HasControl())
		{
			if (bEnteredTutorialMode)
				NetPlayerCancelled(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayerCancelled(AHazePlayerCharacter Player)
	{
		OnTutorialCancelFromPlayer.Broadcast(Player);
		OnTutorialCancel.Broadcast();
		
		bEnteredTutorialMode = false;

		RemoveTutorialOnGenericCancel();
		
		MayTutorialComp = UPlayerMinigameTutorialComponent::Get(Game::May);
		CodyTutorialComp = UPlayerMinigameTutorialComponent::Get(Game::Cody);

		ScoreHud.SetHighScoreVisuals(true);

		if (bShowHighScoreDefault && bHavePlayed)
		{
			ScoreHud.SetHighScoreVisibility(true);
			ScoreHud.SetHighScoreVisuals(true);
		}

		if (bMayBlocked)
			UnblockPlayerMovementTags(Game::May);

		if (bCodyBlocked)
			UnblockPlayerMovementTags(Game::Cody);

		Game::May.RemoveCapabilitySheet(TutorialCapabilitySheet, this);
		Game::Cody.RemoveCapabilitySheet(TutorialCapabilitySheet, this);

		bCodyReady = false;
		bMayReady = false;

		UnblockObjectivesHUD(Game::May, this);
		UnblockObjectivesHUD(Game::Cody, this);
	}

	UFUNCTION(NetFunction)
	void NetTutorialBothPlayersReady()
	{
		if (!bEnteredTutorialMode)
			return;

		StopFoghorn();

		if (bEnableFoghornMinigameMode)
			SetFoghornMinigameModeEnabled(true);

		ResumeFoghorn();

		if (!bHavePlayed)
		{
			MinigameVOPlayStart(VOLevelBank, MinigameTag);
		}
		else
		{
			int r = FMath::RandRange(0, 1);
			
			if (r == 0)
				MinigameVOPlayGenericStart(VOGenericBank, Game::May);
			else
				MinigameVOPlayGenericStart(VOGenericBank, Game::Cody);
		}

		System::SetTimer(this, n"DelayedTutorialComplete", 1.2f, false);

		bEnteredTutorialMode = false;
	}

	UFUNCTION()
	void DelayedTutorialComplete()
	{
		ScoreHud.HideTutorialWindow();

		if (bMayBlocked)
			UnblockPlayerMovementTags(Game::May);
			
		if (bCodyBlocked)
			UnblockPlayerMovementTags(Game::Cody);

		Game::May.RemoveCapabilitySheet(TutorialCapabilitySheet, this);
		Game::Cody.RemoveCapabilitySheet(TutorialCapabilitySheet, this);

		OnMinigameTutorialComplete.Broadcast();
	}

	UFUNCTION()
	void RemoveTutorialOnGenericCancel()
	{
		ScoreHud.HideTutorialWindow();
		ScoreHud.ShowHighScore(true);
	}

	UFUNCTION()
	void StartCountDown()
	{
		System::SetTimer(this, n"DelayedStartCountdown", 0.65f, false);
	
		PlayerMinigameComps[0].bMinigameActive = true;
		PlayerMinigameComps[1].bMinigameActive = true;

		if (HasControl() && TambourineCharacter != nullptr)
			NetDeactivateTambourineCharacter();
			
		if (!bHavePlayed)
		{
			bHavePlayed = true;


			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileFlag(EHazeSaveDataType::MinigameLocal, HavePlayedData, bHavePlayed);
		}
	}

	UFUNCTION()
	private void DelayedStartCountdown()
	{
		if (ScoreHud == nullptr)
			EnterMinigameCreateHud();

		// if (ScoreData.ScoreMode != EScoreMode::Laps)
		ScoreHud.SetHighScoreVisuals(false);
		
		if (bShowScoreBoxesDefault)
			ScoreHud.SetScoreBoxVisibility(false);
		if (bShowTimerDefault)
			ScoreHud.ShowTimeCounter(false);

		bCanCountDown = true;
		bShowTimerDuringCountdown = true;
		CountDownSeconds = MaxCountDownSeconds;

		if (ScoreHud != nullptr)
		{
			ScoreHud.StartCountdown(); 
			OnCountdownStartedEvent.Broadcast();
		}
	}

	UFUNCTION()
	void SetTimer(float Time)
	{
		if (bReversedTimer)
			CurrentTimer = 0.f;
		else
			CurrentTimer = Time;

		ScoreData.Timer = Time;
		
		if (ScoreHud != nullptr)
			ScoreHud.SetTime(CurrentTimer); 
	}

	void StartTimer()
	{
		if (bReversedTimer)
			CurrentTimer = 0.f;
		else
			CurrentTimer = ScoreData.Timer;

		bCanTimer = true;
	}

	void StartTimer(float MaxTimervalue)
	{
		if (bReversedTimer)
		{
			CurrentTimer = 0.f;
			ScoreData.Timer = MaxTimervalue;
		}
		else
		{
			CurrentTimer = MaxTimervalue;
		}

		bCanTimer = true;
	}

	UFUNCTION()
	void BP_StartTimer(float MaxTimervalue)
	{
		if (bReversedTimer)
		{
			CurrentTimer = 0.f;
			ScoreData.Timer = MaxTimervalue;
		}
		else
		{
			CurrentTimer = MaxTimervalue;
		}

		bCanTimer = true;
	}

	UFUNCTION()
	void StopTimer(bool bResetTimeValue = false)
	{
		if (ScoreHud != nullptr && bResetTimeValue)
			ScoreHud.SetTime(0.f);
		
		bCanTimer = false;
	}
	
	UFUNCTION()
	float GetTimerValue()
	{
		return CurrentTimer;
	}

	UFUNCTION()
	float GetCountDownValue()
	{
		return CountDownSeconds;
	}

	UFUNCTION()
	private void TimerUp(float DeltaTime)
	{
		CurrentTimer += DeltaTime;

		if (ScoreHud != nullptr)
			ScoreHud.SetTime(CurrentTimer);

		if (CurrentTimer >= ScoreData.Timer)
		{
			CurrentTimer = ScoreData.Timer;

			if (ScoreHud != nullptr)
				ScoreHud.SetTime(ScoreData.Timer);

			bCanTimer = false;

			OnTimerCompletedEvent.Broadcast();
		}
	}

	UFUNCTION()
	private void TimerDown(float DeltaTime)
	{
		CurrentTimer -= DeltaTime;

		if (ScoreHud != nullptr)
			ScoreHud.SetTime(CurrentTimer);

		if (CurrentTimer <= 0.f)
		{
			CurrentTimer = 0.f;

			if (ScoreHud != nullptr)
				ScoreHud.SetTime(CurrentTimer);

			bCanTimer = false;
			
			OnTimerCompletedEvent.Broadcast();
		}
	}

//*** LAP FUNCTIONS ***//

	UFUNCTION()
	void ShowLapsScoreBox(bool ShouldShow) 
	{
		if (ScoreHud != nullptr)
			ScoreHud.ShowLapsScore(ShouldShow);

		LoadLapTimes();
	}

	UFUNCTION()
	void UpdateCurrentLapTimes(float DeltaTime)
	{
		// if (ScoreHud == nullptr)
		// 	return;

		CurrentMayLapTime += DeltaTime;
		CurrentCodyLapTime += DeltaTime;

		ScoreHud.UpdateCurrentMayLapTime(CurrentMayLapTime);
		ScoreHud.UpdateCurrentCodyLapTime(CurrentCodyLapTime);
	}

	UFUNCTION()
	void LoadLapTimes()
	{
		// if (ScoreHud == nullptr)
		// 	return;
		
		CurrentMayLapTime = 0.f;
		CurrentCodyLapTime = 0.f;

		ScoreHud.UpdateCurrentMayLapTime(CurrentMayLapTime);
		ScoreHud.UpdateCurrentCodyLapTime(CurrentCodyLapTime);

		ScoreHud.UpdateMayBestLaps(ScoreData.MayBestLap);
		ScoreHud.UpdateCodyBestLaps(ScoreData.CodyBestLap);
		ScoreHud.UpdateMayLastLaps(ScoreData.MayLastLap);
		ScoreHud.UpdateCodyLastLaps(ScoreData.CodyLastLap);
	}

	UFUNCTION()
	void SetBestAndLastLapTimes(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
		{
			ScoreData.MayLastLap = CurrentMayLapTime;
			ScoreHud.UpdateMayLastLaps(ScoreData.MayLastLap);

			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileCounter(MayLastLapData, ScoreData.MayLastLap, Type = EHazeSaveDataType::MinigameLocal);

			if (CurrentMayLapTime < ScoreData.MayBestLap || ScoreData.MayBestLap == 0.f)
			{
				ScoreData.MayBestLap = CurrentMayLapTime;
				ScoreHud.UpdateMayBestLaps(ScoreData.MayBestLap);

				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(MayBestLapData, ScoreData.MayBestLap, Type = EHazeSaveDataType::MinigameLocal);
			}

			CurrentMayLapTime = 0.f;
		}
		else
		{
			ScoreData.CodyLastLap = CurrentCodyLapTime;
			ScoreHud.UpdateCodyLastLaps(ScoreData.CodyLastLap);
			
			if (Save::CanAccessProfileData())
				Save::ModifyPersistentProfileCounter(CodyLastLapData, ScoreData.CodyLastLap, Type = EHazeSaveDataType::MinigameLocal);

			if (CurrentCodyLapTime < ScoreData.CodyBestLap || ScoreData.CodyBestLap == 0.f)
			{
				ScoreData.CodyBestLap = CurrentCodyLapTime;
				ScoreHud.UpdateCodyBestLaps(ScoreData.CodyBestLap);

				if (Save::CanAccessProfileData())
					Save::ModifyPersistentProfileCounter(CodyBestLapData, ScoreData.CodyBestLap, Type = EHazeSaveDataType::MinigameLocal);
			}

			CurrentCodyLapTime = 0.f;
		}
	}

//*** DOUBLE TIMER FUNCTIONS ***//

	UFUNCTION()
	void SetClockIconVisibilityMay(bool Value)
	{
		if (ScoreHud != nullptr)
			ScoreHud.SetClockIconVisibilityMay(Value);
	}

	UFUNCTION()
	void SetClockIconVisibilityCody(bool Value)
	{
		if (ScoreHud != nullptr)
			ScoreHud.SetClockIconVisibilityCody(Value);
	}

	UFUNCTION()
	void UpdateDoubleTime(float Value, AHazePlayerCharacter Player)
	{
		int Minutes = 0.f;
		int Seconds = 0.f;
		float Milliseconds = 0.f;

		float MinutesWithDecimals = Value / 60.f;
		Minutes = FMath::TruncToInt(MinutesWithDecimals);

		if (Minutes > 0.f)
		{
			float Remainder = MinutesWithDecimals - Minutes;
			float GetSecondsMultiplier = Remainder / MinutesWithDecimals;
			Seconds = Value * GetSecondsMultiplier;
		}
		else
		{
			Seconds = FMath::Abs(Value);
		}
		
		if (ScoreHud != nullptr && Player == Game::May)
			ScoreHud.UpdateDoubleTimeMay(Minutes, Seconds);
		else if (ScoreHud != nullptr && Player == Game::Cody)
			ScoreHud.UpdateDoubleTimeCody(Minutes, Seconds);
	}

	UFUNCTION()
	void InitializeTime(float Value)
	{
		int Minutes = 0.f;
		int Seconds = 0.f;
		float Milliseconds = 0.f;

		float MinutesWithDecimals = Value / 60.f;
		Minutes = FMath::TruncToInt(MinutesWithDecimals);

		if (Minutes > 0.f)
		{
			float Remainder = MinutesWithDecimals - Minutes;
			float GetSecondsMultiplier = Remainder / MinutesWithDecimals;
			Seconds = Value * GetSecondsMultiplier;
		}
		else
		{
			Seconds = FMath::Abs(Value);
		}

		if (ScoreHud != nullptr)
		{
			ScoreHud.UpdateDoubleTimeMay(Minutes, Seconds);
			ScoreHud.UpdateDoubleTimeCody(Minutes, Seconds);
		}
	}

//*** SHOW IN GAME ROUND FUNCTIONS ***//

	UFUNCTION()
	void PlayMessageAnimation(FText Text)
	{
		if (ScoreHud != nullptr)
			ScoreHud.BP_PlayMessageAnimation(Text);
	}

//*** Minigame Rounds ***//

//*** IN WORLD WIDGET ***//
	UMinigameInGameText CreateWidget(UMinigameInGameText InWidget, AHazePlayerCharacter Player, TArray<UMinigameInGameText>& WidgetPool)
	{
		if (WidgetPool.Num() == 0)
		{
			InWidget = Cast<UMinigameInGameText>(Player.AddWidget(InWorldWidgetClass));
			WidgetPool.Add(InWidget);
			return InWidget;
		}
		else
		{
			for (UMinigameInGameText ThisWidget : WidgetPool)
			{
				if (!ThisWidget.IsVisible())
				{
					InWidget = Cast<UMinigameInGameText>(Player.AddWidget(InWorldWidgetClass));
					return InWidget;
				}
			}

			InWidget = Cast<UMinigameInGameText>(Player.AddWidget(InWorldWidgetClass));
			WidgetPool.Add(InWidget);
			return InWidget;
		}
	}

	UFUNCTION()
	void CreateMinigameWorldWidgetText(
		EMinigameTextPlayerTarget MinigameTextPlayerTarget, 
		FString InputString,
		FVector SpawnLocation,
		FMinigameWorldWidgetSettings WidgetSettings
		)
	{
		TPerPlayer<UMinigameInGameText> Widgets;

		if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::Both)
		{
			Widgets[0] = CreateWidget(Widgets[0], Game::May, MayWidgetPool);
			Widgets[1] = CreateWidget(Widgets[1], Game::Cody, CodyWidgetPool);
		}
		else if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::May)
		{
			Widgets[0] = CreateWidget(Widgets[0], Game::May, MayWidgetPool);
		}
		else if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::Cody)
		{
			Widgets[1] = CreateWidget(Widgets[1], Game::Cody, CodyWidgetPool);
		}
		
		for (UMinigameInGameText Widget : Widgets)
		{
			if (Widget == nullptr)
				continue;

			Widget.SpawnLocation = SpawnLocation;
			Widget.TimeDuration = WidgetSettings.TimeDuration;
			Widget.FadeDuration = WidgetSettings.FadeDuration;
			Widget.MinigameTextMovementType = WidgetSettings.MinigameTextMovementType;
			Widget.TargetHeight = WidgetSettings.TargetHeight;
			Widget.MoveSpeed = WidgetSettings.MoveSpeed;
			Widget.MinigameTextColor = WidgetSettings.MinigameTextColor;
			Widget.SetTextValue(InputString);
			Widget.Start(EInGameTextJuice::SmallChange);
		}
	}

	UFUNCTION()
	void CreateMinigameWorldWidgetNumber(
		EMinigameTextPlayerTarget MinigameTextPlayerTarget, 
		float InputNumber,
		FVector SpawnLocation,
		FMinigameWorldWidgetSettings WidgetSettings
		)
	{
		TPerPlayer<UMinigameInGameText> Widgets;

		if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::Both)
		{
			Widgets[0] = CreateWidget(Widgets[0], Game::May, MayWidgetPool);
			Widgets[1] = CreateWidget(Widgets[1], Game::Cody, CodyWidgetPool);
		}
		else if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::May)
		{
			Widgets[0] = CreateWidget(Widgets[0], Game::May, MayWidgetPool);
		}
		else if (MinigameTextPlayerTarget == EMinigameTextPlayerTarget::Cody)
		{
			Widgets[1] = CreateWidget(Widgets[1], Game::Cody, CodyWidgetPool);
		}

		for (UMinigameInGameText Widget : Widgets)
		{
			if (Widget == nullptr)
				continue;

			Widget.SpawnLocation = SpawnLocation;
			Widget.TimeDuration = WidgetSettings.TimeDuration;
			Widget.FadeDuration = WidgetSettings.FadeDuration;
			Widget.MinigameTextMovementType = WidgetSettings.MinigameTextMovementType;
			Widget.TargetHeight = WidgetSettings.TargetHeight;
			Widget.MoveSpeed = WidgetSettings.MoveSpeed;
			Widget.MinigameTextColor = WidgetSettings.MinigameTextColor;
			Widget.SetTextValue(InputNumber);
			Widget.Start(EInGameTextJuice::SmallChange);
		}
	}

	void BlockPlayerTags(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(n"IceSkatingMovement", this);

		if (Player == Game::May)
			bMayBlocked = true;
		else
			bCodyBlocked = true;
	}

	void UnblockPlayerMovementTags(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(n"IceSkatingMovement", this);

		if (Player == Game::May)
			bMayBlocked = false;
		else
			bCodyBlocked = false;
	}

	//Plays Unique or Generic taunt based on priority and cooldown between the two. Unique gets priority first
	UFUNCTION()
	void PlayTauntAllVOBark(AHazePlayerCharacter Player)
	{
		MinigameVOPlayUniqueTaunt(Player, MinigameTag, VOLevelBank);
		MinigameVOPlayGenericTaunt(Player, VOGenericBank);
	}

	UFUNCTION()
	void PlayTauntUniqueVOBark(AHazePlayerCharacter Player)
	{
		MinigameVOPlayUniqueTaunt(Player, MinigameTag, VOLevelBank);
	}

	UFUNCTION()
	void PlayTauntGenericVOBark(AHazePlayerCharacter Player)
	{
		MinigameVOPlayGenericTaunt(Player, VOGenericBank);
	}

	UFUNCTION()
	void PlayFailGenericVOBark(AHazePlayerCharacter Player)
	{
		MinigameVOPlayGenericFail(Player, VOGenericBank);
	}

	UFUNCTION()
	void PlayPendingStartVOBark(AHazePlayerCharacter Player, FVector OtherInteractionLocation)
	{
		float DistanceFromOther = (OtherInteractionLocation - Player.OtherPlayer.ActorLocation).Size();

		if (DistanceFromOther >= MinPendingPlayDistance)
			MinigameVOPlayPendingStart(Player, VOGenericBank);
	}
}

UFUNCTION()
bool IsAnyMinigameActive()
{
	if (Game::May == nullptr || Game::Cody == nullptr)
		return false;

	UPlayerMinigameComponent MayComp = UPlayerMinigameComponent::Get(Game::May); 
	UPlayerMinigameComponent CodyComp = UPlayerMinigameComponent::Get(Game::Cody); 

	if (Game::May.IsAnyCapabilityActive(n"SlotCar") && Game::Cody.IsAnyCapabilityActive(n"SlotCar"))
		return true;

	if (MayComp == nullptr || CodyComp == nullptr)
		return false;

	if (MayComp.bMinigameActive && CodyComp.bMinigameActive)
		return true;
	else
		return false;
}