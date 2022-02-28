import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.Players.ParentBlobPlayerInputCapability;

class UParentBlobPlayerInputOverrideCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Input");
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"MovementInput");
	default CapabilityTags.Add(n"ParentBlob");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default CapabilityDebugCategory = n"ParentBlob";

	TArray<FParentBlobDelayInput> InputDelayLine;

	AHazePlayerCharacter PlayerOwner;
	AParentBlob ParentBlob;
	UParentBlobPlayerComponent ParentBlobComponent;
	UParentBlobKineticComponent KineticComponent;
	bool bSingleInputIsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(PlayerOwner);
		ParentBlob = ParentBlobComponent.ParentBlob;
		KineticComponent = UParentBlobKineticComponent::Get(ParentBlobComponent.ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"NetToggleSingleInput", "ToggleSingleSteering");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"ParentBlob");
	}

	UFUNCTION(NetFunction)
	void NetToggleSingleInput()
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
		ParentBlob.bBrothersMovementActive = true;
		PlayerOwner.GetOtherPlayer().BlockCapabilities(n"Input", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ParentBlob.bBrothersMovementActive = false;
		PlayerOwner.GetOtherPlayer().UnblockCapabilities(n"Input", this);
		bSingleInputIsActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FLinearColor DebugColor = PlayerOwner.IsMay() ? FLinearColor::LucBlue : FLinearColor::Green;
		PrintToScreen("BROTHERS MODE ACTIVE - " + PlayerOwner.GetName(), 0.f, DebugColor);

		auto OtherPlayer = PlayerOwner.GetOtherPlayer();
		ParentBlob.PlayerRawInput[OtherPlayer.Player] = ParentBlob.PlayerRawInput[PlayerOwner.Player];
		ParentBlob.PlayerMovementDirection[OtherPlayer.Player] = ParentBlob.PlayerMovementDirection[PlayerOwner.Player];
		KineticComponent.PlayerInputData[OtherPlayer.Player] = KineticComponent.PlayerInputData[PlayerOwner.Player];
	}
};