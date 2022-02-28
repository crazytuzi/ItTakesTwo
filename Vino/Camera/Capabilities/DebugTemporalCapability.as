import Rice.TemporalLog.TemporalLogStatics;
import Vino.Control.DebugShortcutsEnableCapability;

class UDebugTemporalCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"DebugTemporal");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Debug";

	bool bIsLogging = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		// Enable, Disable
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleTemporalLogging", "ToggleTemporalLogging");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"TemporalLogging");
			Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::Temporal);
			Handler.DisplayAsDefault();
		}
	}

	UFUNCTION()
	void ToggleTemporalLogging()
	{
		bIsLogging = !bIsLogging;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AreDebugShortcutsEnabled())
			return EHazeNetworkActivation::DontActivate;

		if(bIsLogging)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}
 
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AreDebugShortcutsEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!bIsLogging)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TArray<FString> Args;
		StartTemporalLogging(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bIsLogging = false;

		// DEBUG TODO; ask luc about this, tyko
		// if (Network::IsNetworked() && !Network::HasWorldControl())
		// 	return;

		TArray<FString> Args;
		StopTemporalLogging(Owner);
		Debug::OpenDebugMenu(n"Temporal");
		Debug::RequestPIEPlayerEject();	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Temporal logging '" + Owner + "'...", Color = FLinearColor::Red);	
	}
};
