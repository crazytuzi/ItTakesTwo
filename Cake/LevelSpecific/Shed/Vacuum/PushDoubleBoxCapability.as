import Cake.LevelSpecific.Shed.Vacuum.PushableDoubleBox;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Tutorial.TutorialStatics;
import Vino.Audio.Capabilities.AudioTags;

UCLASS(Abstract)
class UPushDoubleBoxCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"GameplayAction");
	default CapabilityTags.Add(AudioTags::FallingAudioBlocker);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	UPlayerMovementAudioComponent AudioMoveComp;
    UHazeBaseMovementComponent Movement;
    APushableDoubleBox CurrentBox;
	UHazeTriggerComponent Interaction;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyMH;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayMH;
	UPROPERTY(Category = "Animation")
	UAnimSequence CodyStruggleAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayStruggleAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence CodyPushAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayPushAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence CodyExitAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayExitAnimation;

	bool bPushing = false;

	bool bCanceled = false;
	bool bExitAnimationFinished = false;
	float PreviousBoxLocation = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
        Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(IsActioning(n"PushingDoubleBox"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bExitAnimationFinished)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (CurrentBox.bFullyPushed)
			return EHazeNetworkDeactivation::DeactivateLocal;
        
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
        OutParams.AddObject(n"DoubleBox", GetAttributeObject(n"DoubleBox"));
		OutParams.AddObject(n"Interaction", GetAttributeObject(n"Interaction"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);
		bCanceled = false;
		bExitAnimationFinished = false;
		bPushing = false;
        CurrentBox = Cast<APushableDoubleBox>(ActivationParams.GetObject(n"DoubleBox"));
		Interaction = Cast<UHazeTriggerComponent>(ActivationParams.GetObject(n"Interaction"));

        Player.BlockCapabilities(CapabilityTags::Movement, this);

        UAnimSequence PushAnimation = Player.IsCody() ? CodyMH : MayMH;

        Player.PlaySlotAnimation(Animation = PushAnimation, BlendTime = 0.2f, bLoop = true);

		Player.AttachToComponent(CurrentBox.Base, AttachmentRule = EAttachmentRule::KeepWorld);

		Player.SmoothSetLocationAndRotation(Interaction.WorldLocation, Interaction.WorldRotation);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ClampYawLeft = 15.f;
		ClampSettings.ClampYawRight = 15.f;
		ClampSettings.ClampPitchDown = 25.f;
		ClampSettings.ClampPitchUp = 10.f;
		ClampSettings.bUseClampPitchDown = true;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.bUseClampYawLeft = true;
		ClampSettings.bUseClampYawRight = true;
		Player.ApplyCameraClampSettings(ClampSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);
		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 260.f), CameraBlend::Additive(2.f), this);

		if (CurrentBox.bShowCancelPrompt)
			ShowCancelPrompt(Player, this);

		PreviousBoxLocation = CurrentBox.Base.RelativeLocation.Y;	

		AudioMoveComp.SetTraversalTypeSwitch(HazeAudio::EPlayerMovementState::HeavyWalk);
		AudioMoveComp.SetCanUpdateTraversalType(false);
		Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterMovementType, HazeAudio::EPlayerMovementState::HeavyWalk);
	}

	void PlayStruggleAnimation()
	{
		UAnimSequence StruggleAnimation = Player.IsCody() ? CodyStruggleAnimation : MayStruggleAnimation;

		if (CurrentBox.bPlayReminderBarks)
		{
			if (Interaction == CurrentBox.LeftInteraction && !CurrentBox.RightInteraction.IsDisabled(n"Interacted"))
			{
				if (Player.IsMay())
					CurrentBox.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumDoubleInteractDumbbellReminderMay");
				else
					CurrentBox.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumDoubleInteractDumbbellReminderCody");
			}
			else if (Interaction == CurrentBox.RightInteraction && !CurrentBox.LeftInteraction.IsDisabled(n"Interacted"))
			{
				if (Player.IsMay())
					CurrentBox.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumDoubleInteractDumbbellReminderMay");
				else
					CurrentBox.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumDoubleInteractDumbbellReminderCody");
			}
		}

		if(!Player.IsPlayingAnimAsSlotAnimation(StruggleAnimation))
			Player.PlaySlotAnimation(Animation = StruggleAnimation, BlendTime = 0.2f, bLoop = true);
	}

	void PlayPushAnimation()
	{
		UAnimSequence PushAnimation = Player.IsCody() ? CodyPushAnimation : MayPushAnimation;

		if(!Player.IsPlayingAnimAsSlotAnimation(PushAnimation))
			Player.PlaySlotAnimation(Animation = PushAnimation, BlendTime = 0.2f, bLoop = true);
	}

	void PlayMH()
	{
		UAnimSequence MHAnim = Player.IsCody() ? CodyMH : MayMH;

		if(!Player.IsPlayingAnimAsSlotAnimation(MHAnim))
			Player.PlaySlotAnimation(Animation = MHAnim, BlendTime = 0.2f, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraClampSettingsByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this, 2.f);
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
        Player.StopAnimation();
        Player.SetCapabilityActionState(n"PushingDoubleBox", EHazeActionState::Inactive);
        Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
        CurrentBox.ReleaseBox(Interaction);
		CurrentBox.ResetPushPower(Player);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);

		CurrentBox.NetSetPushingStatus(Player, false);

		RemoveCancelPromptByInstigator(Player, this);
		AudioMoveComp.SetCanUpdateTraversalType(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bCanceled)
			return;

        FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		
		if (!CurrentBox.bUseForwardInput)
			Input.Y = Input.X;

		if (Input.Y > 0)
		{
			if (!bPushing)
			{
				bPushing = true;
				CurrentBox.NetSetPushingStatus(Player, true);
			}
		}
		else
		{
			if (bPushing)
			{
				bPushing = false;
				CurrentBox.NetSetPushingStatus(Player, false);
			}
		}

		if (CurrentBox.bBothPlayersPushing || (CurrentBox.Base.RelativeLocation.Y != PreviousBoxLocation))
			PlayPushAnimation();
		else if (bPushing)
			PlayStruggleAnimation();
		else
			PlayMH();

		if (WasActionStarted(ActionNames::Cancel))
		{
			PlayExitAnimation();
		}

		PreviousBoxLocation = CurrentBox.Base.RelativeLocation.Y;
	}

	void PlayExitAnimation()
	{
		bCanceled = true;
		CurrentBox.ResetPushPower(Player);
		CurrentBox.NetSetPushingStatus(Player, false);
		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"ExitAnimationFinished");
		UAnimSequence ExitAnim = Player.IsCody() ? CodyExitAnimation : MayExitAnimation;
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = ExitAnim);
	}

	UFUNCTION()
	void ExitAnimationFinished()
	{
		bExitAnimationFinished = true;
	}
}