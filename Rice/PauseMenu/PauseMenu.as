import Rice.PauseMenu.PauseOptionsMenu;
import Rice.PauseMenu.PauseMenuSingleton;
import Rice.PauseMenu.PauseChapterSelect;
import Rice.PauseMenu.PauseMinigameSelect;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Rice.MainMenu.TTSUI;
import Rice.GUI.AccessibilityChatWidget;

const FConsoleVariable CVar_EnableDevMenu("Haze.EnableDevMenu", 0);

UCLASS(Abstract)
class UPauseMenu : UHazeUserWidget
{
	UPROPERTY()
	UHazePlayerIdentity MenuOwner;

	UPROPERTY()
	TSubclassOf<UPauseOptionsMenu> OptionsMenuClass;

	UPROPERTY()
	TSubclassOf<UPauseChapterSelect> ChapterSelectClass;

	UPROPERTY()
	TSubclassOf<UPauseMinigameSelect> MinigameSelectClass;

	UPauseOptionsMenu PauseOptionsMenu;
	UPauseChapterSelect PauseChapterSelect;
	UPauseMinigameSelect PauseMinigameSelect;

	bool ReleaseMouseOnClose = true;
	bool bBackDown = false;
	bool bAnyMinigamesUnlocked = false;
	private bool bHasTickedForSound = false;

	EPauseMenuStartSubMenu PendingSubmenu = EPauseMenuStartSubMenu::Default;

