import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;

class UMagneticPlayerAttractionChargeCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionChargeCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;

	UCameraShakeBase CameraShake;
	UNiagaraComponent TrailEffect;

	FVector PlayerToOtherPlayer;

	const float ChargeDuration = 0.5f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnet = UMagneticPlayerComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Charging)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);

		PlayerOwner.AddLocomotionAsset(MagneticPlayerAttraction.GetAnimationFeature(), MagneticPlayerAttraction);
		AnimationDataComponent.Reset();

		PlayerToOtherPlayer = GetAttributeVector(n"PlayerToOtherPlayer");

		FocusCameraOnOtherPlayer();
		CameraShake = PlayerOwner.PlayCameraShake(MagneticPlayerAttraction.ChargeCameraShakeClass, 5.f);

		TrailEffect = Niagara::SpawnSystemAttached(MagneticPlayerAttraction.TrailEffect, PlayerOwner.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		// Fire charging
		PlayerMagnet.PlayerMagnet.OnMPAChargeStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionCharge");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		MoveComp.SetTargetFacingDirection(PlayerToOtherPlayer, 5.f);
		MoveData.ApplyTargetRotationDelta();

		float ChargeProgress = Math::Saturate(ElapsedTime / ChargeDuration);
		MoveData.ApplyDelta(PlayerOwner.ActorUpVector * 200.f * FMath::Square(ChargeProgress) * DeltaTime);

		MoveCharacter(MoveData, n"MagnetAttract");

		// Rotate player pitch
		PlayerOwner.MeshOffsetComponent.OffsetRotationWithSpeed(PlayerToOtherPlayer.Rotation(), 5.f);

		PlayerOwner.SetFrameForceFeedback(0.025f, 0.025f);

		ElapsedTime += DeltaTime;
		if(ElapsedTime >= ChargeDuration && HasControl())
			MagneticPlayerAttraction.NetSetChargingIsDone(true);

		// Update charge progress
		PlayerMagnet.PlayerMagnet.MagnetChargeProgress = ChargeProgress;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Charging)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.StopCameraShake(CameraShake);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		TrailEffect.Deactivate();

		// Fire appropriate event
		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Inactive)
		{
			PlayerMagnet.PlayerMagnet.OnMPAChargeCancelled.Broadcast();

			// Reset mesh rotation if player cancelled charge
			PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();
		}
		else
		{
			PlayerMagnet.PlayerMagnet.OnMPAChargeDone.Broadcast();

			// Reset mesh rotation if capability didn't finish normally
			if(DeactivationParams.DeactivationReason != ECapabilityStatusChangeReason::Natural)
				PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();
		}


		// Reset charge progress
		PlayerMagnet.PlayerMagnet.MagnetChargeProgress = 0.f;

		// Cleanup
		MagneticPlayerAttraction = nullptr;
		ElapsedTime = 0.f;
	}

	void FocusCameraOnOtherPlayer()
	{
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::Object;
		PointOfInterest.FocusTarget.Actor = PlayerOwner.OtherPlayer;
		PointOfInterest.Blend = ChargeDuration;

		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);
		PlayerOwner.ApplyCameraSettings(MagneticPlayerAttraction.ChargeCameraSettings, FHazeCameraBlendSettings(ChargeDuration), this);
	}
}
