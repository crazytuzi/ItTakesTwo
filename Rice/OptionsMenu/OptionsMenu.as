import Rice.OptionsMenu.OptionsMenuTab;
import Rice.OptionsMenu.OptionsMenuPendingChangesOverlay;
import Rice.MessageDialog.MessageDialogStatics;
import Rice.PauseMenu.PauseMenuSingleton;
import Rice.Mainmenu.MenuPromptOrButton;

delegate void FOnOptionsMenuClosed();

struct FOptionsMenuButtons
{
	UPROPERTY()
	UMenuPromptOrButton LeftTab;

	UPROPERTY()
	UMenuPromptOrButton RightTab;

	UPROPERTY()
	UMenuPromptOrButton Back;

	UPROPERTY()
	UMenuPromptOrButton Apply;

	UPROPERTY()
	UMenuPromptOrButton Reset;

	UPROPERTY()
	UMenuPromptOrButton EULA;
}

class UOptionsMenu : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazePlayerIdentity Identity;

	FOnOptionsMenuClosed OnClosed;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> InputOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> WinInputOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> AudioOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> WinDisplayOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> ConsoleDisplayOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsTabWidget> ControlsOptionsWidget;

	UPROPERTY()
	TSubclassOf<UOptionsMenuPendingChangesOverlay> PendingChangesOverlayWidgetClass;

	UPROPERTY()
	bool bShowEULA = false;

	UOptionsMenuPendingChangesOverlay PendingChangesOverlayWidget;
	TArray<int> BlacklistedIndices;

	TArray<UGameSettingsBaseWidget> AllSettings;
	UGameSettingsBaseWidget HighlightedSetting;

	bool bIsPromptingResolution = false;
	int ResolutionTimerDisplay = 0;
	float ResolutionTimer = 0.f;

	UPROPERTY(BlueprintReadWrite)
	bool bCanPlaySelectionSound = false;
	bool bCanPlayConfirmationOnOpenSound = true;

	private bool bNarrateNextTick = false;

	bool IsBlacklisted(UWidget Tab, TArray<TSubclassOf<UOptionsTabWidget>> BlacklistedTabs)
	{
		for (TSubclassOf<UOptionsTabWidget> Blacklisted : BlacklistedTabs)
		{
			if (Blacklisted.IsValid() && Tab.IsA(Blacklisted))
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Remove tabs not used on this platform
		TArray<TSubclassOf<UOptionsTabWidget>> BlacklistedTabs;
		if (Game::IsConsoleBuild())
		{
			BlacklistedTabs.Add(WinInputOptionsWidget);
			BlacklistedTabs.Add(WinDisplayOptionsWidget);
		}
		else
		{
			BlacklistedTabs.Add(ConsoleDisplayOptionsWidget);
		}

		for (int Index = TabSwitcher.NumWidgets-1; Index >= 0; --Index)
		{
			auto Tab = Cast<UOptionsTabWidget>(TabSwitcher.GetWidgetAtIndex(Index));
			if (IsBlacklisted(Tab, BlacklistedTabs))
			{
				Tab.bIsBlacklisted = true;
				BlacklistedIndices.Add(Index);
			}
			else
			{
				Tab.bIsBlacklisted = false;
			}
		}

		TabSwitched();

		GetAllSettings(AllSettings);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsPromptingResolution)
			UpdateResolutionTimer(InDeltaTime);

		// Update which setting is highlighted
		if (HighlightedSetting == nullptr || !HighlightedSetting.IsHighlighted())
		{
			auto PreviousHighlighted = HighlightedSetting;
			HighlightedSetting = nullptr;

			for (auto Setting : AllSettings)
			{
				if (Setting.IsHighlighted())
				{
					HighlightedSetting = Setting;
				}
			}

			if (PreviousHighlighted != HighlightedSetting)
			{
				if (HighlightedSetting != nullptr)
				{
					FString Value;
					UHazeGameSettingBase SettingsDescription;
					if (GameSettings::GetGameSettingsDescriptionAndValue(HighlightedSetting.GetSettingName(), SettingsDescription, Value))
						UpdateTooltipDescription(SettingsDescription.Description);
					else
						UpdateTooltipDescription(FText());

					if(bCanPlaySelectionSound)
					{
						if(!HighlightedSetting.IsFocusedByMouse())
							GetAudioManager().UI_OptionsMenuRowSelect();
						else
						{
							const float NormalizedInstanceCount = FMath::Clamp(GetAudioManager().MenuWidgetMouseHoverSoundCount / 5.f, 0.f, 1.f);
							UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", NormalizedInstanceCount);
							GetAudioManager().UI_OnSelectionChanged_Mouse();

							if(!HighlightedSetting.bTickForSoundReset)
							{
								GetAudioManager().MenuWidgetMouseHoverSoundCount ++;
								HighlightedSetting.bTickForSoundReset = true;
								HighlightedSetting.PlaySoundTimer = Time::GetRealTimeSeconds();
							}
						}
					}

					// Ugly way of making sure the confirm sound plays the first time options are opened, before tick has happened
					if(bCanPlayConfirmationOnOpenSound)						
						GetAudioManager().UI_OnSelectionConfirmed();
				}
				else
				{
					UpdateTooltipDescription(FText());
				}
			}

			bCanPlaySelectionSound = true;
			bCanPlayConfirmationOnOpenSound = false;
		}

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}
	}

	UFUNCTION(BlueprintEvent)
	void UpdateTooltipDescription(FText Text)
	{
	}

	UFUNCTION()
	void PromptForReset()
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("OptionsMenu", "PromptReset", "Reset all settings back to the default values?");
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.ConfirmText = NSLOCTEXT("OptionsMenu", "ResetAllSettings", "Reset All Settings");
		Dialog.CancelText = NSLOCTEXT("OptionsMenu", "Back", "Back");
		Dialog.OnClosed.BindUFunction(this, n"OnResetPrompt");

		ShowPopupMessage(Dialog);
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION()
	void OnResetPrompt(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			ResetGameSettings();
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			// Reset focus
			bCanPlaySelectionSound = false;
			GetAudioManager().UI_OnSelectionCancel();
		}

		Widget::SetAllPlayerUIFocus(GetInitialFocus());
	}

	FString PreviousResolution;
	FString PreviousWindowMode;

	void UpdateResolutionTimer(float DeltaTime)
	{
		ResolutionTimer -= DeltaTime;

		FText Text = NSLOCTEXT("OptionsMenu", "PromptResolutionChange", "Keep these resolution changes?\n\nReverting in {} seconds.");
		int NewSeconds = FMath::CeilToInt(ResolutionTimer);
		if (NewSeconds != ResolutionTimerDisplay)
		{
			ResolutionTimerDisplay = NewSeconds;
			UpdatePopupMessageText(FOnMessageClosed(this, n"OnAcceptResolution"), 
				FText::FromString(
					Text.ToString().Replace("{}",
						""+NewSeconds)
				));
		}

		if (ResolutionTimer <= 0.f)
		{
			OnAcceptResolution(EMessageDialogResponse::No);
			ForceClosePopupMessage(FOnMessageClosed(this, n"OnAcceptResolution"));
		}
	}

	UFUNCTION()
	bool ApplyMaybePrompt()
	{
		if (HasResolutionChange())
		{
			GameSettings::GetGameSettingsValue(n"WindowMode", PreviousWindowMode);
			GameSettings::GetGameSettingsValue(n"Resolution", PreviousResolution);

			ApplyGameSettings();

			FString NewMode;
			GameSettings::GetGameSettingsValue(n"WindowMode", NewMode);

			if (NewMode == "Fullscreen")
			{
				FMessageDialog Dialog;
				Dialog.ConfirmText = NSLOCTEXT("OptionsMenu", "KeepResolutionChange", "Keep Resolution");
				Dialog.Type = EMessageDialogType::YesNo;
				Dialog.OnClosed.BindUFunction(this, n"OnAcceptResolution");
				ShowPopupMessage(Dialog);

				GetAudioManager().UI_PopupMessageOpen();

				bIsPromptingResolution = true;
				ResolutionTimer = 15.f;
				ResolutionTimerDisplay = -1;
				UpdateResolutionTimer(0.f);

				return true;
			}
			else
			{
				ApplyGameSettings();
			}
		}
		else
		{
			ApplyGameSettings();
		}

		GetAudioManager().UI_OnSelectionConfirmed();

		return false;
	}

	UFUNCTION()
	void OnAcceptResolution(EMessageDialogResponse Response)
	{
		bIsPromptingResolution = false;

		if (Response == EMessageDialogResponse::Yes)
		{
			ApplyGameSettings();
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			auto Resolution = GetSettingWidget(n"Resolution");
			Resolution.SetSettingsValue(PreviousResolution);

			auto WindowMode = GetSettingWidget(n"WindowMode");
			WindowMode.SetSettingsValue(PreviousWindowMode);
			GetAudioManager().UI_OnSelectionCancel();

			bCanPlaySelectionSound = false;
			ApplyGameSettings();
		}
	}

	UFUNCTION()
	void CloseOrPromptForClose()
	{
		if (HasResolutionChange())
		{
			if (ApplyMaybePrompt())
				return;
		}

		ApplyGameSettings();
		CloseOptionsMenu();
	}

	UFUNCTION()
	void CloseOptionsMenu()
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_OptionsMenu_IsOpen", 0.f);
		bCanPlaySelectionSound = false;
		GetAudioManager().UI_OptionsMenuClose();
		OnClosed.ExecuteIfBound();
	}

	UFUNCTION()
	void ApplyGameSettingsKeyBindings()
	{
		GameSettings::ApplyGameSettingsKeyBindings();
	}

	UFUNCTION(BlueprintEvent)
	UWidget GetInitialFocus() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UWidgetSwitcher GetTabSwitcher() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void ConstructGameSettings()
	{
	}

	UFUNCTION(BlueprintEvent)
	bool HasPendingGameSettings()
	{
		return false;
	}

	UFUNCTION(BlueprintEvent)
	void GetAllSettings(TArray<UGameSettingsBaseWidget>&out OutWidgets)
	{
	}

	UFUNCTION(BlueprintEvent)
	FOptionsMenuButtons GetButtonsForNarration()
	{
		return FOptionsMenuButtons();
	}

	UGameSettingsBaseWidget GetSettingWidget(FName SettingName)
	{
		for (auto Widget : AllSettings)
		{
			FName Setting = Widget.GetSettingName();
			if (Setting == SettingName)
				return Widget;
		}

		return nullptr;
	}

	bool HasResolutionChange()
	{
		if (Game::IsConsoleBuild())
			return false;

		auto Resolution = GetSettingWidget(n"Resolution");
		if (Resolution != nullptr && Resolution.HasPendingChanges())
			return true;

		auto WindowMode = GetSettingWidget(n"WindowMode");
		if (WindowMode != nullptr && WindowMode.HasPendingChanges())
			return true;

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void ApplyGameSettings()
	{
	}

	UFUNCTION(BlueprintEvent)
	void ResetGameSettings()
	{
	}

	UFUNCTION(BlueprintEvent)
	void TabSwitched()
	{
	}

	UFUNCTION()
	void GoToNextOptionsTab(int Direction)
	{
		bCanPlaySelectionSound = false;
		int CurrentIndex = TabSwitcher.ActiveWidgetIndex;
		int NumWidgets = TabSwitcher.NumWidgets;

		int NewIndex = CurrentIndex + Direction;
		if (NewIndex < 0)
			NewIndex = NumWidgets-1;
		if (NewIndex >= NumWidgets)
			NewIndex = 0;

		while (BlacklistedIndices.Contains(NewIndex))
		{
			NewIndex += Direction;
			if (NewIndex < 0)
				NewIndex = NumWidgets-1;
			if (NewIndex >= NumWidgets)
				NewIndex = 0;
		}

		TabSwitcher.SetActiveWidgetIndex(NewIndex);
		TabSwitched();

		GetAudioManager().UI_OptionsMenuTabSelect();	

		Widget::SetAllPlayerUIFocus(GetInitialFocus());
	}

	UFUNCTION()
	void GoToTab(int Number)
	{
		TabSwitcher.SetActiveWidgetIndex(Number);
		TabSwitched();

		Widget::SetAllPlayerUIFocus(GetInitialFocus());
	}
	
	UFUNCTION()
	void OpenEULA()
	{
		bShowEULA = true;
		BP_OpenEULA();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenEULA() {}

	UFUNCTION()
	void CloseEULA()
	{
		bShowEULA = false;

		bCanPlaySelectionSound = false;
		Widget::SetAllPlayerUIFocus(GetInitialFocus());
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (bShowEULA)
			return FEventReply::Unhandled();

		// Ignore input not from the owner of the options menu
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (!Identity.TakesInputFromControllerId(Event.ControllerId))
				return FEventReply::Handled();
		}

		// Close the options menu with B
		if (Event.Key == EKeys::Virtual_Back || Event.Key == EKeys::Escape || Event.Key == EKeys::BackSpace)
		{
			CloseOrPromptForClose();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_FaceButton_Left || Event.Key == EKeys::F1)
		{
			ApplyMaybePrompt();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_FaceButton_Top || Event.Key == EKeys::F2)
		{
			PromptForReset();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_LeftShoulder || Event.Key == EKeys::PageUp)
		{
			GoToNextOptionsTab(-1);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_RightShoulder || Event.Key == EKeys::PageDown)
		{
			GoToNextOptionsTab(1);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_LeftTrigger || Event.Key == EKeys::F3)
		{
			OpenEULA();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Tab)
		{
			GoToNextOptionsTab(+1);
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;
		
		FOptionsMenuButtons Buttons = GetButtonsForNarration();

		FString FullNarration = "";
		FString ButtonNarration;

		auto CurrentTab = Cast<UOptionsTabWidget>(TabSwitcher.GetActiveWidget());
		if (CurrentTab == nullptr)
			return;

		
		// Narrate the controller screen specially
		if (CurrentTab.IsA(ControlsOptionsWidget))
		{ 
			FullNarration += CurrentTab.TabDisplayName.ToString() + ", ";
			FOptionsTabNarrationText NarrationText = CurrentTab.GetTextsForNarration();

			EHazePlayerControllerType ConType = Lobby::GetMostLikelyControllerType();
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_LeftY, ConType).ToString() + ", ";
			FullNarration += NarrationText.LeftStick.ToString() + ", ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_LeftThumbstick, ConType).ToString() + ", ";
			FullNarration += NarrationText.LeftStickButton.ToString() + ", ";

			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_RightY, ConType).ToString() + ", ";
			FullNarration += NarrationText.RightStick.ToString() + ", ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_RightThumbstick, ConType).ToString() + ", ";
			FullNarration += NarrationText.RightStickButton.ToString() + ", ";

			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Bottom, ConType).ToString() + ", ";
			FullNarration += NarrationText.FaceDown.ToString() + ", ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Right, ConType).ToString() + ", ";
			FullNarration += NarrationText.FaceRight.ToString() + ", ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Top, ConType).ToString() + ", ";
			FullNarration += NarrationText.FaceUp.ToString() + ", ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Left, ConType).ToString() + ", ";
			FullNarration += NarrationText.FaceLeft.ToString() + ", ";

			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_RightShoulder, ConType).ToString() + ", ";
			FullNarration += NarrationText.RightShoulder.ToString() + ", ";

			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_LeftTrigger, ConType).ToString();
			FullNarration += "and ";
			FullNarration += Game::KeyToNarrationText(EKeys::Gamepad_RightTrigger, ConType).ToString() + ", ";
			FullNarration += NarrationText.Triggers.ToString() + ", ";
		}
		else if (HighlightedSetting != nullptr)
		{
			FullNarration += CurrentTab.TabDisplayName.ToString() + " Options, ";
			FullNarration += HighlightedSetting.GetFullNarrationText() + ", ";
		}

		FString ControlNarration;
		if (Buttons.LeftTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.RightTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Back.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Apply.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Reset.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.EULA.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (!ControlNarration.IsEmpty())
			FullNarration += "Menu Controls, " + ControlNarration;

		Game::NarrateString(FullNarration);
	}

	UFUNCTION()
	void NarrateFullMenu()
	{
		bNarrateNextTick = true;
	}
};