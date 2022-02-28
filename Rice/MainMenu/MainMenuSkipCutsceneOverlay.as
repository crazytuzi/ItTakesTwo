import Vino.Camera.Actors.MenuCameraUser;

class UMainMenuSkipCutsceneOverlay : UHazeUserWidget
{
	default bIsFocusable = true;

	AMenuCameraUser CameraUser;
	FKey KeyboardCancelKey;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FString Value;
		UHazeGameSettingBase SettingsDescription;
		bool bSuccess = GameSettings::GetGameSettingsDescriptionAndValue(n"KeyboardBinding_Cancel", SettingsDescription, Value);
		if (bSuccess)
		{
			UHazeKeyBindSetting KeyBindDescription = Cast<UHazeKeyBindSetting>(SettingsDescription);
			KeyboardCancelKey = KeyBindDescription.GetKeyFromSettingsValue(Value);
		}
	}

	EHazePlayer GetPlayerForInput(FKeyEvent Event)
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr)
		{
			auto Identity = Lobby.GetIdentityForInput(Event.ControllerId);
			if (Identity != nullptr && Identity.IsLocal())
			{
				// We haven't chosen players yet, so pretend player 1 is may
				if (Identity == Lobby.LobbyMembers[0].Identity)
					return EHazePlayer::May;
				else
					return EHazePlayer::Cody;
			}
		}
		return EHazePlayer::MAX;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == KeyboardCancelKey || InKeyEvent.Key == EKeys::Gamepad_FaceButton_Right)
		{
			EHazePlayer SkipPlayer = GetPlayerForInput(InKeyEvent);
			if (SkipPlayer != EHazePlayer::MAX && CameraUser.ActiveLevelSequenceActor != nullptr)
				CameraUser.ActiveLevelSequenceActor.NetSetPlayerWantsToSkipSequence(SkipPlayer, true);
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == KeyboardCancelKey || InKeyEvent.Key == EKeys::Gamepad_FaceButton_Right)
		{
			EHazePlayer SkipPlayer = GetPlayerForInput(InKeyEvent);
			if (SkipPlayer != EHazePlayer::MAX && CameraUser.ActiveLevelSequenceActor != nullptr)
				CameraUser.ActiveLevelSequenceActor.NetSetPlayerWantsToSkipSequence(SkipPlayer, false);
		}
		return FEventReply::Unhandled();
	}
};