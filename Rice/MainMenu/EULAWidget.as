import Rice.MessageDialog.MessageDialogStatics;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

event void FEULAEvent();

// Display for a single license that should be displayed
struct FLicenseContent
{
	UPROPERTY()
	FString Title;
	UPROPERTY(Meta = (MultiLine = true))
	FString Text;
};

struct FEULAButtons
{
	UPROPERTY()
	FText TitleText;

	UPROPERTY()
	UMenuPromptOrButton DeclineButton;

	UPROPERTY()
	UMenuPromptOrButton AcceptButton;
}

// An asset that keeps culture variants of licenses
class ULicenseAsset : UDataAsset
{
	UPROPERTY()
	TMap<FString, FLicenseContent> LicensesByCulture;

	FLicenseContent GetLicenseForCulture(FString Culture)
	{
		Log("Retrieving license for culture "+Culture);
		FLicenseContent OutLicense;

		// Check for a license for this culture
		if (LicensesByCulture.Find(Culture, OutLicense))
			return OutLicense;

		// Check for a license with only the language from the culture
		if (Culture.Len() > 2 && LicensesByCulture.Find(Culture.Left(2), OutLicense))
			return OutLicense;

		// Check for chinese alternatives
		if (Culture == "zh-Hans" || Culture == "zh-Hans-CN" || Culture == "zh")
		{
			if (LicensesByCulture.Find("zh-CN", OutLicense))
				return OutLicense;
		}
		else if (Culture == "zh-Hant" || Culture == "zh-Hant-CN")
		{
			if (LicensesByCulture.Find("zh-TW", OutLicense))
				return OutLicense;
		}

		// Fall back to english license
		if (LicensesByCulture.Find("en", OutLicense))
			return OutLicense;

		// A dummy license
		OutLicense.Title = "Dummy License";
		OutLicense.Text = "No text was found for culture "+Culture;
		return OutLicense;
	}
};

enum EEULAState
{
	EULA,
	PrivacyStatement,
	OpenSource,
};

class UEULAWidget : UHazeUserWidget
{
	UPROPERTY()
	ULicenseAsset OpenSourceLicense;
	UPROPERTY()
	TMap<FString, ULicenseAsset> EULALicenseByPlatform;
	UPROPERTY()
	TMap<FString, ULicenseAsset> PrivacyLicenseByPlatform;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EEULAState State = EEULAState::EULA;

	UPROPERTY()
	bool bShowOnly = false;

	UPROPERTY(NotEditable)
	UHazePlayerIdentity Identity;

	UPROPERTY(NotEditable)
	UScrollBox TextScrollWidget;

	UPROPERTY()
	FEULAEvent OnAcceptedEULA;
	UPROPERTY()
	FEULAEvent OnDeclinedEULA;

	float CurScrollLeft = 0.f;
	float CurScrollRight = 0.f;

	bool bAcceptDown = false;
	bool bDeclineDown = false;

