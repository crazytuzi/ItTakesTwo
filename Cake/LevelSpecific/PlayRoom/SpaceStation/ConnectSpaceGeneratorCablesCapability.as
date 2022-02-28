import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceGenerator;
import Vino.Tutorial.TutorialStatics;

UCLASS(Abstract)
class UConnectSpaceGeneratorCablesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Interaction);
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

    UPROPERTY(EditDefaultsOnly)
    UAnimSequence ConnectAnim;
    UPROPERTY(EditDefaultsOnly)
    UAnimSequence ConnectMH;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ConnectExit;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BatteryEnter;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BatteryMh;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BatteryExit;

    UPROPERTY()
    ASpaceGenerator SpaceGenerator;
	UHazeSkeletalMeshComponentBase BatteryAnimActor;

	bool bEnterAnimationFinished = false;
	bool bExitAnimationFinished = false;
	bool bExiting = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"ConnectCables"))
            return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (bExitAnimationFinished)
		    return EHazeNetworkDeactivation::DeactivateLocal;
		
        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bExiting = false;
		bEnterAnimationFinished = false;
		bExitAnimationFinished = false;

        SpaceGenerator = Cast<ASpaceGenerator>(GetAttributeObject(n"SpaceGenerator"));
        Player.SetCapabilityActionState(n"ConnectCables", EHazeActionState::Inactive);
		BatteryAnimActor = SpaceGenerator.BatteryAnimActor;

        FHazeAnimationDelegate OnEnterFinished;
        OnEnterFinished.BindUFunction(this, n"EnterFinished");
        Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = ConnectAnim);

		FHazePlaySlotAnimationParams Params;
		Params.Animation = BatteryEnter;
		Params.bPauseAtEnd = true;
		BatteryAnimActor.PlaySlotAnimation(Params);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.TriggerMovementTransition(this);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.bUseClampPitchDown = true;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.bUseClampYawLeft = true;
		ClampSettings.bUseClampYawRight = true;
		ClampSettings.ClampPitchDown = 80.f;
		ClampSettings.ClampPitchUp = 15.f;
		ClampSettings.ClampYawLeft = 80.f;
		ClampSettings.ClampYawRight = 80.f;
		Player.ApplyCameraClampSettings(ClampSettings, FHazeCameraBlendSettings(1.f), this);
	}

    UFUNCTION()
    void EnterFinished()
    {
        Player.PlaySlotAnimation(Animation = ConnectMH, bLoop = true);
		bEnterAnimationFinished = true;

		ShowCancelPrompt(Player, this);
		SpaceGenerator.SetBatteryConnected();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		Player.ClearCameraClampSettingsByInstigator(this, 0.5f);

		if (!bExiting)
		{
			Player.StopAnimation();
			Player.RemoveCancelPromptByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!HasControl())
			return;

		if (!bEnterAnimationFinished)
			return;

		if (bExiting)
			return;

		if (WasActionStarted(ActionNames::Cancel))
			NetInteractionCanceled();
	}

	UFUNCTION(NetFunction)
	void NetInteractionCanceled()
	{
		bExiting = true;

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"ExitAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = ConnectExit);

		FHazePlaySlotAnimationParams Params;
		Params.Animation = BatteryExit;
		Params.bPauseAtEnd = true;
		BatteryAnimActor.PlaySlotAnimation(Params);

		RemoveCancelPromptByInstigator(Player, this);
		SpaceGenerator.SetBatteryDisconnected();
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitAnimFinished()
	{
		bExitAnimationFinished = true;
	}
}