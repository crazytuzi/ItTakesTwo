import Vino.Control.DebugShortcutsEnableCapability;

class UDebugNetworkFreezeCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	bool bIsFrozen = false;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler FreezeHandler = DebugValues.AddFunctionCall(n"HandleToggleFreezeNetwork", "Freeze Network");
		FreezeHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"Network");
	}

	UFUNCTION()
	void HandleToggleFreezeNetwork()
	{
		Network::DebugToggleFrozen();
	}

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
	{
	}
};