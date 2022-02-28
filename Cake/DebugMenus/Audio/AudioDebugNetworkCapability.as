enum EDebugAudioOutputBlock
{
	Remote,
	Local,	
	None,
};

class UAudioDebugNetworkCapability : UHazeDebugCapability
{
	// This function lets you setup all the debug information you want to use.
	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsValue(n"DisableAudioOutputs", 2, "Disables audio posted by either Remote|Control|None side", true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return
			UHazeAudioNetworkDebugManager::IsNetworkSimulating() ? 
			EHazeNetworkActivation::ActivateLocal : EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return
			!UHazeAudioNetworkDebugManager::IsNetworkSimulating() ? 
			EHazeNetworkDeactivation::DeactivateLocal : EHazeNetworkDeactivation::DontDeactivate;
	}

	int PreviousDebugValue = 0;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int NewValue = 0;
		if (!Owner.GetDebugValue(n"DisableAudioOutputs", NewValue))
			return;

		EDebugAudioOutputBlock Output = EDebugAudioOutputBlock(NewValue);
		if (NewValue != PreviousDebugValue)
		{
			UHazeAudioNetworkDebugManager Manager = Cast<UHazeAudioNetworkDebugManager>(Game::GetSingleton(UHazeAudioNetworkDebugManager::StaticClass()));
			Manager.SetNetworkAudioOutput(Output != EDebugAudioOutputBlock::Local, Output != EDebugAudioOutputBlock::Remote);
		}
		PreviousDebugValue = NewValue;
	}
}