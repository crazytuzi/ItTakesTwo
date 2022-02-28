
#if !RELEASE
const FConsoleVariable CVar_DebugDJDance("Music.DJ.Debug", 0);
const FConsoleVariable CVar_DebugDJDanceHideScreenPrint("Music.DJ.DebugHideScreenPrint", 0);
const FConsoleVariable CVar_DebugDJDisableStations("Music.DJ.DebugDisableStations", 0);
#endif // !RELEASE

namespace DJDanceCommon
{

	void DebugPrintToScreenOnly(FString StringToPrint, float Duration = 0.0f)
	{
#if !RELEASE
		if(CVar_DebugDJDance.GetInt() == 1 && CVar_DebugDJDanceHideScreenPrint.GetInt() != 1)
		{
			PrintToScreen(StringToPrint, 5.0f, FLinearColor::Green);
		}
#endif // !RELEASE
	}

	void DebugPrint(FString StringToPrint, float Duration = 5.0f)
	{
#if !RELEASE
		if(CVar_DebugDJDance.GetInt() == 1 && CVar_DebugDJDanceHideScreenPrint.GetInt() != 1)
		{
			Print(StringToPrint, Duration, FLinearColor::Green);
		}
#endif // !RELEASE
	}
}
