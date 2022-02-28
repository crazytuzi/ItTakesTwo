import Rice.MainMenu.MainMenu;
import Rice.OptionsMenu.BootOptionsPage;

enum ESplashWidgetState
{
	Prompt,
	Loading,
	EULA,
	BootOptions,
	None
};

struct FSplashOptionsButtons
{
	UPROPERTY()
	UMenuPromptOrButton BackButton;

	UPROPERTY()
	UMenuPromptOrButton ContinueButton;
}

const FConsoleVariable CVar_AlwaysShowEULA("Haze.AlwaysShowEULA", 0);
const FConsoleCommand Command_ResetEULA("Haze.ResetEULA", n"ResetEULA");

class USplashWidget : UMainMenuStateWidget
{
	UPROPERTY()
	UHazePlayerIdentity PendingIdentity;

	UPROPERTY()
	UScrollBox EULAScrollboxWidget;

	UPROPERTY()
	bool bAllowInput = true;

	bool bSnapToMainMenu = false;
	bool bIsLoadingProfile = false;
	bool bIsShowingEULA = false;
	bool bEverShowEULA = false;
	bool bProfileLoadingEvent = false;

	int BootOptionsIndex = -1;
	UBootOptionsPage BootOptionsPage;
	UGameSettingsBaseWidget HighlightedSetting;

	UPROPERTY()
	UOverlay BootOptionsContainer;

	UPROPERTY()
	ESplashWidgetState State = ESplashWidgetState::Prompt;

	UPROPERTY()
	TArray<TSubclassOf<UBootOptionsPage>> BootOptionsPages;

