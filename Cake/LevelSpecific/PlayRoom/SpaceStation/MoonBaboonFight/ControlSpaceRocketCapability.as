import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocket;
import Vino.Tutorial.TutorialStatics;
import Peanuts.SpeedEffect.SpeedEffectStatics;

UCLASS(Abstract)
class UControlSpaceRocketCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;

	ASpaceRocket SpaceRocketActor;

	UPROPERTY()
	UAnimSequence CodyMountAnimation;
	UPROPERTY()
	UAnimSequence MayMountAnimation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveRocketUpTimeLike;
	default MoveRocketUpTimeLike.Duration = 0.25f;

	FVector RocketStartLoc;

	UPROPERTY()
	UBlendSpace CodyBlendSpace;
	UPROPERTY()
	UBlendSpace MayBlendSpace;

	UPROPERTY()
	UAnimSequence CodyJumpOffAnimation;
	UPROPERTY()
	UAnimSequence MayJumpOffAnimation;

	UPROPERTY()
	UForceFeedbackEffect ExplosionForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ExplosionCamShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ConstantCamShake;
	UCameraShakeBase ConstantCamShakeInstance;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	FVector2D CurrentBlendSpaceValues;
	FVector2D TargetBlendSpaceValues;

	float TimeSinceLastCameraInput = 0.f;
	bool bPointOfInterestActive = false;

	FTimerHandle BlendSpaceSyncTimer;

	bool bMounting = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"ControlSpaceRocket"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ControlSpaceRocket"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SpaceRocket", GetAttributeObject(n"SpaceRocketActor"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bMounting = true;
		SpaceRocketActor = Cast<ASpaceRocket>(ActivationParams.GetObject(n"SpaceRocket"));

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"ChangeSize", this);
		Player.BlockCapabilities(n"KnockDown", this);
		Player.TriggerMovementTransition(this);

		Player.SmoothSetLocationAndRotation(SpaceRocketActor.AttachmentPoint.WorldLocation, SpaceRocketActor.AttachmentPoint.WorldRotation);
		Player.AttachToComponent(SpaceRocketActor.AttachmentPoint, AttachmentRule = EAttachmentRule::KeepWorld);

		FHazeAnimationDelegate MountAnimFinishedDelegate;
		MountAnimFinishedDelegate.BindUFunction(this, n"MountAnimFinished");
		
		UAnimSequence EnterAnim = Player.IsCody() ? CodyMountAnimation : MayMountAnimation;
		Player.PlaySlotAnimation(OnBlendingOut = MountAnimFinishedDelegate, Animation = EnterAnim);

		MoveRocketUpTimeLike.BindUpdate(this, n"UpdateMoveRocketUp");
		RocketStartLoc = SpaceRocketActor.ActorLocation;
		MoveRocketUpTimeLike.PlayFromStart();

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = SpaceRocketActor;
		PoI.FocusTarget.LocalOffset = FVector(5000.f, 0.f, -1500.f);
		PoI.Blend.BlendTime = 0.5f;
		PoI.Duration = 1.f;
		Player.ApplyPointOfInterest(PoI, this);

		SpaceRocketActor.CurrentMovementSpeed = SpaceRocketActor.DefaultPlayerSpeed;
	}

	UFUNCTION()
	void UpdateMoveRocketUp(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(RocketStartLoc, RocketStartLoc + FVector(0.f, 0.f, 150.f), CurValue);
		SpaceRocketActor.SetActorLocation(CurLoc);

		float CurPitch = FMath::Lerp(0.f, 25.f, CurValue);
		SpaceRocketActor.SetActorRotation(FRotator(CurPitch, SpaceRocketActor.ActorRotation.Yaw, 0.f));
	}

	UFUNCTION()
	void MountAnimFinished()
	{
		if (SpaceRocketActor.bPermanentlyDisabled)
		{
			Player.SetCapabilityActionState(n"ControlSpaceRocket", EHazeActionState::Inactive);
			return;
		}

		bMounting = false;

		UBlendSpace BlendSpace = Player.IsCody() ? CodyBlendSpace : MayBlendSpace;
        Player.PlayBlendSpace(BlendSpace);

		SpaceRocketActor.StartMovingRocket();

		Player.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(), this);
		bPointOfInterestActive = false;
		TimeSinceLastCameraInput = 2.f;

		Player.PlayForceFeedback(ExplosionForceFeedback, false, true, NAME_None);

		ConstantCamShakeInstance = Player.PlayCameraShake(ConstantCamShake);

		FName EventName = Player.IsMay() ? n"FoghornDBPlayRoomSpaceStationBossFightRocketMountMay" : n"FoghornDBPlayRoomSpaceStationBossFightRocketMountCody";
		SpaceRocketActor.VOBank.PlayFoghornVOBankEvent(EventName);

		if (HasControl())
			BlendSpaceSyncTimer = System::SetTimer(this, n"UpdateBlendSpaceValues", 0.1f, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"ChangeSize", this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(n"KnockDown", this);

		Player.StopAnimation();
		Player.StopBlendSpace();
		Player.ClearCameraSettingsByInstigator(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		UAnimSequence JumpOffAnim = Player.IsCody() ? CodyJumpOffAnimation : MayJumpOffAnimation;
		Player.PlaySlotAnimation(Animation = JumpOffAnim, StartTime = 0.4f);
		Player.AddImpulse(FVector(0.f, 0.f, 2500.f));
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		Player.PlayForceFeedback(ExplosionForceFeedback, false, true, NAME_None);
		Player.StopCameraShake(ConstantCamShakeInstance);
		Player.PlayCameraShake(ExplosionCamShake);

		Player.RemoveTutorialPromptByInstigator(this);

		if (HasControl())
			System::ClearAndInvalidateTimerHandle(BlendSpaceSyncTimer);

		if (HasControl() && Player.IsPlayerDead())
			SpaceRocketActor.NetTriggerExplosion();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bMounting)
			return;

		if (HasControl())
		{
			FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if (Player.IsSteeringPitchInverted())
				PlayerInput.Y *= -1.f;

			TargetBlendSpaceValues = PlayerInput;
			SpaceRocketActor.UpdatePlayerInput(PlayerInput);

			FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			if (CameraInput.Size() == 0.f)
			{
				TimeSinceLastCameraInput += DeltaTime;
				if (TimeSinceLastCameraInput >= 1.f)
				{
					bPointOfInterestActive = true;
					FHazePointOfInterest PoI;
					PoI.FocusTarget.Actor = SpaceRocketActor;
					PoI.FocusTarget.LocalOffset = FVector(2000.f, PlayerInput.X * 4000.f, 150.f);
					PoI.Blend.BlendTime = 3.f;
					Player.ApplyPointOfInterest(PoI, this);
				}
			}
			else
			{
				TimeSinceLastCameraInput = 0.f;
				Player.ClearPointOfInterestByInstigator(this);
			}

			Player.SetFrameForceFeedback(0.05f, 0.05f);
		}

		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, TargetBlendSpaceValues.X * 220.f, 0.f), FHazeCameraBlendSettings(3.f), this);

		CurrentBlendSpaceValues.X = FMath::FInterpTo(CurrentBlendSpaceValues.X, TargetBlendSpaceValues.X, DeltaTime, 8.f);
		CurrentBlendSpaceValues.Y = FMath::FInterpTo(CurrentBlendSpaceValues.Y, TargetBlendSpaceValues.Y, DeltaTime, 8.f);
		Player.SetBlendSpaceValues(CurrentBlendSpaceValues.X, CurrentBlendSpaceValues.Y);

		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(1.f, this));

		SpaceRocketActor.HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_Movement_Delta", TargetBlendSpaceValues.Size(), 0);
	}

	UFUNCTION()
	void UpdateBlendSpaceValues()
	{
		NetUpdateBlendSpaceValues(TargetBlendSpaceValues);
	}

	UFUNCTION(NetFunction)
	void NetUpdateBlendSpaceValues(FVector2D Values)
	{
		TargetBlendSpaceValues = Values;
	}
}