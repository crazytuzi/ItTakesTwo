import Peanuts.Foghorn.FoghornDebugStatics;

const FConsoleVariable CVar_FoghornVOBankDebug("Foghorn.VOBankDebug", 0);
const FConsoleVariable CVar_FoghornNarrateVOBankDebug("Foghorn.NarrateVOBank", 0);

class UFoghornVOBankDataAssetBase : UDataAsset
{
	void TriggerVO(FName EventName, AActor Actor, AActor Actor2, AActor Actor3, AActor Actor4) {}

	void DebugLogNoEvent(FName EventName)
	{
		#if !RELEASE
		if (CVar_FoghornDebugModeEnabled.GetInt() != 0)
		{
			FString LogText = Name.ToString() + " missing event " + EventName.ToString();
			Log("Foghorn " + LogText);
			PrintToScreen(LogText, 3.0f, FLinearColor::Red);
		}
		#endif
		#if TEST
		if (CVar_FoghornVOBankDebug.GetInt() != 0 && CVar_FoghornNarrateVOBankDebug.GetInt() != 0)
		{
			Game::NarrateString(EventName.ToString());
		}
		#endif
	}
}