	private bool bNarrateNextFrame = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLicenseContent LicenseContent;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (bShowOnly)
			SwitchToState(EEULAState::OpenSource);
		else
			SwitchToState(EEULAState::PrivacyStatement);
		DeleteUnneededLicenses();
	}

	void DeleteUnneededLicenses()
	{
		TArray<ULicenseAsset> NeededLicenses;
		TArray<ULicenseAsset> UnneededLicenses;

		for (auto Elem : EULALicenseByPlatform)
		{
			if (Elem.Key == Game::GetPlatformName())
			{
				NeededLicenses.AddUnique(Elem.Value);
				UnneededLicenses.Remove(Elem.Value);
			}
			else if (!NeededLicenses.Contains(Elem.Value))
			{
				UnneededLicenses.AddUnique(Elem.Value);
			}
		}

		for (auto Elem : PrivacyLicenseByPlatform)
		{
			if (Elem.Key == Game::GetPlatformName())
			{
				NeededLicenses.AddUnique(Elem.Value);
				UnneededLicenses.Remove(Elem.Value);
			}
			else if (!NeededLicenses.Contains(Elem.Value))
			{
				UnneededLicenses.AddUnique(Elem.Value);
			}
		}

		for (ULicenseAsset UnneededAsset : UnneededLicenses)
		{
			Log("Unneeded License: "+UnneededAsset);
#if !EDITOR
			Debug::Dangerous_MarkAssetPendingKill(UnneededAsset);
#endif
		}
	}

	UFUNCTION()
	void UpdateEULAText()
	{
		SwitchToState(State);
	}

	void SwitchToState(EEULAState NewState)
	{
		State = NewState;

		ULicenseAsset LicenseAsset;
		if (NewState == EEULAState::OpenSource)
		{
			LicenseAsset = OpenSourceLicense;
		}
		else if (NewState == EEULAState::EULA)
		{
			if (!EULALicenseByPlatform.Find(Game::GetPlatformName(), LicenseAsset))
				LicenseAsset = ULicenseAsset();
		}
		else
		{
			if (!PrivacyLicenseByPlatform.Find(Game::GetPlatformName(), LicenseAsset))
				LicenseAsset = ULicenseAsset();
		}

		if (LicenseAsset == nullptr)
			LicenseAsset = ULicenseAsset();
		LicenseContent = LicenseAsset.GetLicenseForCulture(Internationalization::GetCurrentCulture());

		FText PromptQuestion;
		FText AcceptButton;
		FText DeclineButton;

		if (State == EEULAState::PrivacyStatement || State == EEULAState::OpenSource)
		{
			PromptQuestion = FText();
			AcceptButton = NSLOCTEXT("EULA", "NextButton", "Next");
			DeclineButton = FText();
		}
		else if (Online::IsEUBuild(Identity))
		{
			PromptQuestion = NSLOCTEXT("EULA", "AcceptQuestion_EU", "I accept the User Agreement and understand EA's Privacy and Cookie Policy applies to my use of EA's services. I consent to any personal data collected through my use of EA's services being transferred to EA in the United States, as further explained in the Privacy and Cookie Policy.");
			AcceptButton = NSLOCTEXT("EULA", "AcceptButton_EU", "Continue");
			DeclineButton = NSLOCTEXT("EULA", "DeclineButton_EU", "Cancel");
		}
		else
		{
			PromptQuestion = NSLOCTEXT("EULA", "AcceptQuestion_WW", "I have read and accept the User Agreement and EA's Privacy and Cookie Policy.");
			AcceptButton = NSLOCTEXT("EULA", "AcceptButton_WW", "Accept");
			DeclineButton = NSLOCTEXT("EULA", "DeclineButton_WW", "Decline");
		}

		BP_ShowLicense(LicenseContent, PromptQuestion, AcceptButton, DeclineButton);
		bNarrateNextFrame = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowLicense(FLicenseContent Content, FText PromptQuestion, FText AcceptButton, FText DeclineButton) {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float TotalScroll = CurScrollLeft + CurScrollRight;
		if (FMath::Abs(TotalScroll) > 0.4f)
		{
			float ScrollAmount = 10.f * TotalScroll;
			float NewScrollOffset = TextScrollWidget.ScrollOffset + ScrollAmount;
			NewScrollOffset = FMath::Clamp(NewScrollOffset, 0.f, TextScrollWidget.ScrollOffsetOfEnd);
			TextScrollWidget.SetScrollOffset(NewScrollOffset);
		}

		if (bNarrateNextFrame)
		{
			NarrateFull();
			bNarrateNextFrame = false;
		}

		// Close the EULA if we no longer have a user that can accept it
		if (Identity != nullptr && (!Online::IsIdentitySignedIn(Identity) || Identity.GetEngagement() != EHazeIdentityEngagement::Engaged))
			OnDeclinedEULA.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		CurScrollLeft = 0.f;
		CurScrollRight = 0.f;
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		CurScrollLeft = 0.f;
		CurScrollRight = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (Identity != nullptr && !Identity.TakesInputFromControllerId(InAnalogInputEvent.ControllerId))
				return FEventReply::Unhandled();
		}

		if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftY)
		{
			CurScrollLeft = -InAnalogInputEvent.AnalogValue;
			return FEventReply::Handled();
		}
		else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightY)
		{
			CurScrollRight = -InAnalogInputEvent.AnalogValue;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Visibility == ESlateVisibility::Collapsed)
			return FEventReply::Unhandled();

		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (Identity != nullptr && !Identity.TakesInputFromControllerId(Event.ControllerId))
				return FEventReply::Unhandled();
		}

		if (Event.Key == EKeys::Virtual_Accept
			|| Event.Key == EKeys::Enter)
		{
			bAcceptDown = true;
			return FEventReply::Handled();
		}
		else if (Event.Key == EKeys::Virtual_Back
				|| Event.Key == EKeys::Escape)
		{
			bDeclineDown = true;
			bAcceptDown = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void AcceptEULA()
	{
		if (State == EEULAState::OpenSource)
		{
			SwitchToState(EEULAState::PrivacyStatement);
		}
		else if (State == EEULAState::PrivacyStatement)
		{
			SwitchToState(EEULAState::EULA);
		}
		else
		{
			if (bShowOnly)
				SwitchToState(EEULAState::OpenSource);
			else
				SwitchToState(EEULAState::PrivacyStatement);
			OnAcceptedEULA.Broadcast();
		}

		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void DeclineEULA()
	{
		if (State == EEULAState::EULA)
		{
			FMessageDialog Dialog;
			if (Online::IsEUBuild())
				Dialog.Message = NSLOCTEXT("EULA", "DeclinePrompt_EU", "You must accept the User Agreement to play this game. You understand EA's Privacy & Cookie Policy applies.");
			else
				Dialog.Message = NSLOCTEXT("EULA", "DeclinePrompt_WW", "You must accept the User Agreement and EA's Privacy & Cookie Policy to play this game.");

			Dialog.OnClosed.BindUFunction(this, n"EULADeclineDialog");

			if (!Game::IsConsoleBuild())
			{
				// Allow user to exit the game from declining the EULA
				Dialog.Type = EMessageDialogType::YesNo;
				Dialog.ConfirmText = NSLOCTEXT("EULA", "Decline_Continue", "Continue");
				Dialog.CancelText = NSLOCTEXT("EULA", "Decline_Exit", "Quit Game");
			}

			ShowPopupMessage(Dialog);
			GetAudioManager().UI_PopupMessageOpen();
		}
		else
		{
			if (State == EEULAState::PrivacyStatement && bShowOnly)
				SwitchToState(EEULAState::OpenSource);
			else
				SwitchToState(EEULAState::PrivacyStatement);
			OnDeclinedEULA.Broadcast();
		}
	}

	UFUNCTION()
	private void EULADeclineDialog(EMessageDialogResponse Response)
	{
		SwitchToState(EEULAState::PrivacyStatement);
		OnDeclinedEULA.Broadcast();

		if (Response == EMessageDialogResponse::No)
			Game::QuitGame();
		else
			GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (Identity != nullptr && !Identity.TakesInputFromControllerId(Event.ControllerId))
				return FEventReply::Unhandled();
		}

		if (Event.Key == EKeys::Virtual_Accept
			|| Event.Key == EKeys::Enter)
		{
			if (bAcceptDown)
				AcceptEULA();
			bAcceptDown = false;
			return FEventReply::Handled();
		}
		else if (Event.Key == EKeys::Virtual_Back
				|| Event.Key == EKeys::Escape)
		{
			if (bDeclineDown && !bShowOnly && State == EEULAState::EULA)
				DeclineEULA();
			bDeclineDown = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	FEULAButtons GetButtonsForNarration()
	{
		return FEULAButtons();
	}

	void NarrateFull()
	{
		if (!Game::IsNarrationEnabled())
			return;
		
		FEULAButtons Buttons = GetButtonsForNarration();

		FString NarrationString = Buttons.TitleText.ToString() + ", ";

		FString ControlNarration;
		FString ButtonNarration;
		
		if (Buttons.DeclineButton.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";
		
		if (Buttons.AcceptButton.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (!ControlNarration.IsEmpty())
			NarrationString += ControlNarration;

		Game::NarrateString(NarrationString);
	}

};