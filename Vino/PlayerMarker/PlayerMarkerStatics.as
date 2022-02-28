import Vino.PlayerMarker.PlayerMarkerComponent;

UFUNCTION()
void EnablePlayerMarker(AHazePlayerCharacter Player, UObject Instigator = nullptr)
{
	if ((Player == nullptr) || (Player.OtherPlayer == nullptr))
		return;

	UPlayerMarkerComponent PlayerMarkerComp = UPlayerMarkerComponent::Get(Player.OtherPlayer);
	if (PlayerMarkerComp != nullptr)
		PlayerMarkerComp.ClearDisabled(Instigator);
}

UFUNCTION()
void DisablePlayerMarker(AHazePlayerCharacter Player, UObject Instigator = nullptr)
{
	if ((Player == nullptr) || (Player.OtherPlayer == nullptr))
		return;

	UPlayerMarkerComponent PlayerMarkerComp = UPlayerMarkerComponent::Get(Player.OtherPlayer);
	if (PlayerMarkerComp != nullptr)
		PlayerMarkerComp.SetDisabled(Instigator);
}

UFUNCTION()
void ForceEnablePlayerMarker(AHazePlayerCharacter Player, UObject Instigator)
{
	if ((Player == nullptr) || (Player.OtherPlayer == nullptr))
		return;

	UPlayerMarkerComponent PlayerMarkerComp = UPlayerMarkerComponent::Get(Player.OtherPlayer);
	if (PlayerMarkerComp != nullptr)
		PlayerMarkerComp.SetForceEnabled(Instigator);
}

UFUNCTION()
void StopForceEnablePlayerMarker(AHazePlayerCharacter Player, UObject Instigator)
{
	if ((Player == nullptr) || (Player.OtherPlayer == nullptr))
		return;

	UPlayerMarkerComponent PlayerMarkerComp = UPlayerMarkerComponent::Get(Player.OtherPlayer);
	if (PlayerMarkerComp != nullptr)
		PlayerMarkerComp.ClearForceEnabled(Instigator);
}
