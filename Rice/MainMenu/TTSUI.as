
UFUNCTION(BlueprintPure)
bool IsTTSActive()
{
	auto Lobby = Lobby::GetLobby();
	if (Lobby == nullptr)
		return false;
	if (Lobby.Network == EHazeLobbyNetwork::Local)
		return false;
	if (Lobby.NumIdentitiesInLobby() < 2)
		return false;
	switch (Online::GetAccessibilityState(EHazeAccessibilityFeature::TextToSpeech))
	{
		case EHazeAccessibilityState::OSTurnedOn:
		case EHazeAccessibilityState::GameTurnedOn:
			return true;
	}
	return false;
}

UFUNCTION(BlueprintPure)
bool AreVOIPAccessibilityOptionsAvailable()
{
	if (Online::GetAccessibilityState(EHazeAccessibilityFeature::TextToSpeech) != EHazeAccessibilityState::NotAvailable)
		return true;
	if (Online::GetAccessibilityState(EHazeAccessibilityFeature::SpeechToText) != EHazeAccessibilityState::NotAvailable)
		return true;
	return false;
}

bool HandleTTSKeyInput(FKeyEvent Event)
{
	if (Event.IsRepeat())
		return false;

	if (Event.Key == EKeys::Gamepad_FaceButton_Left)
	{
		if (IsTTSActive())
		{
			Print("Opening TTS UI");
			Online::ShowTextToSpeechInput();
			return true;
		}
	}
	else if (Event.Key == EKeys::Gamepad_LeftTrigger)
	{
		if (IsTTSActive())
		{
			Print("TTS: Yes");
			Online::SendVoipTextToSpeech(FText::FromString("Yes"));
			return true;
		}
	}
	else if (Event.Key == EKeys::Gamepad_RightTrigger)
	{
		if (IsTTSActive())
		{
			Print("TTS: No");
			Online::SendVoipTextToSpeech(FText::FromString("No"));
			return true;
		}
	}

	return false;
}