	TArray<FKey> ExcludedKeys;
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Down);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Up);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Left);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Right);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Down);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Up);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Left);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Right);
	default ExcludedKeys.Add(EKeys::LeftAlt);
	default ExcludedKeys.Add(EKeys::RightAlt);
	default ExcludedKeys.Add(EKeys::LeftControl);
	default ExcludedKeys.Add(EKeys::RightControl);
	default ExcludedKeys.Add(EKeys::LeftShift);
	default ExcludedKeys.Add(EKeys::RightShift);

	private bool bNarrateBootOptionsNextFrame = false;

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Super::Show(bSnap);

		// Take focus for *all* users, since we need players to be able to confirm
		Widget::SetAllPlayerUIFocus(this);
		bIsShowingEULA = false;
		bEverShowEULA = false;

		// If a primary identity is already set, use it
		if (Online::PrimaryIdentity != nullptr)
		{
			PendingIdentity = Online::PrimaryIdentity;
			bSnapToMainMenu = true;
			ProceedTakeMenuOwner();
		}
		else
		{
			bSnapToMainMenu = false;
		}

		auto AudioManager = GetAudioManager();
		AudioManager.UI_SplashBackgroundFadeIn();
		System::SetTimer(AudioManager, n"UI_SplashTextFadeIn", 0.6f, false);		
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowAccountPicker()
	{
		if (CVar_AlwaysShowEULA.GetInt() == 0)
		{
			if (!Online::RequiresIdentityEngagement())
				return false;
			if (!Game::IsConsoleBuild())
				return false;
		}

		if (PendingIdentity == nullptr)
			return false;

		if (BootOptionsIndex != -1)
			return true;
		if (State == ESplashWidgetState::EULA)
			return true;
		if (State == ESplashWidgetState::BootOptions)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintEvent)
	void SwitchToState(ESplashWidgetState NewState, ESplashWidgetState PreviousState) {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTIme)
	{
		if (PendingIdentity == nullptr && Online::PrimaryIdentity != nullptr && bIsActive)
		{
			PendingIdentity = Online::PrimaryIdentity;
			bSnapToMainMenu = true;
			ProceedTakeMenuOwner();
		}

		if (BootOptionsIndex != -1 &&
			(PendingIdentity == nullptr
			|| !Online::IsIdentitySignedIn(PendingIdentity)
			|| PendingIdentity.GetEngagement() != EHazeIdentityEngagement::Engaged))
		{
			BootOptionsIndex = -1;
			PendingIdentity = nullptr;
			Widget::SetAllPlayerUIFocus(this);
			Online::SetPrimaryIdentity(nullptr);
		}

		// Update which setting is highlighted
		if (HighlightedSetting == nullptr || !HighlightedSetting.IsHighlighted() || (HighlightedSetting != nullptr && BootOptionsIndex == -1))
		{
			auto PreviousHighlighted = HighlightedSetting;
			HighlightedSetting = nullptr;

			if (BootOptionsPage != nullptr)
			{
				for (auto Setting : BootOptionsPage.AllSettings)
				{
					if (Setting.IsHighlighted())
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
						BP_UpdateHoveredBootOption(SettingsDescription.Description);
					else
						BP_UpdateHoveredBootOption(FText());
				}
				else
				{
					BP_UpdateHoveredBootOption(FText());
				}
			}
		}

		if (bNarrateBootOptionsNextFrame)
		{
			bNarrateBootOptionsNextFrame = false;
			NarrateBootOptions();
		}

		UpdateStates();
	}

	void UpdateStates()
	{
		ESplashWidgetState NewState = ESplashWidgetState::Prompt;

		// Pick the correct mode between loading and prompt
		//  We will be in loading mode while the user's profile data
		//  is being loaded.
		if (IsMessageDialogShown() || !bIsActive)
		{
			NewState = ESplashWidgetState::None;
		}
		else if (PendingIdentity != nullptr)
		{
			if (bIsShowingEULA)
				NewState = ESplashWidgetState::EULA;
			else if (BootOptionsIndex != -1)
				NewState = ESplashWidgetState::BootOptions;
			else
				NewState = ESplashWidgetState::Loading;
		}
		else if (bIsLoadingProfile)
		{
			NewState = ESplashWidgetState::Loading;
		}

		if (NewState != State)
		{
			auto PrevState = State;
			State = NewState;
			SwitchToState(State, PrevState);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		auto Identity = Online::GetMainMenuIdentityAssociatedWithInputDevice(Event.ControllerId);

		if (bIsShowingEULA || BootOptionsIndex != -1)
		{
			if (PendingIdentity != nullptr && PendingIdentity.TakesInputFromControllerId(Event.ControllerId))
			{
				if ((Event.Key == EKeys::Gamepad_FaceButton_Top || Event.Key == EKeys::F1) && ShouldShowAccountPicker())
				{
					Online::PromptIdentitySignIn(PendingIdentity, FHazeOnOnlineIdentitySignedIn(this, n"OnPendingIdentityChanged"));
					return FEventReply::Handled();
				}
			}
		}

		if (bIsShowingEULA || IsMessageDialogShown() || Event.IsRepeat())
			return FEventReply::Unhandled();

		if (BootOptionsIndex != -1)
		{
			if (PendingIdentity.TakesInputFromControllerId(Event.ControllerId))
			{
				if (Event.Key == EKeys::Enter || Event.Key == EKeys::Virtual_Accept)
				{
					if (BootOptionsPage != nullptr && BootOptionsPage.bIsPrivacyOptions)
						OnTelemetryOptIn(EMessageDialogResponse::Yes);
					else
						BootOptionsContinue();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					if (BootOptionsPage != nullptr && BootOptionsPage.bIsPrivacyOptions)
						OnTelemetryOptIn(EMessageDialogResponse::No);
					else
						BootOptionsBack();
					return FEventReply::Handled();
				}
			}

			return FEventReply::Handled();
		}

		// Don't absorb anything if this is input without an identity,
		// this can happen on console platforms with keyboards.
		if (Identity == nullptr)
			return FEventReply::Unhandled();

		// We can't confirm with axes
		if (ExcludedKeys.Contains(Event.Key))
			return FEventReply::Unhandled();

		// Don't absorb certain special keys
		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Gamepad_Special_Left || Event.Key == EKeys::Tab)
			return FEventReply::Unhandled();

		// Don't absorb if focus is something outside of the game (ie console)
		if (Widget::IsPlayerUIFocusOutsideGame(Identity))
			return FEventReply::Unhandled();

		if (MainMenu.OwnerIdentity == nullptr && PendingIdentity == nullptr && bAllowInput)
		{
			PendingIdentity = Identity;
			PendingIdentity.OnInputTakenFromControllerId(Event.ControllerId, true);
			ProceedTakeMenuOwner();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		auto Identity = Online::GetMainMenuIdentityAssociatedWithInputDevice(Event.ControllerId);
		if (bIsShowingEULA || IsMessageDialogShown() || BootOptionsIndex != -1)
			return FEventReply::Unhandled();

		if ((Event.EffectingButton == EKeys::LeftMouseButton
			|| Event.EffectingButton == EKeys::RightMouseButton)
			&& (PendingIdentity == nullptr && MainMenu.OwnerIdentity == nullptr))
		{
			PendingIdentity = Identity;
			ProceedTakeMenuOwner();

			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void ProceedTakeMenuOwner()
	{
		if (MainMenu.OwnerIdentity != nullptr)
			return;
		if (PendingIdentity == nullptr)
			return;
		if (bIsShowingEULA)
			return;

		// Make sure we're signed in before allowing to use the main menu
		if (!Online::IsIdentitySignedIn(PendingIdentity))
		{
			auto SignInWithIdentity = PendingIdentity;
			PendingIdentity = nullptr;
			bIsLoadingProfile = true;
			Online::PromptIdentitySignIn(SignInWithIdentity, FHazeOnOnlineIdentitySignedIn(this, n"OnIdentitySignedIn"));
			return;
		}

		// Make sure the profile is loaded before we proceed to the menu
		if (!Profile::IsProfileLoaded(PendingIdentity))
		{
			Profile::LoadProfile(PendingIdentity, FHazeOnProfileLoaded(this, n"OnIdentityProfileLoaded"));
			return;
		}

		FString EULAValue;
		if (!Profile::GetProfileValue(PendingIdentity, n"EULA_Accepted", EULAValue) || EULAValue != "true"
			|| (CVar_AlwaysShowEULA.GetInt() != 0 && !bEverShowEULA))
		{
			bEverShowEULA = true;
			bIsShowingEULA = true;
			UpdateStates();
			if (ShouldAutoAcceptEULA() && CVar_AlwaysShowEULA.GetInt() == 0)
				EULAAccepted();
			return;
		}

		// Wait for all boot options to be completed
		if (BootOptionsIndex != -1)
			return;

		// All steps completed!
		auto FinishedIdentity = PendingIdentity;
		PendingIdentity = nullptr;
		MainMenu.ConfirmMenuOwner(FinishedIdentity, bSnapToMainMenu);
		auto AudioManager = GetAudioManager();

		AudioManager.UI_SplashScreenConfirm();
		System::SetTimer(AudioManager, n"UI_SplashBackgroundFadeOut", 1.f, false);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_MainMenu_Progression", 1.f, 2500.f);			
	}

	bool ShouldAutoAcceptEULA()
	{
		// When we're debugging EULA we should show it regardless
		if (CVar_AlwaysShowEULA.GetInt() != 0)
			return false;

		// On console we should show EULA on first boot
		if (Game::IsConsoleBuild())
			return false;

		// On PC we don't need to show EULA, Origin has done it for us
		return true;
	}

	UFUNCTION()
	void EULAAccepted()
	{
		if (PendingIdentity == nullptr || !bIsShowingEULA)
			return;

		bIsShowingEULA = false;
		Profile::SetProfileValue(PendingIdentity, n"EULA_Accepted", "true");

		if (BootOptionsPages.Num() != 0)
			ShowBootOptions(0);
		else
			ProceedTakeMenuOwner();
	}

	UFUNCTION()
	void OnTelemetryOptIn(EMessageDialogResponse Response)
	{
		if (PendingIdentity == nullptr || MainMenu.OwnerIdentity != nullptr)
			return;

		GameSettings::SetGameSettingsProfile(PendingIdentity, bApplySettings = false);
		if (Response == EMessageDialogResponse::Yes)
		{
			GameSettings::SetGameSettingsValue(n"TelemetryOptIn", "On");
		}
		else
		{
			GameSettings::SetGameSettingsValue(n"TelemetryOptIn", "Off");
		}

		GetAudioManager().UI_OnSelectionConfirmed();
		BootOptionsContinue();
	}

	void ShowBootOptions(int Page)
	{
		GameSettings::SetGameSettingsProfile(PendingIdentity, bApplySettings = false);
		BootOptionsIndex = Page;

		if (BootOptionsPage != nullptr)
		{
			BootOptionsPage.RemoveFromParent();
			BootOptionsPage = nullptr;
		}

		BootOptionsPage = Cast<UBootOptionsPage>(Widget::CreateWidget(this, BootOptionsPages[Page].Get()));
		BootOptionsPage.SplashWidget = this;
		HighlightedSetting = nullptr;

		auto BootOptionsSlot = Cast<UOverlaySlot>(BootOptionsContainer.AddChild(BootOptionsPage));
		BootOptionsSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Fill);
		BootOptionsSlot.SetHorizontalAlignment(EHorizontalAlignment::HAlign_Fill);

		if (State == ESplashWidgetState::BootOptions)
			SetInitialFocus();

		UpdateStates();
		BP_ShowBootOptions(BootOptionsPage);

		if (BootOptionsPage.bIsPrivacyOptions && Online::IsIdentityUnderage(PendingIdentity))
			OnTelemetryOptIn(EMessageDialogResponse::No);

		bNarrateBootOptionsNextFrame = true;
	}

	UFUNCTION()
	void BootOptionsContinue()
	{
		if (BootOptionsPage != nullptr)
			BootOptionsPage.Apply();

		if (BootOptionsPages.IsValidIndex(BootOptionsIndex+1))
		{
			ShowBootOptions(BootOptionsIndex+1);
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			BootOptionsIndex = -1;
			GameSettings::ApplyGameSettingsKeyBindings();
			ProceedTakeMenuOwner();
		}
	}

	UFUNCTION()
	void BootOptionsBack()
	{
		if (BootOptionsPage != nullptr)
			BootOptionsPage.Apply();

		if (BootOptionsPages.IsValidIndex(BootOptionsIndex-1))
		{
			ShowBootOptions(BootOptionsIndex-1);
			GetAudioManager().UI_OnSelectionConfirmed();
		}
	}

	UFUNCTION(BlueprintPure)
	bool BootOptionsCanBack()
	{
		if (BootOptionsPage == nullptr)
			return false;
		return BootOptionsPages.IsValidIndex(BootOptionsIndex-1);
	}

	UFUNCTION()
	void EULADeclined()
	{
		if (PendingIdentity == nullptr || !bIsShowingEULA)
			return;

		bIsShowingEULA = false;
		PendingIdentity = nullptr;
		bEverShowEULA = false;
		UpdateStates();

		Widget::SetAllPlayerUIFocus(this);
		Online::SetPrimaryIdentity(nullptr);
	}

	UFUNCTION()
	void OnIdentityProfileLoaded(UHazePlayerIdentity Identity)
	{
		ProceedTakeMenuOwner();
	}

	UFUNCTION()
	void OnIdentitySignedIn(UHazePlayerIdentity Identity, bool bSuccess)
	{
		bIsLoadingProfile = false;
		if (bSuccess && PendingIdentity == nullptr)
		{
			PendingIdentity = Identity;
			ProceedTakeMenuOwner();
		}
	}

	UFUNCTION()
	void OnPendingIdentityChanged(UHazePlayerIdentity Identity, bool bSuccess)
	{
		if (!bSuccess)
			return;
		if (PendingIdentity == Identity)
			return;

		bIsShowingEULA = false;
		bEverShowEULA = false;
		BootOptionsIndex = -1;
		PendingIdentity = Identity;
		ProceedTakeMenuOwner();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (bIsShowingEULA || IsMessageDialogShown() || BootOptionsIndex != -1)
			return FEventReply::Unhandled();

		// Always focus the splash when clicked
		return FEventReply::Handled().SetUserFocus(this, true);
	}

	UFUNCTION()
	void SetInitialFocus()
	{
		Widget::SetAllPlayerUIFocus(GetInitialFocusWidget());
	}

	UFUNCTION(BlueprintOverride)
	UWidget GetInitialFocusWidget()
	{
		if (BootOptionsPage != nullptr && BootOptionsIndex != -1)
			return BootOptionsPage.BP_GetInitialFocus();
		return this;
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateHoveredBootOption(FText Description)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowBootOptions(UBootOptionsPage Page) {}

	UFUNCTION(BlueprintEvent)
	FSplashOptionsButtons GetButtonsForNarration()
	{
		return FSplashOptionsButtons();
	}

	void NarrateBootOptions()
	{
		if (!Game::IsNarrationEnabled())
			return;

		if (State != ESplashWidgetState::BootOptions)
		{
			PrintToScreen("SPLASH NOT IN BootOptions", 10.0, FLinearColor::Red);
			return;
		}

		FString NarrationString = "";

		if (BootOptionsPage != nullptr)
		{
			NarrationString += BootOptionsPage.GetPageDisplayName().ToString() + ", ";
		}

		if (HighlightedSetting != nullptr)
		{
			NarrationString += HighlightedSetting.GetFullNarrationText() + ", ";
		}

		FSplashOptionsButtons Buttons = GetButtonsForNarration();

		FString ControlNarration;
		FString ButtonNarration;
		
		if (Buttons.BackButton.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";
		
		if (Buttons.ContinueButton.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (!ControlNarration.IsEmpty())
			NarrationString += "Menu Controls, " + ControlNarration;

		Game::NarrateString(NarrationString);
	}
};

void ResetEULA(const TArray<FString>& Args)
{
	auto Identity = Online::GetPrimaryIdentity();
	if (Identity != nullptr)
		Profile::SetProfileValue(Identity, n"EULA_Accepted", "false");
}