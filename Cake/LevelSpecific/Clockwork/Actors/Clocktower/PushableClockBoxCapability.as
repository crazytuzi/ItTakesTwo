import Cake.LevelSpecific.Clockwork.Actors.Clocktower.PushableClockBox;
import Vino.Tutorial.TutorialStatics;

class UPushableClockBoxCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
    APushableClockBox PushableBox;
	UHazeCrumbComponent CrumbComp;

	bool bPushing = false;

	float SyncTimer = 0.f;

	bool bReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"PushingClockBox"))
            return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (WasActionStarted(ActionNames::Cancel))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bReachedEnd)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"PushActor", GetAttributeObject(n"PushableClockBox"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bReachedEnd = false;
        Player.SetCapabilityActionState(n"PushingClockBox", EHazeActionState::Inactive);
        PushableBox = Cast<APushableClockBox>(ActivationParams.GetObject(n"PushActor"));
        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(PushableBox.BoxMesh, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.TriggerMovementTransition(this);

		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"EnterAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimFinishedDelegate, Animation = PushableBox.PushEnter);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ClampYawLeft = 45.f;
		ClampSettings.ClampYawRight = 45.f;
		ClampSettings.ClampPitchDown = 89.f;
		ClampSettings.ClampPitchUp = 30.f;
		ClampSettings.bUseClampPitchDown = true;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.bUseClampYawLeft = true;
		ClampSettings.bUseClampYawRight = true;
		Player.ApplyCameraClampSettings(ClampSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);

		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.TriggerMovementTransition(this);
		Print("May Detached", 5.f);
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);

		if (bReachedEnd)
		{
			PushableBox.ReleaseBlock(true);
		}
		else
		{
			PushableBox.ReleaseBlock(false);
		}

		Player.PlaySlotAnimation(Animation = PushableBox.PushExit);

		Player.ClearCameraClampSettingsByInstigator(this);

		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (PushableBox.bReachedEnd)
		{
			bReachedEnd = true;
		}

		if (HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);

        	PushableBox.UpdatePushDirection(Input);

			SyncTimer -= DeltaTime;
			if (SyncTimer <= 0.f)
			{
				SyncTimer = 0.15f;
				if (Input.X <= 0)
				{
					if (bPushing)
					{
						bPushing = false;
						NetUpdatePushingStatus(false);
					}
				}
				else if (Input.X > 0)
				{
					if (!bPushing)
					{
						bPushing = true;
						NetUpdatePushingStatus(true);
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdatePushingStatus(bool bPush)
	{
		if (!IsActive())
			return;

		UAnimSequence Anim = bPush ? PushableBox.PushForward : PushableBox.PushMH;
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true);
	}

	UFUNCTION()
	void EnterAnimFinished()
	{
		Player.PlaySlotAnimation(Animation = PushableBox.PushMH, bLoop = true);
	}
}