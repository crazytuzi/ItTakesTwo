#if !RELEASE
const FConsoleVariable CVar_FoghornDebugModeEnabled("Foghorn.DebugMode", 0);
const FConsoleVariable CVar_FoghornDebugDisablePlayOnce("Foghorn.DisablePlayOnce", 0);

struct FFoghornDebugEffortLocation
{
	FName Name;
	FVector Location;
};

void FoghornDebugLog(FString DebugMessage)
{
	if (CVar_FoghornDebugModeEnabled.GetInt() == 0)
		return;

	bool MayControlSide = Game::GetMay().HasControl();
	Log("Foghorn " + (GFrameNumber % 9999) + (MayControlSide ? "  " : "R ") + DebugMessage);
}

void FoghornDebugLog(EFoghornLaneName Lane, FString DebugMessage)
{
	if (CVar_FoghornDebugModeEnabled.GetInt() == 0)
		return;

	bool MayControlSide = Game::GetMay().HasControl();
	Log("Foghorn " + (GFrameNumber % 9999) + (MayControlSide ? "  " : "R ") + "  [Lane " + (int(Lane)+1) + "] " + DebugMessage);
}
#endif