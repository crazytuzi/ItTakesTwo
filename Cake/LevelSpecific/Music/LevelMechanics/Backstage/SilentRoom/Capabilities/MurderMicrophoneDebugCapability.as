import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneDebugCapability : UHazeDebugCapability
{
	AMurderMicrophone OwnerMicrophone;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UHazeDisableComponent DisableComp;

	bool bDrawDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwnerMicrophone = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		DisableComp = UHazeDisableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler ToggleAlwaysShowWeakPoint = DebugValues.AddFunctionCall(n"ToggleWeakPointVisibility", "Toggle Show Weak Point");
		FHazeDebugFunctionCallHandler ToggelDrawDebugHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebug", "Toggle Debug Draw");
		FHazeDebugFunctionCallHandler IgnorePlayer = DebugValues.AddFunctionCall(n"ToggleIgnorePlayer", "Toggle Ignore Player");

		ToggleAlwaysShowWeakPoint.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"MurderMicrophone");
		ToggelDrawDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"MurderMicrophone");
		IgnorePlayer.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"MurderMicrophone");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawDebug && !DisableComp.bIsAutoDisabled)
		{
			DrawDebug(DeltaTime);
		}
	}

	private void DrawDebug(float DeltaTime)
	{
		TargetingComp.DebugDrawVision();
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
	void ToggleDrawDebug()
	{
		bDrawDebug = !bDrawDebug;
	}

	UFUNCTION()
	void ToggleIgnorePlayer()
	{
		OwnerMicrophone.ToggleIgnorePlayer();
	}

	UFUNCTION()
	void ToggleWeakPointVisibility()
	{
		NetToggleWeakPointVisibility();
	}

	UFUNCTION(NetFunction)
	private void NetToggleWeakPointVisibility()
	{
		OwnerMicrophone.DebugToggleWeakPoint();
	}
}
