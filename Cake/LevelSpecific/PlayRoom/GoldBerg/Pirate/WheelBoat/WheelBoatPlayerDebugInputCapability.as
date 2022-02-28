import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatPlayerDebugInputCapability : UHazeDebugCapability
{
    default CapabilityTags.Add(n"Debug");

	AHazePlayerCharacter PlayerOwner;

	bool bSingleInputIsActive = false;
	
	bool bBlockinOtherPlayersInput = false;
	UOnWheelBoatComponent BoatComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatComp = UOnWheelBoatComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ConsumeAction(n"WheelBoatSingleInputUsed");
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"NetWheelBoatToggleSingleInput", "ToggleSingleSteering");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"WheelBoat");
	}

	UFUNCTION(NetFunction)
	void NetWheelBoatToggleSingleInput()
	{			
		bSingleInputIsActive = !bSingleInputIsActive;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bSingleInputIsActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bSingleInputIsActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetSingleDebugStatus(true);
		PlayerOwner.GetOtherPlayer().BlockCapabilities(n"WheelBoatInput", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetSingleDebugStatus(false);
		PlayerOwner.GetOtherPlayer().UnblockCapabilities(n"WheelBoatInput", this);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		PrintToScreen("Wheelboat single input for " + PlayerOwner.GetName() + " is Active!", 0.f, FLinearColor::Red);

		EHazeActionState WantedActionState;
		if(IsActioning(ActionNames::MovementJump))
			WantedActionState = EHazeActionState::Active;
		else
			WantedActionState = EHazeActionState::Inactive;
	}

	void SetSingleDebugStatus(bool bActive)
	{
		const EHazeActionState ActionState = bActive ? EHazeActionState::Active : EHazeActionState::Inactive;
		PlayerOwner.SetCapabilityActionState(n"WheelBoatSingleInputUsed", ActionState);
	}
};