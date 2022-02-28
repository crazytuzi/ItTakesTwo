import Rice.PauseMenu.PauseMenuSingleton;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

const FConsoleCommand Command_TrialUpsell("Haze.TrialUpsell", n"ConsoleTrialUpsell");

class UTrialUpsellWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		Game::HazeGameInstance.bTrialUpsellActive = true;
		Game::SetGamePaused(this, true);
		GetAudioManager().UI_PopupMessageOpen();

		Widget::SetAllPlayerUIFocus(BP_GetInitialEntry());
		Widget::SetUseMouseCursor(true);
		SetWidgetZOrderInLayer(150);
		SetWidgetPersistent(true);

		UPauseMenuSingleton::Get().UpsellWidget = this;
	}

	void CloseWidget()
	{
		Game::SetGamePaused(this, false);
		Widget::ClearAllPlayerUIFocus();
		Widget::RemoveFullscreenWidget(this);
		UPauseMenuSingleton::Get().UpsellWidget = nullptr;
		Game::HazeGameInstance.bTrialUpsellActive = false;
	}

	UFUNCTION()
	void ReturnToMain()
	{
		CloseWidget();
		Progress::ReturnToMainMenu();
		GetAudioManager().UI_OnSelectionCancel();
	}

	UFUNCTION(BlueprintPure)
	bool IsBusy()
	{
		FText DummyText;
		return Online::HasBusyTask(DummyText);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// If the user buys the game, close this dialog!
		if (!NeedsUpsell())
		{
			CloseWidget();
			return;
		}

		// Don't allow pause menu here
		Game::HazeGameInstance.ClosePauseMenu();

		// We might be in a menu lobby (accepted an invite through OS)
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && !Lobby.HasGameStarted())
		{
			CloseWidget();
			return;
		}

		Widget::SetAllPlayerUIFocusBeneathParent(this);
	}

	UFUNCTION(BlueprintEvent)
	UWidget BP_GetInitialEntry()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry Geom, FFocusEvent Event)
	{
		auto InitialFocus = BP_GetInitialEntry();
		if (InitialFocus != nullptr && InitialFocus != this)
		{
			BP_ResetButtonsForSound();
			return FEventReply::Handled().SetUserFocus(InitialFocus);
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResetButtonsForSound(){ };
};

bool NeedsUpsell()
{
	if (Game::HazeGameInstance == nullptr)
		return false;
	return Game::HazeGameInstance.IsTrialUpsellNeeded();
}

void ConsoleTrialUpsell(const TArray<FString>& Args)
{
	Game::HazeGameInstance.TriggerTrialUpsell();
}

UFUNCTION()
void ReachedPlayFirstTrialBoundary()
{
	Game::HazeGameInstance.TriggerTrialUpsell();
}

UFUNCTION(BlueprintPure)
bool IsTrialUpsellActive()
{
	return UPauseMenuSingleton::Get().UpsellWidget != nullptr;
}