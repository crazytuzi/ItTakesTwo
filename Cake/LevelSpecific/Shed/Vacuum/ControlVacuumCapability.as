import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Cake.LevelSpecific.Shed.Vacuum.ControlVacuumABP;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

UCLASS(Abstract)
class UControlVacuumCapability : UHazeCapability
{
    default CapabilityTags.Add(n"GameplayAction");
    default CapabilityTags.Add(n"Vacuum");
    default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 6;

    AHazePlayerCharacter Player;
    AVacuumHoseActor Hose;
    USceneComponent AttachmentPoint;
    EVacuumMountLocation MountLocation;

	bool bThrownOff = false;
	bool bLanded = false;

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
    UHazeCameraSpringArmSettingsDataAsset MountedCameraSettings;

	UPROPERTY()
	ULocomotionFeatureControlVacuumABP MayFeature;
	UPROPERTY()
	ULocomotionFeatureControlVacuumABP CodyFeature;

	UPROPERTY()
	UVacuumVOBank VOBank;

    FVector2D TargetBlendSpaceValue;
    FTimerHandle BlendSpaceTimer;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        Player = Cast<AHazePlayerCharacter>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (IsActioning(n"InteractedWithVacuum"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        
		return EHazeNetworkActivation::DontActivate;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (WasActionStarted(ActionNames::Cancel))
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(n"ThrownOffHose"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        
		return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
        OutParams.AddObject(n"Hose", GetAttributeObject(n"Hose"));
		OutParams.AddNumber(n"MountLocation", GetAttributeNumber(n"MountLocation"));
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bLanded = false;
		Player.TriggerMovementTransition(this);

		ULocomotionFeatureControlVacuumABP Feature = Player.IsCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(Feature);

        TargetBlendSpaceValue = FVector2D::ZeroVector;

        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
	    Player.BlockCapabilities(CapabilityTags::Interaction, this);

        Hose = Cast<AVacuumHoseActor>(ActivationParams.GetObject(n"Hose"));

        Player.SetCapabilityActionState(n"InteractedWithVacuum", EHazeActionState::Inactive);
        Player.SetCapabilityActionState(n"ThrownOffHose", EHazeActionState::Inactive);

        bThrownOff = false;

        MountLocation = ActivationParams.GetNumber(n"MountLocation") == 0 ? EVacuumMountLocation::Front : EVacuumMountLocation::Back;
        AttachmentPoint = MountLocation == EVacuumMountLocation::Front ? Hose.FrontAttachmentPoint : Hose.BackAttachmentPoint;

        if(Player.HasControl())
            BlendSpaceTimer = System::SetTimer(this, n"UpdateBlendSpaceValue", 0.2f, true);

		// Player.SmoothSetLocationAndRotation(AttachmentPoint.WorldLocation, AttachmentPoint.WorldRotation, 1200.f);

		Player.AttachToComponent(Parent = AttachmentPoint, AttachmentRule = EAttachmentRule::SnapToTarget);

		UAnimSequence MountAnimation = Player.IsCody() ? CodyEnterAnimation : MayEnterAnimation;

		FHazeAnimationDelegate LandedDelegate;
		LandedDelegate.BindUFunction(this, n"Landed");
		float Blend = Player.IsMay() ? 0.18f : 0.23f;
        Player.PlaySlotAnimation(OnBlendingOut = LandedDelegate, Animation = MountAnimation, BlendTime = 0.03f);
		// Player.TeleportActor(AttachmentPoint.WorldLocation, AttachmentPoint.WorldRotation);

		Player.ApplyCameraSettings(MountedCameraSettings, FHazeCameraBlendSettings(1.f), this);
		if (Hose.MountedIdealDistanceOverride != 0)
			Player.ApplyIdealDistance(Hose.MountedIdealDistanceOverride, FHazeCameraBlendSettings(1.f), this);

		ShowCancelPrompt(Player, this);

		if (Hose.bTellOtherPlayerToEnter && Player.GetDistanceTo(Player.OtherPlayer) <= 3000.f)
		{
			if ((MountLocation == EVacuumMountLocation::Front && Hose.FrontVacuumMode == EVacuumMode::Blow) || (MountLocation == EVacuumMountLocation::Back && Hose.FrontVacuumMode == EVacuumMode::Suck))
			{
				if (Player.IsCody())
					VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumHosePartnerCody");
				else
					VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumHosePartnerMay");
			}
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
		Player.CleanupCurrentMovementTrail();
        Player.StopBlendSpace();
        Player.ClearCameraSettingsByInstigator(this);
		Player.ClearIdealDistanceByInstigator(this, 1.f);

		UAnimSequence ExitAnimation = Player.IsCody() ? CodyExitAnimation : MayExitAnimation;
        Player.PlaySlotAnimation(Animation = ExitAnimation, BlendTime = 0.05f);

        if (Player.HasControl())
            System::ClearAndInvalidateTimerHandle(BlendSpaceTimer);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);

        Player.SetCapabilityActionState(n"ThrownOffHose", EHazeActionState::Inactive);
        Player.SetCapabilityActionState(n"InteractedWithVacuum", EHazeActionState::Inactive);
		Hose.DismountHose(MountLocation);

		System::SetTimer(this, n"Launch", 0.38f, false);

		RemoveCancelPromptByInstigator(Player, this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
    }

	UFUNCTION()
	void Launch()
	{
		Player.TriggerMovementTransition(this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
	    Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		EnableInteraction();
	}

	void EnableInteraction()
	{
		if(MountLocation == EVacuumMountLocation::Front)
			Hose.FrontInteractionComp.Enable(n"FrontSeatOccupied");
		else
			Hose.BackInteractionComp.Enable(n"BackSeatOccupied");
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (HasControl())
		{
			FVector2D CurrentInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
        	CurrentInput.Y = -CurrentInput.Y;
			Hose.UpdateForces(CurrentInput, MountLocation);

			TargetBlendSpaceValue.X = CurrentInput.X;
            TargetBlendSpaceValue.Y = -CurrentInput.Y;

			float HoseVelocitySize;
			if (MountLocation == EVacuumMountLocation::Front)
				HoseVelocitySize = Hose.FirstCollisionSphere.ComponentVelocity.Size();
			else
				HoseVelocitySize = Hose.LastCollisionSphere.ComponentVelocity.Size();
			if (HoseVelocitySize >= 100.f)
				Player.SetFrameForceFeedback(0.05f, 0.05f);
		}

		if(!bLanded)
			return;

		Player.SetAnimFloatParam(n"BlendSpaceX", TargetBlendSpaceValue.X);
		Player.SetAnimFloatParam(n"BlendSpaceY", TargetBlendSpaceValue.Y);

		FHazeRequestLocomotionData AnimData;
		AnimData.AnimationTag = n"ControlVacuumABP";
		Player.RequestLocomotion(AnimData);

		// Player.SetBlendSpaceValues(TargetBlendSpaceValue.X, -TargetBlendSpaceValue.Y);
    }
	
    UFUNCTION()
    void UpdateBlendSpaceValue()
    {
        NetUpdateBlendSpaceValue(TargetBlendSpaceValue);
    }

    UFUNCTION(NetFunction)
    void NetUpdateBlendSpaceValue(FVector2D BlendSpaceValue)
    {
        TargetBlendSpaceValue = BlendSpaceValue;
    }
}