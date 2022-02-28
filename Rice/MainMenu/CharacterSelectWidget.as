import Rice.MainMenu.LobbyWidget;

struct FCharacterSelectButtons
{
	UPROPERTY()
	UMenuPromptOrButton Back;
}

class UCharacterSelectWidget : ULobbyWidget
{
	default bCustomNavigation = true;

	bool bWantToStart = false;
	float StartTimer = 0.f;
	float CurrentOpacity = 1.f;

	FKey KeyboardBoundMoveLeft;
	FKey KeyboardBoundMoveRight;

	private bool bNarrateNextTick = false;

	TMap<UHazePlayerIdentity, EHazePlayer> IdentitiesToPlayer;
	TPerPlayer<bool> PreviousReadyStates;

	private bool bHasTickedForSound = false;

	FKey GetBoundKey(FName SettingName)
	{
		FString Value;
		UHazeGameSettingBase SettingsDescription;
		bool bSuccess = GameSettings::GetGameSettingsDescriptionAndValue(SettingName, SettingsDescription, Value);
		if (bSuccess)
		{
			UHazeKeyBindSetting KeyBindDescription = Cast<UHazeKeyBindSetting>(SettingsDescription);
			return KeyBindDescription.GetKeyFromSettingsValue(Value);
		}
		return FKey();
	}

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap) override
	{
		KeyboardBoundMoveLeft = GetBoundKey(n"KeyboardBinding_MoveLeft");
		KeyboardBoundMoveRight = GetBoundKey(n"KeyboardBinding_MoveRight");

		BindMemberEvents(GetLobbyOwnerWidget());
		BindMemberEvents(GetLobbyJoinerWidget());

		Super::Show(bSnap);
		NarrateFullMenu();
		bHasTickedForSound = false;
	}

	void BindMemberEvents(ULobbyMemberWidget MemberWidget)
	{
		if (MemberWidget == nullptr)
			return;
		MemberWidget.OnLeftArrowClicked.AddUFunction(this, n"OnMemberLeftArrowClicked");
		MemberWidget.OnRightArrowClicked.AddUFunction(this, n"OnMemberRightArrowClicked");
		MemberWidget.OnClicked.AddUFunction(this, n"OnMemberReadyClicked");
	}

	UFUNCTION()
	private void OnMemberLeftArrowClicked(ULobbyMemberWidget Member)
	{
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromControllerId(-1))
			return;
		MoveSelection(-1, bMoveLeft = true);
	}

	UFUNCTION()
	private void OnMemberRightArrowClicked(ULobbyMemberWidget Member)
	{
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromControllerId(-1))
			return;
		MoveSelection(-1, bMoveLeft = false);
	}

	UFUNCTION()
	private void OnMemberReadyClicked(ULobbyMemberWidget Member)
	{
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromControllerId(-1))
			return;
		ToggleReady(-1);
	}

	void MoveSelection(int ControllerId, bool bMoveLeft)
	{
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity == nullptr)
				continue;
			if (Member.Identity.TakesInputFromControllerId(ControllerId))
			{
				EHazePlayer NewSelection = EHazePlayer::MAX;

				if (bMoveLeft)
				{
					switch (Member.ChosenPlayer)
					{
						case EHazePlayer::May:
						case EHazePlayer::MAX:
							NewSelection = EHazePlayer::May;
						break;
						case EHazePlayer::Cody:
							NewSelection = EHazePlayer::MAX;
						break;
					}
				}
				else
				{
					switch (Member.ChosenPlayer)
					{
						case EHazePlayer::May:
							NewSelection = EHazePlayer::MAX;
						break;
						case EHazePlayer::Cody:
						case EHazePlayer::MAX:
							NewSelection = EHazePlayer::Cody;
						break;
					}
				}

				if (NewSelection != Member.ChosenPlayer)
				{
					Lobby::Menu_LobbySetReady(Member.Identity, false);
					Lobby::Menu_LobbySelectPlayer(Member.Identity, NewSelection);
				}
			}
		}
	}

	void ToggleReady(int ControllerId)
	{
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(ControllerId);

		// Toggle ready state
		if (KeyIdentityInLobby != nullptr && Lobby.GetPlayerChosen(KeyIdentityInLobby) != EHazePlayer::MAX)
		{
			bool bOtherPlayerReadyHere = false;
			for (auto& Member : Lobby.LobbyMembers)
			{
				if (Member.Identity == KeyIdentityInLobby)
					continue;
				if (Member.Identity == nullptr)
					continue;
				if (Member.ChosenPlayer != Lobby.GetPlayerChosen(KeyIdentityInLobby))
					continue;
				if (!Member.bReady)
					continue;
				bOtherPlayerReadyHere = true;
				break;
			}

			if (!bOtherPlayerReadyHere)
			{
				bool bWasReady = Lobby.IsPlayerReady(KeyIdentityInLobby);
				if (!bWasReady || !bWantToStart)
					Lobby::Menu_LobbySetReady(KeyIdentityInLobby, !bWasReady);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return nullptr;

		// We respond to navigation here,
		// so analog stick can be used as well as dpad or keyboard.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.
		if (Event.NavigationType == EUINavigation::Left)
			MoveSelection(Event.ControllerId, bMoveLeft = true);
		if (Event.NavigationType == EUINavigation::Right)
			MoveSelection(Event.ControllerId, bMoveLeft = false);

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.ControllerId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.ControllerId);

		// Don't eat navigation keys to they can be used for custom navigation later
		if (Event.Key == EKeys::Left || Event.Key == EKeys::Right || Event.Key == EKeys::Up || Event.Key == EKeys::Down
		 || Event.Key == EKeys::Gamepad_DPad_Left || Event.Key == EKeys::Gamepad_DPad_Right
		 || Event.Key == EKeys::Gamepad_DPad_Up || Event.Key == EKeys::Gamepad_DPad_Down)
		{
			return FEventReply::Unhandled();
		}

		if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
		{
			ToggleReady(Event.ControllerId);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// Un-ready for local player
			if (KeyIdentityInLobby != nullptr
				&& Lobby.GetPlayerChosen(KeyIdentityInLobby) != EHazePlayer::MAX
				&& Lobby.IsPlayerReady(KeyIdentityInLobby)
				&& !bWantToStart)
			{
				Lobby::Menu_LobbySetReady(KeyIdentityInLobby, false);
				Lobby::Menu_LobbySetReady(KeyIdentityInLobby, false);		
				return FEventReply::Handled();
			}

			if (MainMenu.OwnerIdentity.TakesInputFromControllerId(Event.ControllerId))
			{
				if (Lobby.LobbyOwner.IsLocal())
				{
					// Return to chapter select for owner of menu
					Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
					return FEventReply::Handled();
				}
				else
				{
					// Disconnect from lobby for joining player
					LeaveLobby();
					GetAudioManager().UI_ReturnToChapterSelect();
					return FEventReply::Handled();
				}
			}
		}

		// Special handling for WASD
		if (Event.Key == KeyboardBoundMoveLeft)
		{
			MoveSelection(Event.ControllerId, bMoveLeft = true);
			return FEventReply::Handled();
		}

		if (Event.Key == KeyboardBoundMoveRight)
		{
			MoveSelection(Event.ControllerId, bMoveLeft = false);
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION()
	void ReturnToChapterSelect()
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			// Return to chapter select for owner of menu
			Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		Super::Tick(Geom, DeltaTime);

		if (Lobby == nullptr)
			return;
		if (!bIsActive)
			return;

		if (Lobby.IsOkayToStartGame() && AreAllPlayersReady() && !Lobby.HasGameStarted())
		{
			if (!bWantToStart)
			{
				StartTimer = 1.1f;
				bWantToStart = true;
				bWantToStart = true;				
				GetAudioManager().UI_OnGameConfirmStarted();
			}
			else
			{
				float PrevTimer = StartTimer;
				StartTimer -= DeltaTime;

				if (StartTimer < 0.6f)
				{
					if (PrevTimer >= 0.6f)
					{
						MainMenu.CameraUser.FadeOutView(0.5f);
						MainMenu.OnGameProbablyStartingSoon.Broadcast();
					}

					CurrentOpacity = FMath::FInterpConstantTo(CurrentOpacity, 0.f, DeltaTime, 2.f);
					SetRenderOpacity(CurrentOpacity);
				}

				if (StartTimer <= 0.f && Lobby.LobbyOwner.IsLocal())
				{
					// If we're ever completely ready, lobby owner will decide to start the game.
					/// No turning back now!
					bWantToStart = false;
					Lobby::Menu_StartLobbyGame();

					CurrentOpacity = 0.f;
					SetRenderOpacity(0.f);
				}
			}
		}
		else if (bWantToStart)
		{
			bWantToStart = false;
			MainMenu.CameraUser.FadeInView(0.5f);
		}
		else if (CurrentOpacity < 1.f)
		{
			CurrentOpacity = FMath::FInterpConstantTo(CurrentOpacity, 1.f, DeltaTime, 2.f);
			SetRenderOpacity(CurrentOpacity);
		}

		// Return to chapter select if the joining player has left
		if (Lobby.Network == EHazeLobbyNetwork::Host && Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.LobbyState == EHazeLobbyState::CharacterSelect)
		{
			Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
			GetAudioManager().UI_ReturnToChapterSelect();
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_MainMenu_Progression", 2.f, 1000.f);
		}

		// Return to chapter select if the lobby state has changed
		if (Lobby.LobbyState == EHazeLobbyState::ChapterSelect)
		{
			GetAudioManager().UI_ReturnToChapterSelect();
			bHasTickedForSound = false;
			MainMenu.ReturnToChapterSelect();
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_MainMenu_Progression", 2.f, 1000.f);	
		}

		// If the secondary identity is disengaged, remove it from the lobby and return to chapter select

		int PlayerCount = 0;
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity != nullptr && Member.Identity != Online::PrimaryIdentity)
			{
				if (Member.Identity.Engagement != EHazeIdentityEngagement::Engaged)
				{
					Lobby::Menu_RemoveLocalPlayerFromLobby(Member.Identity);
					Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
					GetAudioManager().UI_ReturnToChapterSelect();
					MainMenu.ReturnToChapterSelect();
					UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_MainMenu_Progression", 2.f, 1000.f);					
				}
			}
			
			EHazePlayer PreviousSelectedPlayer = IdentitiesToPlayer.FindOrAdd(Member.Identity);
			if(bHasTickedForSound)
			{
				// Poll updates for playing audio
				if(Member.ChosenPlayer != PreviousSelectedPlayer)
				{
					if(Member.ChosenPlayer == EHazePlayer::MAX)
					{
						if(PreviousSelectedPlayer == EHazePlayer::May)
						{
							GetAudioManager().UI_PlayerOnRemoveSelectionMay();
							PreviousReadyStates[PlayerCount] = false;
						}
						else if(PreviousSelectedPlayer == EHazePlayer::Cody)
						{
							GetAudioManager().UI_PlayerOnRemoveSelectionCody();
							PreviousReadyStates[PlayerCount] = false;
						}
					}
					else if(Member.ChosenPlayer == EHazePlayer::May)
						GetAudioManager().UI_PlayerOnMoveSelectionMay();
					else if(Member.ChosenPlayer == EHazePlayer::Cody)
						GetAudioManager().UI_PlayerOnMoveSelectionCody();
				}

				// Play selection audio on toggle ready
				if(Member.ChosenPlayer != EHazePlayer::MAX && Member.bReady != PreviousReadyStates[PlayerCount])
				{			
					if(Member.bReady)
					{
						if(Member.ChosenPlayer == EHazePlayer::May)
							GetAudioManager().UI_PlayerCharacterSelectionConfirmMay();
						else
							GetAudioManager().UI_PlayerCharacterSelectionConfirmCody();
					}
					else
						GetAudioManager().UI_PlayerCharacterSelectionCancel();

					PreviousReadyStates[PlayerCount] = Member.bReady;
				}

			}

			IdentitiesToPlayer[Member.Identity] = Member.ChosenPlayer;	
			++PlayerCount;
		}

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}		

		bHasTickedForSound = true;
	}

	UFUNCTION(BlueprintEvent)
	FCharacterSelectButtons GetButtonsForNarration()
	{
		return FCharacterSelectButtons();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;

		FString Narration = "Select Character, Menu Controls, Left and Right, select character, ";

		Narration += Game::KeyToNarrationText(EKeys::Virtual_Accept, GetLobbyOwnerWidget().GetControllerType()).ToString() + ", Set Ready, ";

		FCharacterSelectButtons Buttons = GetButtonsForNarration();

		FString ButtonNarration;
		if (Buttons.Back != nullptr && Buttons.Back.MakeNarrationString(ButtonNarration))
			Narration += ButtonNarration + ", ";

		Game::NarrateString(Narration);
	}

	UFUNCTION()
	void NarrateFullMenu()
	{
		bNarrateNextTick = true;
	}
};

const FConsoleCommand ConsoleLeaveLobby("Haze.SimulateLeaveLobby", n"ExecuteSimulateLeaveLobby");
void ExecuteSimulateLeaveLobby(TArray<FString> Args)
{
	Lobby::Menu_LeaveLobby();
}