import Cake.LevelSpecific.Music.NightClub.BassDropOMeter;

class UDropOMeterDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"DebugDropOMeter");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Debug";

	private ABassDropOMeter DropOMeter;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler IncreaseDropOMeterHandle = DebugValues.AddFunctionCall(n"IncreaseDropOMeter", "Increase Meter");
		FHazeDebugFunctionCallHandler DecreaseDropOMeterHandle = DebugValues.AddFunctionCall(n"DecreaseDropOMeter", "Decrease Meter");
		FHazeDebugFunctionCallHandler TogglePauseDropOMeterHandle = DebugValues.AddFunctionCall(n"ToggleDropOMeterActive", "Toggle Active");
		FHazeDebugFunctionCallHandler ToggleDropOMeterDebugTextHandle = DebugValues.AddFunctionCall(n"ToggleDropOMeterDebugText", "Toggle Debug Text");

		IncreaseDropOMeterHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"DJDance");
		DecreaseDropOMeterHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"DJDance");
		TogglePauseDropOMeterHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"DJDance");
		ToggleDropOMeterDebugTextHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"DJDance");
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DropOMeter = Cast<ABassDropOMeter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION()
	void IncreaseDropOMeter()
	{
		DropOMeter.Dev_AddToMasterMeter(0.1f);
	}

	UFUNCTION()
	void DecreaseDropOMeter()
	{
		DropOMeter.Dev_AddToMasterMeter(-0.1f);
	}

	UFUNCTION()
	void ToggleDropOMeterActive()
	{
		DropOMeter.ToggleDropOActive();
	}

	UFUNCTION()
	void ToggleDropOMeterDebugText()
	{
		DropOMeter.ToggleDebugText();
	}
}
