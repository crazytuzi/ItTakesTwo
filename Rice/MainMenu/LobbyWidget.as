import Rice.MainMenu.MainMenu;
import Rice.MessageDialog.MessageDialogStatics;
import Rice.MainMenu.TTSUI;
import Rice.GUI.AccessibilityChatWidget;
import Rice.PauseMenu.PauseMenuSingleton;

event void FLobbyMemberInteraction(ULobbyMemberWidget LobbyMember);

struct FLobbyMemberJoinButtons
{
	UPROPERTY()
	UHazeInputButton JoinButton;

	UPROPERTY()
	UHazeInputButton JoinButton_KB;
}

class ULobbyMemberWidget : UHazeUserWidget
{
	UPROPERTY()
	UHazeLobby Lobby;

	UPROPERTY()
	UHazePlayerIdentity Identity;

	UPROPERTY()
	FHazeLobbyMember MemberData;

	UPROPERTY()
	bool bIsOwner = false;

	UPROPERTY()
	bool bIsBusy = false;

	UPROPERTY()
	bool bIsChapterSelect = false;

	UPROPERTY()
	FLobbyMemberInteraction OnLeftArrowClicked;
	UPROPERTY()
	FLobbyMemberInteraction OnRightArrowClicked;
	UPROPERTY()
	FLobbyMemberInteraction OnClicked;

	UFUNCTION(BlueprintPure)
	bool IsChapterSelect()
	{
		return bIsChapterSelect;
	}

	UFUNCTION(BlueprintPure)
	bool IsCharacterSelect()
	{
		return !bIsChapterSelect;
	}

	UFUNCTION(BlueprintPure)
	bool CanInteractWithMouse()
	{
		if (Identity == nullptr || !Identity.IsLocal())
			return false;
		return Identity.TakesInputFromControllerId(-1);
	}

	UFUNCTION(BlueprintPure)
	EHazeSelectPlayer GetSelectedPlayer()
	{
		switch (MemberData.ChosenPlayer)
		{
			case EHazePlayer::May:
				return EHazeSelectPlayer::May;
			case EHazePlayer::Cody:
				return EHazeSelectPlayer::Cody;
		}

		return EHazeSelectPlayer::None;
	}

	UFUNCTION(BlueprintPure)
	EHazePlayerControllerType GetControllerType()
	{
		if (Identity == nullptr)
		{
			auto LikelyType = Lobby::GetMostLikelyControllerType();
			if (LikelyType == EHazePlayerControllerType::Keyboard)
				return EHazePlayerControllerType::Xbox;
			else
				return LikelyType;
		}
		return Identity.GetControllerType();
	}

	UFUNCTION(BlueprintEvent)
	FLobbyMemberJoinButtons GetGamepadButtons() { return FLobbyMemberJoinButtons(); }

	bool MakeNarrationString(FString& OutNarrationString)
	{
		FLobbyMemberJoinButtons Buttons = GetGamepadButtons();

		OutNarrationString = Game::KeyToNarrationText(EKeys::Virtual_Accept, GetControllerType()).ToString() + ", ";

		if (Buttons.JoinButton_KB.IsVisible())
		{
			OutNarrationString += " or " + Buttons.JoinButton_KB.OverrideKey.GetDisplayName().ToString() + ", ";
		}

		OutNarrationString += "Join Lobby";
		return true;
	}
};

class ULobbyWidget : UMainMenuStateWidget
{
	UHazeLobby Lobby;

	UPROPERTY()
	UHazeChapterDatabase ChapterDatabase;

	UPROPERTY()
	UHazePlayerIdentity PendingJoinIdentity;
	UPROPERTY()
	bool bIsPendingSignIn = false;

	UFUNCTION(BlueprintEvent)
	ULobbyMemberWidget GetLobbyOwnerWidget()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	ULobbyMemberWidget GetLobbyJoinerWidget()
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (HandleTTSKeyInput(Event))
			return FEventReply::Handled();

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Lobby = Lobby::GetLobby();
		ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();

