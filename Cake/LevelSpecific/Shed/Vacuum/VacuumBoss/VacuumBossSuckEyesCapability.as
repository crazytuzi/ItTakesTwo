import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Cake.LevelSpecific.Shed.Vacuum.ControlVacuumABP;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBoss;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

UCLASS(Abstract)
class UVacuumBossSuckEyesCapability : UHazeCapability
{
    default CapabilityTags.Add(n"GameplayAction");
    default CapabilityTags.Add(n"Vacuum");
    default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 6;

    AHazePlayerCharacter Player;
	AVacuumBoss VacuumBossActor;

	bool bLanded = false;
	bool bLeftHose = false;

    UPROPERTY()
    UAnimSequence CodyEnterAnimation;
    UPROPERTY()
    UAnimSequence MayEnterAnimation;

    UPROPERTY()
    UAnimSequence CodyExitAnimation;
    UPROPERTY()
    UAnimSequence MayExitAnimation;

    UPROPERTY()
    UBlendSpace MayBlendSpace;
    UPROPERTY()
    UBlendSpace CodyBlendSpace;

	UPROPERTY()
	ULocomotionFeatureControlVacuumABP MayFeature;
	UPROPERTY()
	ULocomotionFeatureControlVacuumABP CodyFeature;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMovingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SuckEyeEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSuckEyeEvent;

	private FHazeAudioEventInstance MovingEventInstance;

	float TargetBlendSpaceValue;
    FTimerHandle BlendSpaceTimer;

	float SuckValue = 0.f;
	float SuckMinValue = 0.f;
	bool bButtonMashStarted = false;
	bool bEyesFullySucked = false;
	float LastSuckValue;

	UButtonMashHandleBase ButtonMashHandle;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        Player = Cast<AHazePlayerCharacter>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if(IsActioning(n"SuckEyes"))
            return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		VacuumBossActor = Cast<AVacuumBoss>(GetAttributeObject(n"VacuumBoss"));
		bLeftHose = GetActionStatus(n"LeftHose") == EActionStateStatus::Active ? true : false;

		bLanded = false;
		Player.TriggerMovementTransition(this);

		ULocomotionFeatureControlVacuumABP Feature = Player.IsCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(Feature);

        TargetBlendSpaceValue = 0.f;

        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
	    Player.BlockCapabilities(CapabilityTags::Interaction, this);

        Player.SetCapabilityActionState(n"InteractedWithVacuum", EHazeActionState::Inactive);

		FName Socket = bLeftHose ? n"LeftHand" : n"RightHand";

        if (Player.HasControl())
            BlendSpaceTimer = System::SetTimer(this, n"UpdateBlendSpaceValue", 0.2f, true);

		USceneComponent Attachment = bLeftHose ? VacuumBossActor.LeftAttachPoint : VacuumBossActor.RightAttachPoint;
		Player.SmoothSetLocationAndRotation(Attachment.WorldLocation, Attachment.WorldRotation);
		Player.AttachToComponent(VacuumBossActor.BossMesh, Socket, EAttachmentRule::KeepWorld);

		UAnimSequence MountAnimation = Player.IsCody() ? CodyEnterAnimation : MayEnterAnimation;
		float Blend = Player.IsMay() ? 0.18f : 0.23f;

		FHazeAnimationDelegate LandedDelegate;
		LandedDelegate.BindUFunction(this, n"Landed");
        Player.PlaySlotAnimation(OnBlendingOut = LandedDelegate, Animation = MountAnimation, BlendTime = Blend);

