import Cake.LevelSpecific.PlayRoom.SpaceStation.PushableSpaceBlock;
import Vino.Tutorial.TutorialStatics;

class UPushableSpaceBlockCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;
    APushableSpaceBlock PushableBlock;

	bool bEnterAnimFinished = false;
	bool bExiting = false;
	bool bExitAnimFinished = false;
	bool bStruggling = false;
	bool bFalling = false;
	bool bPlayedFallBark = false;

	FTimerHandle StruggleSyncTimerHandle;

	FVector BlendSpaceValues;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"PushingSpaceBlock"))
            return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (bExitAnimFinished)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"PushableSpaceBlock", GetAttributeObject(n"PushableSpaceBlock"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bEnterAnimFinished = false;
		bExiting = false;
		bExitAnimFinished = false;

        Player.SetCapabilityActionState(n"PushingSpaceBlock", EHazeActionState::Inactive);
        PushableBlock = Cast<APushableSpaceBlock>(ActivationParams.GetObject(n"PushableSpaceBlock"));
        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(PushableBlock.CubeMesh, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.SmoothSetLocationAndRotation(PushableBlock.InteractionPoint.WorldLocation, PushableBlock.InteractionPoint.WorldRotation);
		Player.TriggerMovementTransition(this);

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"EnterAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = PushableBlock.EnterAnim);

		Player.AddLocomotionFeature(PushableBlock.Feature);
		Player.ApplyCameraSettings(PushableBlock.CamSettings, FHazeCameraBlendSettings(), this);

		if (HasControl())
			StruggleSyncTimerHandle = System::SetTimer(this, n"UpdateValues", 0.1f, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.RemoveLocomotionFeature(PushableBlock.Feature);
		Player.ClearCameraSettingsByInstigator(this);

		if (HasControl())
			System::ClearAndInvalidateTimerHandle(StruggleSyncTimerHandle);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterAnimFinished()
	{
		ShowCancelPrompt(Player, this);
		bEnterAnimFinished = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bEnterAnimFinished)
		{		
			FHazeRequestLocomotionData LocomotionData;
			LocomotionData.AnimationTag = n"PlasmaCube";
			Player.RequestLocomotion(LocomotionData);
			return;
		}

		if (bExiting)
			return;

		if (WasActionStarted(ActionNames::Cancel))
		{
			NetStartExitAnimation();
			return;
		}

		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		// if (HasControl())

		if (HasControl())
		{
			BlendSpaceValues = FVector(-Input.Z * 400.f, Input.X * 400.f, 0.f);
			bool bBigCodyOnBlock = PushableBlock.bCodyOnBlock && PushableBlock.CurrentCodySizeMultiplier > 0.f;
			if (bBigCodyOnBlock && !PushableBlock.bAtBottom)
			{
				bFalling = true;
			}
			else
				bFalling = false;
		}

		Player.SetAnimBoolParam(n"PlasmaCubeFalling", bFalling);
		if (bFalling && !bPlayedFallBark)
		{
			bPlayedFallBark = true;
			PushableBlock.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPlasmaBallCodyFail");
		}

		
		if (HasControl())
		{
			bStruggling = Input.Size() != 0.f && PushableBlock.bBlockingHitActive;
		}

		Player.SetAnimBoolParam(n"PlasmaCubeStruggling", bStruggling);

		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = n"PlasmaCube";
		LocomotionData.WantedVelocity = BlendSpaceValues;
		Player.RequestLocomotion(LocomotionData);

        PushableBlock.UpdatePushDirection(Input);

		if (Input.Z > 0.f && PushableBlock.bCodyOnBlock && PushableBlock.CurrentCodySizeMultiplier > 0.f)
		{
			Player.SetFrameForceFeedback(0.1f, 0.1f);
			PushableBlock.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPlasmaBallStrainEffort");
		}
	}

	UFUNCTION()
	void UpdateValues()
	{
		NetUpdateValues(bStruggling, BlendSpaceValues, bFalling);
	}

	UFUNCTION(NetFunction)
	void NetUpdateValues(bool bStruggle, FVector Values, bool bFall)
	{
		bStruggling = bStruggle;
		BlendSpaceValues = Values;
		bFalling = bFall;
	}

	UFUNCTION(NetFunction)
	void NetStartExitAnimation()
	{
		bExiting = true;
		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"ExitAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = PushableBlock.ExitAnim);

		PushableBlock.ReleaseBlock();
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		RemoveCancelPromptByInstigator(Player, this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitAnimFinished()
	{
		bExitAnimFinished = true;
	}
}