UFUNCTION()
void ActivateSkydive(AHazePlayerCharacter Player)
{
	Player.SetCapabilityActionState(n"SkyDive", EHazeActionState::ActiveForOneFrame);
}