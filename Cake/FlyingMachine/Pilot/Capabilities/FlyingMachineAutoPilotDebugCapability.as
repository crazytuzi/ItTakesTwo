import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Cake.FlyingMachine.FlyingMachine;


class UFlyingMachineAutoPilotDebugCapability : UHazeDebugCapability
{
	UFlyingMachinePilotComponent PilotComp;
	bool bAutoPilotIsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PilotComp = UFlyingMachinePilotComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"NetToggleAutoPilot", "ToggleAutoPilot");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"FlyingMachine");
	}

	UFUNCTION(NetFunction)
	void NetToggleAutoPilot()
	{			
		bAutoPilotIsActive = !bAutoPilotIsActive;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	#if TEST
		PilotComp.CurrentMachine.bDebugLockedSpeed = bAutoPilotIsActive;
	#endif
	}
}