		if (bLeftHose)
		{
			VacuumBossActor.LeftSuckSyncComp.OverrideControlSide(this);
		}
		else
		{
			VacuumBossActor.RightSuckSyncComp.OverrideControlSide(this);
		}
    }

	UFUNCTION()
	void Landed()
	{
		bLanded = true;
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

        if (Player.HasControl())
            System::ClearAndInvalidateTimerHandle(BlendSpaceTimer);

        Player.SetCapabilityActionState(n"InteractedWithVacuum", EHazeActionState::Inactive);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
	    Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		Player.PlayerHazeAkComp.HazePostEvent(StopMovingEvent);
		Player.PlayerHazeAkComp.HazePostEvent(StopSuckEyeEvent);

		if (ButtonMashHandle != nullptr)
		{
			ButtonMashHandle.StopButtonMash();
			ButtonMashHandle = nullptr;
		}
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (HasControl())
		{
			if (!bButtonMashStarted)
			{
				float InputSize = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Size();

				TargetBlendSpaceValue = InputSize;

				SuckValue += InputSize * 0.10f * DeltaTime;
				if (InputSize == 0)
					SuckValue -= 0.15f * DeltaTime;
				SuckValue = FMath::Clamp(SuckValue, SuckMinValue, 1.f);
				if (SuckValue >= 0.6f && !bButtonMashStarted)
				{
					bButtonMashStarted = true;

					NetStartButtonMash();
					SuckMinValue = 0.6f;
				}
			}
			else if (!bEyesFullySucked)
			{
				float TargetSuckValue = SuckValue + ButtonMashHandle.MashRateControlSide * 0.9f * DeltaTime;
				float SuckInterpSpeed = 1.f;

				if (ButtonMashHandle.MashRateControlSide <= 1.5f)
				{
					TargetSuckValue = 0.6f;
					SuckInterpSpeed = 0.45f;
					TargetBlendSpaceValue = 0.f;
				}
				else
				{
					TargetBlendSpaceValue = 1.f;
				}
				SuckValue = FMath::FInterpTo(SuckValue, TargetSuckValue, DeltaTime, SuckInterpSpeed);

				SuckValue = FMath::Clamp(SuckValue, 0.6f, 1.f);

				if (SuckValue == 1 && !bEyesFullySucked)
				{
					bEyesFullySucked = true;
					NetStopButtonMash();
					VacuumBossActor.NetEyeFullySucked();
					Player.PlayerHazeAkComp.HazePostEvent(ImpactEvent);
					Player.PlayerHazeAkComp.HazePostEvent(SuckEyeEvent);
				}
			}

			if (bLeftHose)
			{
				VacuumBossActor.LeftSuckSyncComp.Value = SuckValue;
			}
			else
			{
				
				VacuumBossActor.RightSuckSyncComp.Value = SuckValue;
			}
		}
		else
		{
			SuckValue = bLeftHose ? VacuumBossActor.LeftSuckSyncComp.Value : VacuumBossActor.RightSuckSyncComp.Value;
		}

		if (bLeftHose)
		{
			VacuumBossActor.SetAnimFloatParam(n"LeftArmOverride", SuckValue);
			VacuumBossActor.LeftSuckValue = SuckValue;
		}
		else
		{
			VacuumBossActor.SetAnimFloatParam(n"RightArmOverride", SuckValue);
			VacuumBossActor.RightSuckValue = SuckValue;
		}

		if (SuckValue >= 0.1f)
			VacuumBossActor.OneArmSlightlyRaised(bLeftHose);

		if (SuckValue >= 0.6f && !VacuumBossActor.bOneArmMashStarted)
			VacuumBossActor.OneArmMashStarted();

		if (SuckValue == 0.f && bLeftHose && !VacuumBossActor.bLeftArmIdle)
			VacuumBossActor.OneArmFullyReset(true);

		if (SuckValue == 0.f && !bLeftHose && !VacuumBossActor.bRightArmIdle)
			VacuumBossActor.OneArmFullyReset(false);

		if(!bLanded)
			return;

		Player.SetAnimFloatParam(n"BlendSpaceY", TargetBlendSpaceValue);

		FHazeRequestLocomotionData AnimData;
		AnimData.AnimationTag = n"ControlVacuumABP";
		Player.RequestLocomotion(AnimData);

		HandleMovementAudio(SuckValue);

		if (DidLandOnFloor(SuckValue))
		{
			Player.PlayerHazeAkComp.HazePostEvent(ImpactEvent);
		}

		if (Player.PlayerHazeAkComp.EventInstanceIsPlaying(MovingEventInstance))
		{
			const float DirectionRtpcValue = FMath::Sign(SuckValue - LastSuckValue);
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Events_SuckEyeVacuum_Direction", DirectionRtpcValue);
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Events_SuckEyeVacuum_Progress", SuckValue);
		}

		LastSuckValue = SuckValue;
    }

	bool DidLandOnFloor(const float CurrentSuckValue)
	{
		if(CurrentSuckValue == 0.f && LastSuckValue > 0.f)
			return true;

		return false;		
	}

	void HandleMovementAudio(const float CurrentSuckValue)
	{
		if (LastSuckValue == 0.f && CurrentSuckValue > 0.f)
		{
			MovingEventInstance = Player.PlayerHazeAkComp.HazePostEvent(StartMovingEvent);
		}
		else if (CurrentSuckValue == 0.f && Player.PlayerHazeAkComp.EventInstanceIsPlaying(MovingEventInstance))
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopMovingEvent);
		}
	}
	
    UFUNCTION()
    void UpdateBlendSpaceValue()
    {
        NetUpdateBlendSpaceValue(TargetBlendSpaceValue);
    }

    UFUNCTION(NetFunction)
    void NetUpdateBlendSpaceValue(float BlendSpaceValue)
    {
        TargetBlendSpaceValue = BlendSpaceValue;
    }

	UFUNCTION(NetFunction)
	void NetStartButtonMash()
	{
		FName ButtonMashAttachSocket = bLeftHose ? n"LeftHand" : n"RightHand";
		FVector AttachOffset = FVector(0.f, -160.f, 120.f);
		if (bLeftHose)
			AttachOffset.Y *= -1.f;

		ButtonMashHandle = StartButtonMashDefaultAttachToComponent(Player, VacuumBossActor.BossMesh, ButtonMashAttachSocket, AttachOffset);
	}

	UFUNCTION(NetFunction)
	void NetStopButtonMash()
	{
		if (ButtonMashHandle != nullptr)
		{
			ButtonMashHandle.StopButtonMash();
			ButtonMashHandle = nullptr;
		}
	}
}