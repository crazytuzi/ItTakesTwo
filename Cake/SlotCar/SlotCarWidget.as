import Cake.SlotCar.SlotCarLapTimes;

class USlotCarWidget : UHazeUserWidget
{   
	UPROPERTY()
    int CurrentLaps = 0;
	UPROPERTY()
	int TargetLaps = 0;

	UPROPERTY()
	float BestLaptime;
	UPROPERTY()
	float LastLaptime;

	UPROPERTY()
	float CurrentLaptime;

	UPROPERTY()
	FName OwnerName;

	UPROPERTY()
	FLinearColor OwnerColour;

	void RaceStarted(int LapTarget = 5)
	{
		CurrentLaps = 0;
		TargetLaps = LapTarget;
	}

	void LapCompleted(float LapTime)
	{
		LastLaptime = LapTime;

		if (LastLaptime < BestLaptime)
			BestLaptime = LastLaptime;
	}

	UFUNCTION(BlueprintEvent)
	void ShowSlotCarWidget() {}

	UFUNCTION(BlueprintEvent)
	void HideSlotCarWidget() {}	
}

class USlotCarTrackWidget : UHazeUserWidget
{   	
	UPROPERTY()
	TArray<AHazePlayerCharacter> ActivePlayers;

	UFUNCTION(BlueprintEvent)
	USlotCarWidget GetSlotCarWidgetForPlayer(AHazePlayerCharacter InPlayer)
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void UpdateSlotCarWidget(AHazePlayerCharacter InPlayer, FSlotCarLapTimes LapTimes)
	{
		USlotCarWidget SlotCarWidget = GetSlotCarWidgetForPlayer(InPlayer);
		if (SlotCarWidget == nullptr)
			return;

		SlotCarWidget.CurrentLaps = LapTimes.NumberOfLaps;
		SlotCarWidget.TargetLaps = LapTimes.TargetLaps;

		SlotCarWidget.CurrentLaptime = LapTimes.CurrentLapTime;
		SlotCarWidget.LastLaptime = LapTimes.LastLapTime;
		SlotCarWidget.BestLaptime = LapTimes.BestLapTime;
	}

	UFUNCTION(BlueprintEvent)
	void PlayerEnteredTrack(AHazePlayerCharacter InPlayer)
	{
		ActivePlayers.Add(InPlayer);
		GetSlotCarWidgetForPlayer(InPlayer).ShowSlotCarWidget();
	}

	UFUNCTION(BlueprintEvent)
	void PlayerLeftTrack(AHazePlayerCharacter InPlayer)
	{
		ActivePlayers.Remove(InPlayer);
		GetSlotCarWidgetForPlayer(InPlayer).HideSlotCarWidget();
	}

	UFUNCTION(BlueprintEvent)
	void RaceCountdownStarted() {}

	UFUNCTION(BlueprintEvent)
	void RaceCountdownFinished() {}

	UFUNCTION(BlueprintEvent)
	void RaceAborted(AHazePlayerCharacter InPlayer) {}

	UFUNCTION(BlueprintEvent)
	void DisplayWinner(AHazePlayerCharacter InPlayer) {}

	UFUNCTION(BlueprintEvent)
	void UpdateStartLights(int LightSequence) {}
	
	UFUNCTION(BlueprintEvent)
	void HideStartLights() {}
}