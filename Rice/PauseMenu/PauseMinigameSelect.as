import Rice.MessageDialog.MessageDialogStatics;
import Rice.MinigamePicker.MinigamePickerWidget;

enum EMinigameSelectResult
{
	Closed,
	Confirmed,
	Unpaused,
};

struct FPauseMinigameSelectButtons
{
	UPROPERTY()
	UMenuPromptOrButton Back;

	UPROPERTY()
	UMenuPromptOrButton Proceed;
}

delegate void FOnPauseMinigameSelectClosed(EMinigameSelectResult Result);

class UPauseMinigameSelect : UHazeUserWidget
{
	default bCustomNavigation = true;

	UPROPERTY()
	UMinigamePickerWidget MinigamePicker;
	UPROPERTY()
	UHazePlayerIdentity Identity;

	FOnPauseMinigameSelectClosed OnClosed;

	private bool bNarrateNextTick = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{

	}

	void Init()
	{
		MinigamePicker.Initialize();
		MinigamePicker.ScrollToSelection();
		bNarrateNextTick = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}
	}

	UFUNCTION()
	void PlayMinigame()
	{
		if (Save::HasMinigameToRestart())
		{
			// If we're already playing a minigame we don't have a save to lose
			OnClosed.ExecuteIfBound(EMinigameSelectResult::Confirmed);
			return;
		}

		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("MinigameSelect", "Prompt", "Play the selected minigame?\nYour progress since your last save will be lost.");
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.ConfirmText = NSLOCTEXT("MinigameSelect", "PlayMinigame", "Play Minigame");
		Dialog.CancelText = NSLOCTEXT("MinigameSelect", "CancelPrompt", "Cancel");
		Dialog.OnClosed.BindUFunction(this, n"OnPlayMinigameResponse");

		ShowPopupMessage(Dialog);
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION()
	void OnPlayMinigameResponse(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			OnClosed.ExecuteIfBound(EMinigameSelectResult::Confirmed);
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			Widget::SetPlayerUIFocus(Identity, this);
			GetAudioManager().UI_OnSelectionCancel();
		}
	}

	UFUNCTION()
	void Back()
	{
		OnClosed.ExecuteIfBound(EMinigameSelectResult::Closed);
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (!Identity.TakesInputFromControllerId(Event.ControllerId))
				return nullptr;
		}

		// We respond to navigation for chapter select,
		// so analog stick can be used for switching chapters.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.

		if (Event.NavigationType == EUINavigation::Up)
			MinigamePicker.BrowseMinigame(-1);
		else if (Event.NavigationType == EUINavigation::Down)
			MinigamePicker.BrowseMinigame(+1);

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Gamepad_Special_Right
			|| Event.Key == EKeys::Escape)
		{
			OnClosed.ExecuteIfBound(EMinigameSelectResult::Unpaused);
			return FEventReply::Handled();
		}

		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (!Identity.TakesInputFromControllerId(Event.ControllerId))
				return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Virtual_Back
			|| Event.Key == EKeys::Escape)
		{
			OnClosed.ExecuteIfBound(EMinigameSelectResult::Closed);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Virtual_Accept
			|| Event.Key == EKeys::Enter)
		{
			PlayMinigame();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent Event)
	{
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (!Identity.TakesInputFromControllerId(Event.ControllerId))
				return FEventReply::Handled();
		}

		if (Event.GetKey() == EKeys::Gamepad_RightY && FMath::Abs(Event.AnalogValue) > 0.4f)
		{
			MinigamePicker.Scroll(Event.AnalogValue * -400.f * Time::UndilatedWorldDeltaSeconds);
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	FPauseMinigameSelectButtons GetButtonsForNarration()
	{
		return FPauseMinigameSelectButtons();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;
			
		FPauseMinigameSelectButtons Buttons = GetButtonsForNarration();

		FString FullNarration = "";


		FullNarration += "Play Minigames, ";
		auto MinigameRow = MinigamePicker.GetSelectedRow();
		if (MinigameRow != nullptr)
		{
			FullNarration += MinigameRow.MinigameChapter.Name.ToString() + ", ";
		}

		FString ButtonNarration;
		FString ControlNarration;

		if (Buttons.Back.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Proceed.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (!ControlNarration.IsEmpty())
			FullNarration += "Menu Controls, " + ControlNarration;

		Game::NarrateString(FullNarration);
	}

}