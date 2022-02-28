import Vino.Control.DebugShortcutsEnableCapability;

class UDebugFastForwardCutscenesCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleFastForwardCutscenes", "Toggle Fast-Forward Cutscenes");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, Handler.DefaultActiveCategory);
	}

	UFUNCTION()
	void ToggleFastForwardCutscenes()
	{
		int LastValue = Console::GetConsoleVariableInt("Haze.FastForwardCutscenes");
		int NewValue = (LastValue == 0) ? 1 : 0;
		Console::SetConsoleVariableInt("Haze.FastForwardCutscenes", NewValue, "", true);
	}

#if !RELEASE
    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
	{
		int CurValue = Console::GetConsoleVariableInt("Haze.FastForwardCutscenes");
		if (CurValue == 1 && Owner == Game::May)
			PrintToScreenScaled("Fast-Forwarding Cutscenes", 0.f, FLinearColor::LucBlue, 1.2f);
	}
#endif
};