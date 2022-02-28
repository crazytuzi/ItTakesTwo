import Rice.MainMenu.LobbyWidget;
import Rice.ChapterSelect.ChapterSelectPickerWidget;
import Rice.MinigamePicker.MinigamePickerWidget;

event void FOnCategoryPressed();

const FConsoleVariable CVar_AlwaysShowFriendsPassPopup("Haze.AlwaysShowFriendsPassPopup", 0);

struct FChapterSelectButtons
{
	// Top Banner
	UPROPERTY()
	UChapterSelectCategoryWidget NewGame;

	UPROPERTY()
	UChapterSelectCategoryWidget Continue;

	UPROPERTY()
	UChapterSelectCategoryWidget ChapterSelect;

	UPROPERTY()
	UChapterSelectCategoryWidget Minigames;

	// Controls
	UPROPERTY()
	UMenuPromptOrButton LeftTab;

	UPROPERTY()
	UMenuPromptOrButton RightTab;

	UPROPERTY()
	UMenuPromptOrButton Back;

	UPROPERTY()
	UMenuPromptOrButton Invite;

	UPROPERTY()
	UMenuPromptOrButton FP;

	UPROPERTY()
	UMenuPromptOrButton Proceed;
}

class UChapterSelectCategoryWidget : UHazeUserWidget
{
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FText Text;

	UPROPERTY()
	bool bIsSelected = false;

	UPROPERTY()
	bool bIsButtonEnabled = true;

	private bool bHovered = false;

	UPROPERTY()
	FOnCategoryPressed OnPressed;

	UFUNCTION(BlueprintPure)
	bool IsButtonHovered()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return false;
		return bHovered && bIsButtonEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsClickableByMouse()
	{
		return !Game::IsConsoleBuild();
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonEnabledOrRemote()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return true;
		return bIsButtonEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsUsableByController()
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return;

		if(!bIsSelected)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", 0.f);
			GetAudioManager().UI_OnSelectionChanged_Hover_Background_Mouse();
		}

		Game::NarrateText(Text);

		bHovered = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
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
			if (bIsButtonEnabled)
				OnPressed.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}
};

class UChapterSelectWidget : ULobbyWidget
{
	UPROPERTY()
	UChapterSelectPickerWidget ChapterPicker;
	UPROPERTY()
	UMinigamePickerWidget MinigamePicker;

	FKCodeHandler KCodeHandler;

	default bCustomNavigation = true;

	bool bHasContinue = false;
	bool bInFriendsPassPopup = false;

	float EngagementGraceTimer = 0.f;
	FHazeProgressPointRef ContinueChapter;
	FHazeProgressPointRef ContinuePoint;
	EHazeLobbyStartType CurrentStartType = EHazeLobbyStartType::NewGame;

	private bool bNarrateNextTick = false;

	private FString ConinueNarrationText = "";