		Super::Show(bSnap);

		// Take focus for *all* users, since we need players to be able to join
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION(BlueprintOverride)
	void Hide(bool bSnap)
	{
		Super::Hide(bSnap);
		PendingJoinIdentity = nullptr;
	}

	UFUNCTION(BlueprintPure)
	FString GetLobbyDebugString()
	{
		if (Lobby == nullptr)
			return "";
		return Lobby.Debug_GetStatus();
	}

	UFUNCTION(BlueprintPure)
	bool IsOnlineLobby()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.Network != EHazeLobbyNetwork::Local;
	}

	UFUNCTION(BlueprintPure)
	bool IsJoinLobby()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.Network == EHazeLobbyNetwork::Join;
	}

	UFUNCTION(BlueprintPure)
	bool IsContinueSelected()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.StartType == EHazeLobbyStartType::Continue;
	}

	UFUNCTION(BlueprintPure)
	bool IsNewGameSelected()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.StartType == EHazeLobbyStartType::NewGame;
	}

	UFUNCTION(BlueprintPure)
	bool IsMinigamesSelected()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.StartType == EHazeLobbyStartType::PickMinigame;
	}

	UFUNCTION(BlueprintPure)
	FText GetSelectedChapterName()
	{
		if (Lobby == nullptr)
			return FText();
		return ChapterDatabase.GetChapterByProgressPoint(Lobby.StartChapter).Name;
	}

	bool AreAllPlayersReady()
	{
		if (Lobby.LobbyMembers.Num() != 2)
			return false;

		for (auto& Member : Lobby.LobbyMembers)
		{
			if (!Member.bReady)
				return false;
		}

		return true;
	}

	UFUNCTION()
	void LeaveLobby()
	{
		if (Lobby.Network == EHazeLobbyNetwork::Local)
		{
			// Just leave immediately for local lobbies, not a big deal
			Lobby::Menu_LeaveLobby();
		}
		else
		{
			// Confirm for disconnecting from online lobby
			FMessageDialog Dialog;
			Dialog.Type = EMessageDialogType::YesNo;
			Dialog.Message = NSLOCTEXT("Lobby", "LeavyLobbyQuestion", "Disconnect from the online lobby?");
			Dialog.ConfirmText = NSLOCTEXT("Lobby", "ConfirmLeaveLobby", "Disconnect");
			Dialog.CancelText = NSLOCTEXT("Lobby", "CancelLeaveLobby", "Cancel");
			Dialog.OnClosed.BindUFunction(this, n"Confirm_LeaveLobby");

			GetAudioManager().UI_PopupMessageOpen();
			ShowPopupMessage(Dialog);
		}
	}

	UFUNCTION()
	void Confirm_LeaveLobby(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			Lobby::Menu_LeaveLobby();
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_MainMenu_Progression", 1.f, 100.f);
			GetAudioManager().UI_ReturnToMenuRoot();
		}
		else
			GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		if (!bIsActive)
			return;

		// Update UI for lobby owner
		{
			auto MemberWidget = GetLobbyOwnerWidget();
			MemberWidget.Lobby = Lobby;
			MemberWidget.Identity = Lobby.LobbyMembers[0].Identity;
			MemberWidget.bIsOwner = true;
			MemberWidget.MemberData = Lobby.LobbyMembers[0];
		}

		// Update UI for lobby joiner
		{
			auto MemberWidget = GetLobbyJoinerWidget();
			MemberWidget.Lobby = Lobby;
			MemberWidget.bIsOwner = false;

			if (Lobby.LobbyMembers.Num() >= 2)
			{
				MemberWidget.Identity = Lobby.LobbyMembers[1].Identity;
				MemberWidget.MemberData = Lobby.LobbyMembers[1];
			}
			else
			{
				MemberWidget.Identity = nullptr;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	int NumIdentitiesInLobby()
	{
		return Lobby.NumIdentitiesInLobby();
	}

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
};