	UFUNCTION(BlueprintPure)
	bool ShouldShowRemotePlayer()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby == nullptr)
			return false;
		return Lobby.Network != EHazeLobbyNetwork::Local;
	}

	UFUNCTION(BlueprintPure)
	FText GetRemotePlayerName()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby == nullptr)
			return FText();
		if (Lobby.Network == EHazeLobbyNetwork::Local)
			return FText();

		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity == nullptr)
				continue;
			if (Member.Identity.IsLocal())
				continue;
			return Member.Identity.PlayerName;
		}
		return FText();
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		ReleaseMouseOnClose = true;
		bAnyMinigamesUnlocked = AreAnyMinigamesUnlocked();

		int ControllerId = Game::HazeGameInstance.PauseMenuControllerId;
		MenuOwner = Online::GetLocalIdentityAssociatedWithInputDevice(ControllerId);

		BP_OnPauseMenuOpened();

		Widget::SetPlayerUIFocus(MenuOwner, BP_GetInitialEntry());
		Widget::SetUseMouseCursor(true);
		SetWidgetZOrderInLayer(100);

		UPauseMenuSingleton PauseMenuSingleton = UPauseMenuSingleton::Get();
		PendingSubmenu = PauseMenuSingleton.StartSubMenu;

		PauseMenuSingleton.OnOpened.Broadcast();
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geo, float DeltaTime)
	{
		if (PendingSubmenu == EPauseMenuStartSubMenu::Options)
			OpenOptionsMenu();
		PendingSubmenu = EPauseMenuStartSubMenu::Default;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (ReleaseMouseOnClose)
		{
			Widget::SetUseMouseCursor(false);
		}

		Widget::ClearPlayerUIFocus(MenuOwner);

		if (PauseChapterSelect != nullptr)
			Widget::RemoveFullscreenWidget(PauseChapterSelect);
		if (PauseMinigameSelect != nullptr)
			Widget::RemoveFullscreenWidget(PauseMinigameSelect);
		if (PauseOptionsMenu != nullptr)
			Widget::RemoveFullscreenWidget(PauseOptionsMenu);

		UPauseMenuSingleton PauseMenuSingleton = UPauseMenuSingleton::Get();
		PauseMenuSingleton.OnClosed.Broadcast();

		auto ChatWidget = Cast<UAccessibilityChatWidget>(UPauseMenuSingleton::Get().ChatWidget);
		if (ChatWidget != nullptr)
			ChatWidget.CanNoLongerBrowse();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Virtual_Back)
		{
			bBackDown = true;
			return FEventReply::Handled();
		}

		if (HandleTTSKeyInput(Event))
		{
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Virtual_Back)
		{
			if (bBackDown)
			{
				bBackDown = false;
				GetAudioManager().UI_OnSelectionCancel();
				ClosePauseMenu();
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		if (InAnalogInputEvent.GetKey() == EKeys::Gamepad_RightY)
		{
			auto ChatWidget = Cast<UAccessibilityChatWidget>(UPauseMenuSingleton::Get().ChatWidget);
			if (ChatWidget != nullptr)
			{
				if (ChatWidget.BrowseInput(InAnalogInputEvent))
					return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void OpenOptionsMenu()
	{
		SetVisibility(ESlateVisibility::Hidden);

		PauseOptionsMenu = Cast<UPauseOptionsMenu>(Widget::AddFullscreenWidget(OptionsMenuClass.Get(), EHazeWidgetLayer::Menu));
		PauseOptionsMenu.OptionsMenu.Identity = MenuOwner;
		PauseOptionsMenu.OptionsMenu.OnClosed.BindUFunction(this, n"OptionsMenuClosed");
		PauseOptionsMenu.OptionsMenu.ConstructGameSettings();
		Widget::SetPlayerUIFocus(MenuOwner, PauseOptionsMenu.OptionsMenu.InitialFocus);

		UPauseMenuSingleton PauseMenuSingleton = UPauseMenuSingleton::Get();
		PauseMenuSingleton.OnOptionsOpened.Broadcast();
	}

	UFUNCTION()
	void OptionsMenuClosed()
	{
		Widget::RemoveFullscreenWidget(PauseOptionsMenu);
		PauseOptionsMenu = nullptr;

		SetVisibility(ESlateVisibility::Visible);
		Widget::SetPlayerUIFocus(MenuOwner, BP_GetInitialEntry());

		UPauseMenuSingleton PauseMenuSingleton = UPauseMenuSingleton::Get();
		PauseMenuSingleton.OnOptionsClosed.Broadcast();

		BP_FocusOptionsButton();
	}

	UFUNCTION()
	void OpenChapterSelect()
	{
		SetVisibility(ESlateVisibility::Hidden);

		PauseChapterSelect = Cast<UPauseChapterSelect>(Widget::AddFullscreenWidget(ChapterSelectClass.Get(), EHazeWidgetLayer::Menu));
		PauseChapterSelect.Identity = MenuOwner;
		PauseChapterSelect.OnClosed.BindUFunction(this, n"ChapterSelectClosed");
		Widget::SetPlayerUIFocus(MenuOwner, PauseChapterSelect);
		PauseChapterSelect.Init();

		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void ChapterSelectClosed(EChapterSelectResult Result)
	{
		FHazeChapter SelectedChapter = PauseChapterSelect.ChapterPicker.SelectedChapter;

		Widget::RemoveFullscreenWidget(PauseChapterSelect);
		PauseChapterSelect = nullptr;

		if (Result == EChapterSelectResult::Unpaused || Result == EChapterSelectResult::Confirmed)
		{
			ClosePauseMenu();
		}
		else
		{
			SetVisibility(ESlateVisibility::Visible);
			Widget::SetPlayerUIFocus(MenuOwner, BP_GetInitialEntry());
			BP_FocusChapterSelectButton();
			GetAudioManager().UI_OnSelectionCancel();
		}

		if (Result == EChapterSelectResult::Confirmed)
		{
			if (CanChapterSelect())
				Progress::Menu_ChapterSelect(SelectedChapter.ProgressPoint);
		}

	}

	UFUNCTION()
	void OpenMinigameSelect()
	{
		SetVisibility(ESlateVisibility::Hidden);

		PauseMinigameSelect = Cast<UPauseMinigameSelect>(Widget::AddFullscreenWidget(MinigameSelectClass.Get(), EHazeWidgetLayer::Menu));
		PauseMinigameSelect.Identity = MenuOwner;
		PauseMinigameSelect.OnClosed.BindUFunction(this, n"MinigameSelectClosed");

		Widget::SetPlayerUIFocus(MenuOwner, PauseMinigameSelect);
		PauseMinigameSelect.Init();

		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void MinigameSelectClosed(EMinigameSelectResult Result)
	{
		FHazeProgressPointRef SelectedMinigame = PauseMinigameSelect.MinigamePicker.SelectedMinigame;

		Widget::RemoveFullscreenWidget(PauseMinigameSelect);
		PauseMinigameSelect = nullptr;

		if (Result == EMinigameSelectResult::Unpaused || Result == EMinigameSelectResult::Confirmed)
		{
			ClosePauseMenu();
		}
		else
		{
			SetVisibility(ESlateVisibility::Visible);
			Widget::SetPlayerUIFocus(MenuOwner, BP_GetInitialEntry());
			BP_FocusMinigameSelectButton();
			GetAudioManager().UI_OnSelectionCancel();
		}

		if (Result == EMinigameSelectResult::Confirmed)
		{
			if (CanMinigameSelect())
				Progress::Menu_PickMinigame(SelectedMinigame);
		}
	}

	UFUNCTION()
	void ClosePauseMenu()
	{
		Game::HazeGameInstance.ClosePauseMenu();
	}

	UFUNCTION()
	void ReturnToMainMenu()
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptReturnToMainMenu", "Return to the main menu?\nYour progress since the last save will be lost.");
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.ConfirmText = NSLOCTEXT("PauseMenu", "AcceptReturn", "Return to Main Menu");
		Dialog.CancelText = NSLOCTEXT("PauseMenu", "CancelReturn", "Cancel");
		Dialog.OnClosed.BindUFunction(this, n"OnReturnToMainResponse");

		GetAudioManager().UI_PopupMessageOpen();
		ShowPopupMessage(Dialog);
	}

	UFUNCTION()
	void OnReturnToMainResponse(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			ReleaseMouseOnClose = false;
			ClosePauseMenu();
			Progress::ReturnToMainMenu();
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{			
			BP_FocusReturnToMainMenu();
			GetAudioManager().UI_OnSelectionCancel();
		}
	}

	UFUNCTION()
	void RestartFromCheckpoint()
	{
		ClosePauseMenu();
		Progress::Menu_CheckpointRestart();
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void ContinueGame()
	{
		ClosePauseMenu();
		GetAudioManager().UI_OnSelectionCancel();
	}

	UFUNCTION(BlueprintPure)
	bool CanRestartMinigame()
	{
		return Progress::Menu_CanMinigameRestart();
	}

	UFUNCTION()
	void RestartMinigame()
	{
		ClosePauseMenu();
		Progress::Menu_MinigameRestart();
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION(BlueprintPure)
	bool CanContinuePlaying()
	{
		return Progress::Menu_CanContinuePlayingSave();
	}

	UFUNCTION(BlueprintPure)
	bool HasContinuePlayingSave()
	{
		return Save::HasContinuePlayingSave();
	}

	UFUNCTION(BlueprintPure)
	FText GetContinuePlayingName()
	{
		FHazeProgressPointRef Chapter;
		FHazeProgressPointRef ProgressPoint;
		Save::GetContinuePlayingSave(Chapter, ProgressPoint);

		FHazeChapter ContinueChapter = UHazeChapterDatabase::GetChapterDatabase().GetChapterByProgressPoint(Chapter);
		return ContinueChapter.Name;
	}

	UFUNCTION()
	void ContinuePlayingSave()
	{
		ClosePauseMenu();
		if (CanContinuePlaying())
			Progress::Menu_ContinuePlayingSave();
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION(BlueprintEvent)
	UWidget BP_GetInitialEntry()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPauseMenuOpened() { }

	UFUNCTION(BlueprintEvent)
	void BP_FocusOptionsButton() { }

	UFUNCTION(BlueprintEvent)
	void BP_FocusChapterSelectButton() { }

	UFUNCTION(BlueprintEvent)
	void BP_FocusMinigameSelectButton() { }

	UFUNCTION(BlueprintEvent)
	void BP_FocusReturnToMainMenu() { }

	UFUNCTION()
	void ShowTextToSpeechInput()
	{
		Online::ShowTextToSpeechInput();
	}

	UFUNCTION(BlueprintPure)
	bool TextToSpeechInputEnabled()
	{
		switch (Online::GetAccessibilityState(EHazeAccessibilityFeature::TextToSpeech))
		{
			case EHazeAccessibilityState::OSTurnedOn:
			case EHazeAccessibilityState::GameTurnedOn:
				return true;
		}
		return false;
	}

	UFUNCTION()
	void OpenDeveloperMenu()
	{
		ClosePauseMenu();
		Widget::Debug_OpenDevMenu(n"Levels");
	}

	UFUNCTION(BlueprintPure)
	bool CanChapterSelect()
	{
		if (Progress::IsSwitchingLevelSet())
			return false;
		if (Game::IsInLoadingScreen())
			return false;
		FHazeProgressPointRef ContinueChapter;
		FHazeProgressPointRef ContinuePoint;
		if (!Save::GetContinueProgress(ContinueChapter, ContinuePoint))
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool CanMinigameSelect()
	{
		if (!Progress::Menu_CanPickMinigame())
			return false;
		if (!bAnyMinigamesUnlocked)
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowDevOptions() const
	{
#if TEST
		return true;
#else
		if (Game::HazeGameInstance != nullptr)
		{
			if (Game::HazeGameInstance.IsTrialUpsellNeeded())
				return false;
		}
		return (CVar_EnableDevMenu.GetInt() != 0);
#endif
	}

	bool AreAnyMinigamesUnlocked()
	{
		auto ChapterDB = UHazeChapterDatabase::GetChapterDatabase();
		for (int i = 0, Count = ChapterDB.ChapterCount; i < Count; ++i)
		{
			FHazeChapter Chapter = ChapterDB.GetChapterByIndex(i);
			if (!Chapter.bIsMinigame)
				continue;
			if (Save::IsMinigameUnlocked(Chapter.MinigameId))
				return true;
		}
		return false;
	}
};

event void FOnPauseMenuButtonPressed();

UCLASS(Abstract)
class UPauseMenuRow : UHazeUserWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	private bool bFocused = false;

	UPROPERTY(BlueprintReadWrite)
	bool bHasTickedForSound = false;

	private bool bFocusedByMouse = false;
	private bool bTickForSoundReset = false;
	private float PlaySoundTimer = 0;

	UPROPERTY()
	FOnPauseMenuButtonPressed OnPressed;

	UFUNCTION(BlueprintEvent)
	void Narrate()
	{
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonHighlighted()
	{
		return bFocused;
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent FocusEvent)
	{
		bFocused = true;
		if(bHasTickedForSound)
		{
			if(bFocusedByMouse)	
			{
				const float NormalizedInstanceCount = FMath::Clamp(GetAudioManager().MenuWidgetMouseHoverSoundCount / 5.f, 0.f, 1.f);
				UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", NormalizedInstanceCount);
				GetAudioManager().UI_OnSelectionChanged_Mouse();

				if(!bTickForSoundReset)
				{
					GetAudioManager().MenuWidgetMouseHoverSoundCount ++;
					bTickForSoundReset = true;
					PlaySoundTimer = Time::GetRealTimeSeconds();
				}
			}
			else
				GetAudioManager().UI_OnSelectionChanged();
		}

		Narrate();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent FocusEvent)
	{
		bFocused = false;
		bFocusedByMouse = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bFocusedByMouse = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bFocused && !MouseEvent.CursorDelta.IsZero())
		{
			bFocusedByMouse = true;
			Widget::SetAllPlayerUIFocus(this);
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{			
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			OnPressed.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			OnPressed.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		bHasTickedForSound = true;

		if(bTickForSoundReset)
		{
			if(Time::GetRealTimeSince(PlaySoundTimer) >= 0.25f)
			{
				ResetMouseOverRTPC();
			}
		}
	}

	UFUNCTION()
	void ResetMouseOverRTPC()
	{
		GetAudioManager().MenuWidgetMouseHoverSoundCount --;
		bTickForSoundReset = false;
	}
}