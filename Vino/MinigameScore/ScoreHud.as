import Vino.MinigameScore.MinigameStatics;
import Vino.MinigameScore.MinigameHighscore;
import Vino.MinigameScore.MinigameCountdown;
import Vino.MinigameScore.MinigameVictoryScreen;
import Vino.Tutorial.TutorialPrompt;

event void FOnScoreBoxVisibilityChange(bool bShouldShow);

enum EScoreHudPosition
{
	Centre,
	Left,
	Right
}

class UScoreHud : UHazeUserWidget
{
	private bool bShouldTickDestroyTimer = false;
	private float DestroyTimer = 0.f;

	UPROPERTY()
	bool ShouldShowTimer = true;
	
	UPROPERTY()
	bool ShouldShowHighScore = true;
	
	UPROPERTY()
	FString FirstToString;

	UPROPERTY()
	EScoreMode MainScoreMode;

	UPROPERTY()
	float OffsetLeftAnchor = 0.25f;

	UPROPERTY()
	float OffsetRightAnchor = 0.75f;

	float CurrentAnchor = 0.5f;

	bool ScoreVisible;
	bool LapsScoreVisible;

	EScoreHudPosition ScoreHudPosition;
	FOnScoreBoxVisibilityChange OnScoreBoxVisibilityChanged;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if (bShouldTickDestroyTimer)
		{
			DestroyTimer -= DeltaTime;

			if (DestroyTimer <= 0.f)
			{
				bShouldTickDestroyTimer = false;
				Widget::RemoveFullscreenWidget(this);
			}
		}

		switch(ScoreHudPosition)
		{
			case EScoreHudPosition::Centre: SetHeaderXPosition(0.5f, DeltaTime); break;
			case EScoreHudPosition::Left: SetHeaderXPosition(OffsetLeftAnchor, DeltaTime); break;
			case EScoreHudPosition::Right: SetHeaderXPosition(OffsetRightAnchor, DeltaTime); break;
		}
	}

	//*** HEADER POSITIONING ***//

	UFUNCTION(BlueprintEvent)
	private UVerticalBox BP_GetHeader() {return nullptr;}

	UFUNCTION(BlueprintEvent)
	private void BP_SetHeaderPosition(float AnchorXPos) {}

	UFUNCTION(BlueprintEvent)
	void SetHeaderXPosition(float TargetAnchorPos, float DeltaTime)
	{
		CurrentAnchor = FMath::FInterpConstantTo(CurrentAnchor, TargetAnchorPos, DeltaTime, 0.4f);
		BP_SetHeaderPosition(CurrentAnchor);
	}

	void SetHeaderTargetPosition(EScoreHudPosition HudPosition)
	{
		ScoreHudPosition = HudPosition;
	}

	void SnapHeadTargetPosition(EScoreHudPosition HudPosition)
	{
		ScoreHudPosition = HudPosition;

		if (ScoreHudPosition == EScoreHudPosition::Left)
			CurrentAnchor = OffsetLeftAnchor;
		else if (ScoreHudPosition == EScoreHudPosition::Right)
			CurrentAnchor = OffsetRightAnchor;
	}