	int PlayersInLobby = 1;
	private bool bHasTickedForSound = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ChapterPicker.OnChapterSelectChanged.AddUFunction(this, n"OnChapterPickerChanged");
		MinigamePicker.OnMinigameSelected.AddUFunction(this, n"OnMinigamePicked");
	}

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Super::Show(bSnap);

		if (Lobby == nullptr)
			return;

		// Select continue in chapter select if available
		if (Lobby.LobbyOwner.IsLocal() && MainMenu.bIsNewLobby)
		{
			bHasContinue = Save::GetContinueProgress(ContinueChapter, ContinuePoint);
			if (bHasContinue)
			{
				FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
				FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);

				BP_SetContinueChapter(Group, Chapter);
				ConinueNarrationText = Group.GroupName.ToString() + ", " + Chapter.Name.ToString() + ", ";

				if (Lobby.StartType == EHazeLobbyStartType::NewGame)
				{
					if (Save::IsContinueStartable(ContinueChapter, ContinuePoint))
						ChapterPicker.SelectChapter(Chapter.ProgressPoint);
					else
						ChapterPicker.SelectChapter(ChapterDatabase.GetInitialChapter());

					Lobby::Menu_LobbySelectStart(EHazeLobbyStartType::Continue, ContinueChapter, ContinuePoint);
				}
				else
				{
					ChapterPicker.SelectChapter(Lobby.StartChapter);
				}
			}
			MainMenu.bIsNewLobby = false;
		}

		// Unselect a character if we have any selected
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity != nullptr && Member.Identity.IsLocal()
				&& Member.ChosenPlayer != EHazePlayer::MAX)
			{
				Lobby::Menu_LobbySetReady(Member.Identity, false);
				Lobby::Menu_LobbySelectPlayer(Member.Identity, EHazePlayer::MAX);
			}
		}

		// Prepare minigame picker
		MinigamePicker.Initialize();

		// Show friends pass popup if it's the first time we've gone online
		if (ShouldShowFriendsPassInfo())
		{
			FString ShownValue;
			if (!Profile::GetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", ShownValue)
				|| ShownValue != "True" || CVar_AlwaysShowFriendsPassPopup.GetInt() != 0)
			{
				ShowFriendsPassPopup();
				Profile::SetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", "True");
			}
		}

		BindMemberEvents(GetLobbyOwnerWidget());
		BindMemberEvents(GetLobbyJoinerWidget());
		PlayersInLobby = 1;
		bHasTickedForSound = false;
	}

	void BindMemberEvents(ULobbyMemberWidget MemberWidget)
	{
		if (MemberWidget == nullptr)
			return;
		MemberWidget.OnClicked.AddUFunction(this, n"OnMemberClicked");
	}

	UFUNCTION()
	private void OnMemberClicked(ULobbyMemberWidget Member)
	{
		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(-1);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(-1);

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(-1))
		)
		{
			// Join a local lobby
			PendingJoinIdentity = KeyIdentity;
			if (KeyIdentityInLobby == nullptr)
				KeyIdentity.OnInputTakenFromControllerId(-1, true);
			ProceedPendingJoin();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetContinueChapter(FHazeChapterGroup ChapterGroup, FHazeChapter Chapter) {}

	UFUNCTION(BlueprintPure)
	bool CanInvitePlayer()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.Network == EHazeLobbyNetwork::Host
			&& Lobby.NumIdentitiesInLobby() < 2
			&& Online::HasInvitePrompt();
	}

	UFUNCTION(BlueprintPure)
	bool CanStartSelectedChapter()
	{
		if (Lobby == nullptr)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return true;

		switch (Lobby.StartType)
		{
			case EHazeLobbyStartType::NewGame:
				return true;
			case EHazeLobbyStartType::ChapterSelect:
			case EHazeLobbyStartType::Continue:
			case EHazeLobbyStartType::PickMinigame:
				return Save::IsContinueStartable(Lobby.StartChapter, Lobby.StartProgressPoint);
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasMinigamesUnlocked()
	{
		return MinigamePicker.bHasUnlockedMinigames;
	}

	UFUNCTION()
	void BrowseStartType(int BrowseDirection, bool bWrap = false)
	{
		EHazeLobbyStartType NewStartType = Lobby.StartType;
		while (true)
		{
			auto CheckingStartType = NewStartType;
			if (BrowseDirection < 0)
			{
				switch (NewStartType)
				{
					case EHazeLobbyStartType::NewGame:
						if (bWrap)
							NewStartType = EHazeLobbyStartType::PickMinigame;
					break;
					case EHazeLobbyStartType::Continue:
						NewStartType = EHazeLobbyStartType::NewGame;
					break;
					case EHazeLobbyStartType::ChapterSelect:
						NewStartType = EHazeLobbyStartType::Continue;
					break;
					case EHazeLobbyStartType::PickMinigame:
						NewStartType = EHazeLobbyStartType::ChapterSelect;
					break;
				}
			}
			else
			{
				switch (NewStartType)
				{
					case EHazeLobbyStartType::NewGame:
						NewStartType = EHazeLobbyStartType::Continue;
					break;
					case EHazeLobbyStartType::Continue:
						NewStartType = EHazeLobbyStartType::ChapterSelect;
					break;
					case EHazeLobbyStartType::ChapterSelect:
						NewStartType = EHazeLobbyStartType::PickMinigame;
					break;
					case EHazeLobbyStartType::PickMinigame:
						if (bWrap)
							NewStartType = EHazeLobbyStartType::NewGame;
					break;
				}
			}

			bool bIsStartTypeValid = true;
			switch (NewStartType)
			{
				case EHazeLobbyStartType::Continue:
					if (!bHasContinue)
						bIsStartTypeValid = false;
				break;
				case EHazeLobbyStartType::ChapterSelect:
					if (!bHasContinue)
						bIsStartTypeValid = false;
				break;
				case EHazeLobbyStartType::PickMinigame:
					if (!MinigamePicker.bHasUnlockedMinigames)
						bIsStartTypeValid = false;
				break;
			}

			if (NewStartType == Lobby.StartType)
				return;

			if (bIsStartTypeValid)
			{
				SetLobbyStartType(NewStartType);				
				return;
			}

			if (NewStartType == CheckingStartType)
				return;
		}
	}

	UFUNCTION()
	void SetLobbyStartType(EHazeLobbyStartType StartType)
	{
		if (!Lobby.LobbyOwner.IsLocal())
			return;

		switch (StartType)
		{
			case EHazeLobbyStartType::NewGame:
			{
				Lobby::Menu_LobbySelectStart(
					EHazeLobbyStartType::NewGame,
					ChapterDatabase.GetInitialChapter(),
					ChapterDatabase.GetInitialChapter());
			}
			break;
			case EHazeLobbyStartType::ChapterSelect:
			{
				if (HasContinueSave())
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::ChapterSelect,
						ChapterPicker.SelectedChapter.ProgressPoint,
						ChapterPicker.SelectedChapter.ProgressPoint);
				}
			}
			break;
			case EHazeLobbyStartType::Continue:
			{
				if (HasContinueSave())
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::Continue,
						ContinueChapter,
						ContinuePoint);
				}
			}
			break;
			case EHazeLobbyStartType::PickMinigame:
			{
				if (MinigamePicker.bHasUnlockedMinigames)
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::PickMinigame,
						MinigamePicker.GetSelectedMinigame(),
						MinigamePicker.GetSelectedMinigame());
				}
			}
			break;
		}
	}

	UFUNCTION()
	void InviteFriend()
	{
		if (CanInvitePlayer())
			Online::PromptForInvite();
	}

	UFUNCTION()
	void ProceedGame()
	{
		if (CanStartSelectedChapter())
			Lobby::Menu_LobbySetState(EHazeLobbyState::CharacterSelect);
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return nullptr;

		if (bInFriendsPassPopup)
			return nullptr;

		// We respond to navigation for chapter select,
		// so analog stick can be used for switching chapters.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.

		if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
		{
			if (Lobby.StartType == EHazeLobbyStartType::ChapterSelect)
			{
				if (Event.NavigationType == EUINavigation::Left)
				{
					ChapterPicker.NavigateGroup(-1);
				}
				else if (Event.NavigationType == EUINavigation::Right)
				{
					ChapterPicker.NavigateGroup(+1);
				}
				else if (Event.NavigationType == EUINavigation::Up)
				{
					ChapterPicker.NavigateChapter(-1);
				}
				else if (Event.NavigationType == EUINavigation::Down)
				{
					ChapterPicker.NavigateChapter(+1);
				}
			}
			else if (Lobby.StartType == EHazeLobbyStartType::PickMinigame)
			{
				if (Event.NavigationType == EUINavigation::Up)
				{
					MinigamePicker.BrowseMinigame(-1);
				}
				else if (Event.NavigationType == EUINavigation::Down)
				{
					MinigamePicker.BrowseMinigame(+1);
				}
			}
		}

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent Event)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();

		if (Lobby.StartType == EHazeLobbyStartType::PickMinigame)
		{
			if (Event.GetKey() == EKeys::Gamepad_RightY && FMath::Abs(Event.AnalogValue) > 0.4f)
			{
				MinigamePicker.Scroll(Event.AnalogValue * -400.f * Time::UndilatedWorldDeltaSeconds);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (KCodeHandler.AddInput(this, Event.Key))
			return FEventReply::Handled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Unhandled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.ControllerId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.ControllerId);

		// Deal with input to the friends pass popup
		if (bInFriendsPassPopup)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				if (Event.Key == EKeys::Enter || Event.Key == EKeys::Virtual_Accept
					|| Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					HideFriendsPassPopup();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::F1 || Event.Key == EKeys::Gamepad_FaceButton_Left)
				{
					ShowFriendsPassMoreInfo();
					return FEventReply::Handled();
				}
			}

			return Super::OnKeyDown(Geom, Event);
		}
		else
		{
			if (Event.Key == EKeys::F2 || Event.Key == EKeys::Gamepad_FaceButton_Left)
			{
				if (ShouldShowFriendsPassInfo())
				{
					ShowFriendsPassPopup();
					return FEventReply::Handled();
				}
			}
		}

		// Host can prompt to invite a player
		if (Event.Key == EKeys::Gamepad_FaceButton_Top
			|| Event.Key == EKeys::Y
			|| Event.Key == EKeys::F1)
		{
			if (CanInvitePlayer())
				Online::PromptForInvite();
			return FEventReply::Handled();
		}

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(Event.ControllerId))
		)
		{
			if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
			{
				// Join a local lobby
				PendingJoinIdentity = KeyIdentity;
				if (KeyIdentityInLobby == nullptr)
					KeyIdentity.OnInputTakenFromControllerId(Event.ControllerId, true);
				ProceedPendingJoin();
				return FEventReply::Handled();
			}
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// Leave lobby for local joined player
			if (KeyIdentityInLobby != nullptr && CanIdentityLeaveLobby(KeyIdentityInLobby) && Lobby.Network == EHazeLobbyNetwork::Local)
			{
				Lobby::Menu_RemoveLocalPlayerFromLobby(KeyIdentityInLobby);
				return FEventReply::Handled();
			}

			// Leave lobby for owner of menu, could be leaving a joined online lobby or a local lobby
			if (MainMenu.OwnerIdentity.TakesInputFromControllerId(Event.ControllerId))
			{
				LeaveLobby();
				return FEventReply::Handled();
			}
		}

		// Switch game start type
		if (Event.Key == EKeys::Gamepad_LeftShoulder)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				BrowseStartType(-1, bWrap = true);
				NarrateFullMenu();
				return FEventReply::Handled();
			}
		}

		if (Event.Key == EKeys::Gamepad_RightShoulder
			|| Event.Key == EKeys::Tab)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				BrowseStartType(+1, bWrap = true);
				NarrateFullMenu();
				return FEventReply::Handled();
			}
		}

		// Proceed to character select from chapter select
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId)
				&& NumIdentitiesInLobby() >= 2)
			{
				ProceedGame();
				GetAudioManager().UI_ProceedToCharacterSelect();
				return FEventReply::Handled();
			}
		}
		
		return Super::OnKeyDown(Geom, Event);
	}

	void ProceedPendingJoin()
	{
		if (Lobby.NumIdentitiesInLobby() >= 2)
		{
			PendingJoinIdentity = nullptr;
			return;
		}

		// Make sure we're signed in before we can join
		if (!Online::IsIdentitySignedIn(PendingJoinIdentity) || Lobby.IsMember(PendingJoinIdentity))
		{
			auto SignInWithIdentity = PendingJoinIdentity;
			PendingJoinIdentity = nullptr;
			bIsPendingSignIn = true;
			Online::PromptIdentitySignIn(SignInWithIdentity, FHazeOnOnlineIdentitySignedIn(this, n"OnJoinIdentitySignedIn"));
			return;
		}

		// Make sure the profile is loaded before we can join
		if (!Profile::IsProfileLoaded(PendingJoinIdentity))
		{
			Profile::LoadProfile(PendingJoinIdentity, FHazeOnProfileLoaded(this, n"OnJoinIdentityProfileLoaded"));
			return;
		}

		// All steps completed!
		auto FinishedIdentity = PendingJoinIdentity;
		PendingJoinIdentity = nullptr;
		EngagementGraceTimer = 1.f;
		Lobby::Menu_AddLocalIdentityToLobby(FinishedIdentity);
	}

	UFUNCTION()
	void OnJoinIdentityProfileLoaded(UHazePlayerIdentity Identity)
	{
		ProceedPendingJoin();
	}

	UFUNCTION()
	void OnJoinIdentitySignedIn(UHazePlayerIdentity Identity, bool bSuccess)
	{
		bIsPendingSignIn = false;
		if (bSuccess && PendingJoinIdentity == nullptr && !Lobby.IsMember(Identity))
		{
			PendingJoinIdentity = Identity;
			ProceedPendingJoin();
		}
	}

	UFUNCTION(BlueprintPure)
	bool HasContinueSave()
	{
		return bHasContinue;
	}

	UFUNCTION(BlueprintPure)
	bool CanProceedToCharacterSelect()
	{
		if (Lobby == nullptr)
			return false;
		if (!CanStartSelectedChapter())
			return false;
		return Lobby.LobbyOwner.IsLocal()
			&& NumIdentitiesInLobby() >= 2;
	}

	UFUNCTION(BlueprintPure)
	bool IsJoinInProgress()
	{
		return PendingJoinIdentity != nullptr || bIsPendingSignIn;
	}

	bool CanIdentityLeaveLobby(UHazePlayerIdentity Identity)
	{
		if (Identity == Lobby.LobbyMembers[1].Identity)
		{
			// Secondary player can always leave
			return true;
		}

		if (Identity == Lobby.LobbyMembers[0].Identity)
		{
			// Primary player can only leave on desktop platforms
			if (!Game::IsConsoleBuild())
				return true;
			else
				return false;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		Super::Tick(Geom, Timer);

		if (Lobby == nullptr)
			return;
		if (!bIsActive)
			return;

		// Proceed to character select if the lobby state has changed
		if (Lobby.LobbyState == EHazeLobbyState::CharacterSelect)
		{
			MainMenu.ProceedToCharacterSelect();
		}

		// If the secondary identity is disengaged, remove it from the lobby
		EngagementGraceTimer -= Timer;
		if (EngagementGraceTimer <= 0.f)
		{
			for (auto& Member : Lobby.LobbyMembers)
			{
				if (Member.Identity != nullptr && Member.Identity != Online::PrimaryIdentity)
				{
					if (Member.Identity.Engagement != EHazeIdentityEngagement::Engaged)
					{
						GetAudioManager().UI_OnSelectionCancel();
						Lobby::Menu_RemoveLocalPlayerFromLobby(Member.Identity);
					}
				}
			}
		}

		// Inform BP if the start type has changed
		if (CurrentStartType != Lobby.StartType)
		{
			BP_StartTypeChanged(CurrentStartType, Lobby.StartType);			
			CurrentStartType = Lobby.StartType;

			if(bHasTickedForSound)
				GetAudioManager().UI_StartModeUpdated();
		}

		// Inform chapter picker if chapter has changed in network
		if (!Lobby.LobbyOwner.IsLocal())
		{
			if (CurrentStartType == EHazeLobbyStartType::ChapterSelect)
			{
				if (Lobby.StartChapter.InLevel != ChapterPicker.SelectedChapter.ProgressPoint.InLevel
					|| Lobby.StartChapter.Name != ChapterPicker.SelectedChapter.ProgressPoint.Name)
				{
					ChapterPicker.SelectChapter(Lobby.StartChapter);
				}
			}
			else if (CurrentStartType == EHazeLobbyStartType::PickMinigame)
			{
				if (Lobby.StartChapter.InLevel != MinigamePicker.SelectedMinigame.InLevel
					|| Lobby.StartChapter.Name != MinigamePicker.SelectedMinigame.Name)
				{
					MinigamePicker.SelectMinigame(Lobby.StartChapter, false);
				}
			}
			else if (CurrentStartType == EHazeLobbyStartType::Continue)
			{
				if (Lobby.StartChapter.InLevel != ContinueChapter.InLevel
					|| Lobby.StartChapter.Name != ContinueChapter.Name)
				{
					ContinueChapter = Lobby.StartChapter;
					FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
					FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);
					BP_SetContinueChapter(Group, Chapter);
				}

			}
		}

		// Update busy state for pending profile loads
		auto PlayerTwoWidget = GetLobbyJoinerWidget();
		if (PlayerTwoWidget != nullptr)
			PlayerTwoWidget.bIsBusy = IsJoinInProgress();

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}

		const int NumPlayers = Lobby.NumIdentitiesInLobby();
		if(bHasTickedForSound)	
		{
			if(PlayersInLobby < NumPlayers)
				GetAudioManager().UI_OnPlayerJoin();
			else if(PlayersInLobby > NumPlayers)
				GetAudioManager().UI_OnPlayerLeave();
		}	

		bHasTickedForSound = true;
		PlayersInLobby = NumPlayers;		
	}

	UFUNCTION()
	private void OnChapterPickerChanged()
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			Lobby::Menu_LobbySelectStart(
				EHazeLobbyStartType::ChapterSelect,
				ChapterPicker.SelectedChapter.ProgressPoint,
				ChapterPicker.SelectedChapter.ProgressPoint
			);
		}
	}

	UFUNCTION()
	private void OnMinigamePicked(FHazeProgressPointRef ProgressPoint)
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			Lobby::Menu_LobbySelectStart(
				EHazeLobbyStartType::PickMinigame,
				MinigamePicker.SelectedMinigame,
				MinigamePicker.SelectedMinigame
			);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartTypeChanged(EHazeLobbyStartType PrevStartType, EHazeLobbyStartType NewStartType) {}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFriendsPassInfo()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return false;
		if (Lobby == nullptr)
			return false;
		if (Lobby.Network != EHazeLobbyNetwork::Host)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return false;
		if (Lobby.NumIdentitiesInLobby() >= 2)
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool IsTrialMode()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FullGame)
			return false;

		auto HazeGameInstance = Game::GetHazeGameInstance();
		if (HazeGameInstance == nullptr)
			return false;
		if (HazeGameInstance.bRemoteEntitlementSynced && HazeGameInstance.RemoteEntitlement == EHazeEntitlement::FullGame)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFullGameIndicator()
	{
		// If this is a trial lobby, show that
		if (IsTrialMode())
			return false;

		// If we are friend's pass in a full game lobby, show it
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return true;

		// Don't need to show full game to someone who owns the game
		return false;
	}

	UFUNCTION()
	void ShowFriendsPassPopup()
	{
		bInFriendsPassPopup = true;
		BP_ShowFriendsPassPopup();
	}

	UFUNCTION()
	void HideFriendsPassPopup()
	{
		bInFriendsPassPopup = false;
		BP_HideFriendsPassPopup();
	}

	UFUNCTION()
	void ShowFriendsPassMoreInfo()
	{
		Online::ShowFriendsPassInfo();
		HideFriendsPassPopup();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowFriendsPassPopup() {}

	UFUNCTION(BlueprintEvent)
	void BP_HideFriendsPassPopup() {}

	UFUNCTION(BlueprintEvent)
	FChapterSelectButtons GetButtonsForNarration()
	{
		return FChapterSelectButtons();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;

		FChapterSelectButtons Buttons = GetButtonsForNarration();

		FString FullNarration = "";
		FString ButtonNarration;
		
		switch (CurrentStartType)
		{
			case EHazeLobbyStartType::NewGame:
				FullNarration += Buttons.NewGame.Text.ToString() + ", ";
				break;
			case EHazeLobbyStartType::Continue:
				FullNarration += Buttons.Continue.Text.ToString() + ", ";
				if (bHasContinue)
				{
					FullNarration += ConinueNarrationText;
				}
				break;
			case EHazeLobbyStartType::ChapterSelect:
				FullNarration += Buttons.ChapterSelect.Text.ToString() + ", ";
				FullNarration += ChapterPicker.GetNarrationString(true);
				break;
			case EHazeLobbyStartType::PickMinigame:
				FullNarration += Buttons.Minigames.Text.ToString() + ", ";
				{
					auto MinigameRow = MinigamePicker.GetSelectedRow();
					if (MinigameRow != nullptr)
					{
						FullNarration += MinigameRow.MinigameChapter.Name.ToString() + ", ";
					}
				}
				break;
		}

		FString ControlNarration;

		// If we have a joinable slot narrate the join button
		if (Lobby != nullptr && Lobby.NumIdentitiesInLobby() < 2)
		{
			if (GetLobbyOwnerWidget().MakeNarrationString(ButtonNarration))
				ControlNarration += ButtonNarration + ", ";
		}

		if (Buttons.LeftTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.RightTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Back.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (CanInvitePlayer() && Buttons.Invite.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (ShouldShowFriendsPassInfo() && Buttons.FP.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (CanProceedToCharacterSelect() && Buttons.Proceed.MakeNarrationString(ButtonNarration))
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

struct FKCodeHandler
{
	int Progress = -1;

	bool AddInput(UChapterSelectWidget Widget, FKey Key)
	{
		bool bCanProceed = false;
		bool bShouldEat = false;

		switch (Progress+1)
		{
			case 0:
			case 1:
				bCanProceed = (Key == EKeys::Up) || (Key == EKeys::Gamepad_DPad_Up);
			break;
			case 2:
			case 3:
				bCanProceed = (Key == EKeys::Down) || (Key == EKeys::Gamepad_DPad_Down);
			break;
			case 4:
			case 6:
				bCanProceed = (Key == EKeys::Left) || (Key == EKeys::Gamepad_DPad_Left);
			break;
			case 5:
			case 7:
				bCanProceed = (Key == EKeys::Right) || (Key == EKeys::Gamepad_DPad_Right);
			break;
			case 8:
				bCanProceed = (Key == EKeys::B) || (Key == EKeys::Gamepad_FaceButton_Right);
				bShouldEat = true;
			break;
			case 9:
				bCanProceed = (Key == EKeys::A) || (Key == EKeys::Gamepad_FaceButton_Bottom);
				bShouldEat = true;
			break;
		}

		if (bCanProceed)
			Progress += 1;
		else if (Progress != -1)
			Progress = -1;

		if (Progress >= 9)
		{
			PrintToScreen("Good Morning World!", Duration = 5.f, Color = FLinearColor::Green);
			System::ExecuteConsoleCommand("Haze.UnlockAllChapters");
			System::ExecuteConsoleCommand("Haze.UnlockAllMinigames");

			if (!Widget.bHasContinue)
			{
				Save::SaveAtProgressPoint(Progress::GetProgressPointRefID(Widget.ChapterDatabase.InitialChapter), bQuietSave = true);
				Widget.bHasContinue = true;
				Widget.ChapterPicker.SelectChapter(Widget.ChapterDatabase.GetInitialChapter());
				Widget.ContinueChapter = Widget.ChapterDatabase.InitialChapter;
				Widget.ContinuePoint = Widget.ChapterDatabase.InitialChapter;
			}

			FHazeChapter Chapter = Widget.ChapterDatabase.GetChapterByProgressPoint(Widget.ContinueChapter);
			FHazeChapterGroup Group = Widget.ChapterDatabase.GetChapterGroup(Chapter);
			Widget.BP_SetContinueChapter(Group, Chapter);
			Widget.MinigamePicker.Initialize();
		}

		return bShouldEat;
	}
};