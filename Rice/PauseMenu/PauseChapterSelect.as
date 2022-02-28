import Rice.ChapterSelect.ChapterSelectPickerWidget;
import Rice.MessageDialog.MessageDialogStatics;

enum EChapterSelectResult
{
	Closed,
	Confirmed,
	Unpaused,
};
struct FPauseChapterSelectButtons
{
	UPROPERTY()
	UMenuPromptOrButton Back;

	UPROPERTY()
	UMenuPromptOrButton Proceed;
}

delegate void FOnPauseChapterSelectClosed(EChapterSelectResult Result);

class UPauseChapterSelect : UHazeUserWidget
{
	default bCustomNavigation = true;

	UPROPERTY()
	UChapterSelectPickerWidget ChapterPicker;
	UPROPERTY()
	UHazePlayerIdentity Identity;

	FOnPauseChapterSelectClosed OnClosed;

	private bool bNarrateNextTick = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{

	}

	void Init()
	{
		FHazeProgressPointRef ContinueChapter;
		FHazeProgressPointRef ContinuePoint;
		if (Save::GetContinueProgress(ContinueChapter, ContinuePoint)
			&& Save::IsChapterSelectUnlocked(ContinueChapter))
		{
			ChapterPicker.SelectChapter(ContinueChapter);
		}
		else
		{
			auto ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
			ChapterPicker.SelectChapter(ChapterDatabase.GetInitialChapter());
		}

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
	void PlayChapter()
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("ChapterSelect", "Prompt", "Play the selected chapter?\nYour progress since the start of the current chapter will be lost.");
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.ConfirmText = NSLOCTEXT("ChapterSelect", "PlayChapter", "Play Chapter");
		Dialog.CancelText = NSLOCTEXT("ChapterSelect", "CancelPrompt", "Cancel");
		Dialog.OnClosed.BindUFunction(this, n"OnPlayChapterResponse");

		ShowPopupMessage(Dialog);
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION()
	void OnPlayChapterResponse(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			OnClosed.ExecuteIfBound(EChapterSelectResult::Confirmed);
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
		OnClosed.ExecuteIfBound(EChapterSelectResult::Closed);
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

		if (Event.NavigationType == EUINavigation::Left)
			ChapterPicker.NavigateGroup(-1);
		else if (Event.NavigationType == EUINavigation::Right)
			ChapterPicker.NavigateGroup(+1);
		else if (Event.NavigationType == EUINavigation::Up)
			ChapterPicker.NavigateChapter(-1);
		else if (Event.NavigationType == EUINavigation::Down)
			ChapterPicker.NavigateChapter(+1);

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Gamepad_Special_Right
			|| Event.Key == EKeys::Escape)
		{
			OnClosed.ExecuteIfBound(EChapterSelectResult::Unpaused);
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
			OnClosed.ExecuteIfBound(EChapterSelectResult::Closed);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Virtual_Accept
			|| Event.Key == EKeys::Enter)
		{
			PlayChapter();
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	FPauseChapterSelectButtons GetButtonsForNarration()
	{
		return FPauseChapterSelectButtons();
	}
	
	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;

		FPauseChapterSelectButtons Buttons = GetButtonsForNarration();

		FString FullNarration = "";

		FullNarration += "Select Chapter, ";
		FullNarration += ChapterPicker.GetNarrationString(true);

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