//	/* - Sub Widget Functions - */
	// Getters Overridden in WBP

	UFUNCTION(BlueprintEvent)
	private UMinigameHighscore BP_GetHighScoreWidget() {return nullptr;}

	UFUNCTION(BlueprintEvent)
	private UMinigameCountdown BP_GetCountdownWidget() {return nullptr;}

	UFUNCTION(BlueprintEvent)
	private UMinigameVictoryScreen BP_GetVictoryScreenWidget(){return nullptr;}

	void BindToCountdownFinished(UObject Object, FName FunctionName)
	{
		UMinigameCountdown CountdownWidget = BP_GetCountdownWidget();

		if(CountdownWidget != nullptr)
			CountdownWidget.CountdownEvent.AddUFunction(Object, FunctionName);
	}

	void BindToVictoryScreenFinished(UObject Object, FName FunctionName)
	{
		UMinigameVictoryScreen VictoryScreenWidget = BP_GetVictoryScreenWidget();

		if(VictoryScreenWidget != nullptr)
			VictoryScreenWidget.VictoryScreenFinishedEvent.AddUFunction(Object, FunctionName);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetScoreBoxVisibility(bool ShouldShow){}

	UFUNCTION()
	void SetScoreBoxVisibility(bool ShouldShow)
	{
		if (!ShouldShow && ScoreVisible)
		{
			BP_SetScoreBoxVisibility(ShouldShow);
			ScoreVisible = ShouldShow;
			OnScoreBoxVisibilityChanged.Broadcast(false);
		}
		else if (ShouldShow && !ScoreVisible)
		{
			BP_SetScoreBoxVisibility(ShouldShow);
			ScoreVisible = ShouldShow;
			OnScoreBoxVisibilityChanged.Broadcast(true);
		}
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetupScore(FScoreHudData ScoreHudData) {}

	UFUNCTION()
	void SetupScore(FScoreHudData ScoreHudData)
	{
		BP_SetupScore(ScoreHudData);
	}

//	/* - Score Related Functions - */
	
	private UFUNCTION(BlueprintEvent)
	void BP_ResetScoreMay(float Score)	{}

	private UFUNCTION(BlueprintEvent)
	void BP_ResetScoreCody(float Score) {}

	UFUNCTION()
	void ResetScoreMay(float Score)
	{
		BP_ResetScoreMay(Score);
	}

	UFUNCTION()
	void ResetScoreCody(float Score)
	{
		BP_ResetScoreCody(Score);
	}
	
	private UFUNCTION(BlueprintEvent)
	void BP_SetMayScore(float MayScore) {}

	UFUNCTION()
	void SetMayScore(float MayScore)
	{
		BP_SetMayScore(MayScore);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetCodyScore(float CodyScore) {}

	UFUNCTION()
	void SetCodyScore(float CodyScore)
	{
		BP_SetCodyScore(CodyScore);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetFirstToValue(float ScoreLimit) {}

	UFUNCTION()
	void SetFirstToValue(float ScoreLimit)
	{
		BP_SetFirstToValue(ScoreLimit);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetScoreMode(EScoreMode ScoreMode) {}

	UFUNCTION()
	void SetScoreMode(EScoreMode ScoreMode)
	{
		BP_SetScoreMode(ScoreMode);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetMinigameName(FText MinigameName, bool GameDiscovered) {}

	UFUNCTION()
	void SetMinigameName(FText MinigameName, bool GameDiscovered)
	{
		BP_SetMinigameName(MinigameName, GameDiscovered);
	}

// /* - HighScore Related Functions - */
	
	private UFUNCTION(BlueprintEvent)
	void BP_SetHighScore(int HighScore) {}

	private UFUNCTION(BlueprintEvent)
	void BP_SetDiscoveryAlreadyOn() {};

	private UFUNCTION(BlueprintEvent)
	void BP_SetDiscoveryOnInstant() {};

	private UFUNCTION(BlueprintEvent)
	void BP_SetDiscoveryAlreadyOff() {};

	UFUNCTION()
	void SetDiscoveryHudAlreadyOn()
	{
		BP_SetDiscoveryAlreadyOn();
	}

	UFUNCTION()
	void SetDiscoveryHudOnInstant()
	{
		BP_SetDiscoveryOnInstant();
	}

	UFUNCTION()
	void SetDiscoveryHudAlreadyOff()
	{
		BP_SetDiscoveryAlreadyOff();
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetDiscoveryHudActivated() {};

	private UFUNCTION(BlueprintEvent)
	void BP_SetDiscoveryHudDeactivated() {};

	UFUNCTION()
	void ShowOnDiscoveryHud()
	{
		BP_SetDiscoveryHudActivated();
	}

	UFUNCTION()
	void RemoveOnDiscoveryHud()
	{
		BP_SetDiscoveryHudDeactivated();
	}

	UFUNCTION()
	void SetHighScore(int HighScore)
	{
		BP_SetHighScore(HighScore);
	}

	UFUNCTION()
	void SetCodyHighScore(int ScoreToSet)
	{
		UMinigameHighscore HighscoreWidget = BP_GetHighScoreWidget();

		if(HighscoreWidget != nullptr)
			HighscoreWidget.SetCodyHighScore(ScoreToSet);
	}

	UFUNCTION()
	void SetMayHighScore(int ScoreToSet)
	{
		UMinigameHighscore HighscoreWidget = BP_GetHighScoreWidget();

		if(HighscoreWidget != nullptr)
			HighscoreWidget.SetMayHighScore(ScoreToSet);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_ShowLapsScore(bool ShouldShow) {}

	UFUNCTION()
	void ShowLapsScore(bool ShouldShow)
	{
		if (ShouldShow && !LapsScoreVisible)
		{
			BP_ShowLapsScore(ShouldShow);
			LapsScoreVisible = true;
		}
		else if (!ShouldShow && LapsScoreVisible)
		{
			BP_ShowLapsScore(ShouldShow);
			LapsScoreVisible = false;
		}
	}

	UFUNCTION()
	void ShowHighScore(bool ShowHighScore)
	{
		UMinigameHighscore HighScoreWidget = BP_GetHighScoreWidget();

		if(HighScoreWidget != nullptr)
			HighScoreWidget.ShowHighScoreVisuals(ShowHighScore);
	}

	UFUNCTION()
	void SetHighScoreType(EHighScoreType ScoreType)
	{
		UMinigameHighscore HighScoreWidget = BP_GetHighScoreWidget();

		if(HighScoreWidget != nullptr)
			HighScoreWidget.SetHighScoreText(ScoreType);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_SetHighScoreVisibility(bool ShouldShow) {}

	UFUNCTION()
	void SetHighScoreVisibility(bool ShouldShow)
	{
		BP_SetHighScoreVisibility(ShouldShow);
	}

	UFUNCTION()
	void SetHighScoreVisuals(bool ShouldShow)
	{
		UMinigameHighscore HighScoreWidget = BP_GetHighScoreWidget();
		
		if(HighScoreWidget != nullptr)
			HighScoreWidget.ShowHighScoreVisuals(ShouldShow);
	}

// /* - Time Related Functions - */

	private UFUNCTION(BlueprintEvent)
	void BP_SetTime(float Time) {}

	UFUNCTION()
	void SetTime(float Time)
	{
		BP_SetTime(Time);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_ShowTimeCounter(bool ShowTimeCounter) {}

	UFUNCTION()
	void ShowTimeCounter(bool ShowTimeCounter)
	{
		BP_ShowTimeCounter(ShowTimeCounter);
	}

	private UFUNCTION(BlueprintEvent)
	void BP_DestroyScoreHudWithDuration(float Duration) {}

	// Destroys the widget after a duration
	UFUNCTION()
	void DestroyScoreHudWithDuration(float Duration)
	{
		DestroyTimer = Duration;
		bShouldTickDestroyTimer = true;
		BP_DestroyScoreHudWithDuration(Duration);
	}

	void StartCountdown()
	{
		UMinigameCountdown CountdownWidget = BP_GetCountdownWidget();

		if(CountdownWidget != nullptr)
			CountdownWidget.StartCountdown();
	}

	void StopCountdown()
	{
		UMinigameCountdown CountdownWidget = BP_GetCountdownWidget();

		if(CountdownWidget != nullptr)
			CountdownWidget.StopCountdown();		
	}

	//*** ROUNDS ***//

	private UFUNCTION(BlueprintEvent)
	void BP_ShowRoundOne() {}

	void ShowRoundOne()
	{
		BP_ShowRoundOne();
	}

	private UFUNCTION(BlueprintEvent)
	void BP_ShowRoundTwo() {}

	void ShowRoundTwo()
	{
		BP_ShowRoundTwo();
	}

	private UFUNCTION(BlueprintEvent)
	void BP_ShowRoundThree() {}

	void ShowRoundThree()
	{
		BP_ShowRoundThree();
	}

// /* - Text Related Functions - */

	void SetCountdownFinishedText(FText Text)
	{
		UMinigameCountdown CountdownWidget = BP_GetCountdownWidget();

		if(CountdownWidget != nullptr)
			CountdownWidget.SetCountdownFinishedText(Text);
	}

	void ShowWinner(EMinigameWinner Winner)
	{
		UMinigameVictoryScreen VictoryScreenWidget = BP_GetVictoryScreenWidget();

		if(VictoryScreenWidget != nullptr)
			VictoryScreenWidget.ShowPlayerWinner(Winner);
	}

//*** Instruction Window Functions ***//

	private UFUNCTION(BlueprintEvent)
	void BP_ShowTutorialWindow() {}
	
	private UFUNCTION(BlueprintEvent)
	void BP_HideTutorialWindow() {}

	private UFUNCTION(BlueprintEvent)
	void BP_SetPlayerInputs(float MayInput, float CodyInput) {}

	private UFUNCTION(BlueprintEvent)
	void BP_PlayerReadyMay() {}

	private UFUNCTION(BlueprintEvent)
	void BP_PlayerReadyCody() {}

	UFUNCTION(BlueprintEvent)
	void BP_SetTutorialMay(TArray<FTutorialPrompt> TutorialPrompts, FText Text) {}
	
	UFUNCTION(BlueprintEvent)
	void BP_SetTutorialCody(TArray<FTutorialPrompt> TutorialPrompts, FText Text) {}

	UFUNCTION()
	void ShowTutorialWindow() {BP_ShowTutorialWindow();}

	UFUNCTION()
	void HideTutorialWindow() {BP_HideTutorialWindow();}

	void SetPlayerInputs(float MayInput, float CodyInput) {BP_SetPlayerInputs(MayInput, CodyInput);}

	UFUNCTION()
	void PlayerReadyMay() {BP_PlayerReadyMay();}

	UFUNCTION()
	void PlayerReadyCody() {BP_PlayerReadyCody();}

// /* - General Functions - */
	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		UMinigameCountdown CountdownWidget = BP_GetCountdownWidget();
		
		if(CountdownWidget != nullptr)
			CountdownWidget.CountdownEvent.Clear();
		
		UMinigameVictoryScreen VictoryScreenWidget = BP_GetVictoryScreenWidget();
		
		if(VictoryScreenWidget != nullptr)
			VictoryScreenWidget.VictoryScreenFinishedEvent.Clear();
	}

//*** RACE LAPS FUNCTIONS ***//

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateMayLastLaps(float Value) {}
	
	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateCodyLastLaps(float Value) {}

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateMayBestLaps(float Value) {}

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateCodyBestLaps(float Value) {}

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateCurrentMayLapTime(float Value) {}

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateCurrentCodyLapTime(float Value) {}

	UFUNCTION()
	void UpdateMayLastLaps(float Value) {BP_UpdateMayLastLaps(Value);}

	UFUNCTION()
	void UpdateCodyLastLaps(float Value) {BP_UpdateCodyLastLaps(Value);}

	UFUNCTION()
	void UpdateMayBestLaps(float Value) {BP_UpdateMayBestLaps(Value);}

	UFUNCTION()
	void UpdateCodyBestLaps(float Value) {BP_UpdateCodyBestLaps(Value);}

	UFUNCTION()
	void UpdateCurrentMayLapTime(float Value) {BP_UpdateCurrentMayLapTime(Value);}

	UFUNCTION()
	void UpdateCurrentCodyLapTime(float Value) {BP_UpdateCurrentCodyLapTime(Value);}

//*** CHESS FUNCTIONS ***//

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateDoubleTimeMay(int Minutes, int Seconds) {}

	private UFUNCTION(BlueprintEvent)	
	void BP_UpdateDoubleTimeCody(int Minutes, int Seconds) {}

    private UFUNCTION(BlueprintEvent)
	void BP_SetClockIconVisibilityMay(bool Value) {}

    private UFUNCTION(BlueprintEvent)
	void BP_SetClockIconVisibilityCody(bool Value) {}

	UFUNCTION()
	void SetClockIconVisibilityMay(bool Value) {BP_SetClockIconVisibilityMay(Value);}

	UFUNCTION()
	void SetClockIconVisibilityCody(bool Value) {BP_SetClockIconVisibilityCody(Value);}

	UFUNCTION()
	void UpdateDoubleTimeMay(int Minutes, int Seconds) {BP_UpdateDoubleTimeMay(Minutes, Seconds);}

	UFUNCTION()
	void UpdateDoubleTimeCody(int Minutes, int Seconds) {BP_UpdateDoubleTimeCody(Minutes, Seconds);}

//*** SHOW IN GAME ROUND FUNCTIONS ***//

	UFUNCTION(BlueprintEvent)
	void BP_PlayMessageAnimation(FText Text) {}
}