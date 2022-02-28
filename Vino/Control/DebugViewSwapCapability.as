import Vino.Control.DebugShortcutsEnableCapability;

class UDebugViewSwapCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SwapView", "SwapView");
		Handler.AddActiveUserIgnoreCategoryButton(EHazeDebugActiveCategoryAlwaysValidButtonType::ShoulderLeft, EHazeDebugInputActivationType::DoubleTap);
		Handler.DisplayAsDefault();
	}

	UFUNCTION()
	void SwapView()
	{
		System::ExecuteConsoleCommand("Haze.ToggleEditorViewMode");
	}
};