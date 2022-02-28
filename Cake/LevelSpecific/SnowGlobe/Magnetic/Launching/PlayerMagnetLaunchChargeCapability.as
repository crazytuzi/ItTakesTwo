import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Effects.PostProcess.PostProcessing;

class UPlayerMagnetLaunchChargeCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunch);
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunchChargeCapability);

	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 189;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ChargeCameraSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ChargeCameraShakeClass;
	UCameraShakeBase ChargeCameraShake;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;
	UMagneticPerchAndBoostComponent MagnetPerch;

	UPostProcessingComponent PostProcessingComponent;

	const float ChargeDuration = 0.4f;
	const float LevitationForce = 500.f;

	FVector InitialPlayerToMagnet;

	float ElapsedTime;
	float InitialDistanceToMagnet;

	bool bShouldSkipLaunch;
	bool bChargeComplete;

	bool bCapabilitiesBlocked;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
		PostProcessingComponent = UPostProcessingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerOwner.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchCapability))
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		// Avoid spamming
		if(WasActionStartedDuringTime(FMagneticTags::MagnetAttractionJustDeactivated, 0.2f))
			return EHazeNetworkActivation::DontActivate;

		UMagneticPerchAndBoostComponent CurrentTargetedMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.GetTargetedMagnet());
		if(CurrentTargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UMagneticPerchAndBoostComponent CurrentActivatedMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.GetActivatedMagnet());
		if(CurrentActivatedMagnet != nullptr)
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if player is trying to perch back to the magnet that he's currently jumping from
		if(PlayerOwner.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchJumpCapability) && CurrentTargetedMagnet == MagnetPerch)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerComponent.HasEqualPolarity(CurrentTargetedMagnet))
		 	return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetedMagnet.IsInfluencedBy(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		UMagneticPerchAndBoostComponent TargetedMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.GetTargetedMagnet());
		SyncParams.AddObject(n"CurrentMagnet", TargetedMagnet);

		if(ShouldSkipLaunch(TargetedMagnet))
			SyncParams.AddActionState(n"bShouldSkipLaunch");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		ConsumeAction(FMagneticTags::MagnetAttractionJustDeactivated);
		PlayerOwner.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

		MagnetPerch = Cast<UMagneticPerchAndBoostComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		MagneticPlayerComponent.ActivateMagnetLockon(MagnetPerch, MagneticPlayerComponent);

		InitialPlayerToMagnet = MagnetPerch.WorldLocation - PlayerOwner.ActorLocation;
		InitialDistanceToMagnet = InitialPlayerToMagnet.Size();

 		// Add state machine asset; will start at 'bIsEntering' by default
		PlayerOwner.AddLocomotionAsset(MagnetPerch.GetLocomotionStateMachineAsset(PlayerOwner), AnimationDataComponent);
		AnimationDataComponent.Reset();

		// If player is standing on a floor magnet, don't charge, perch immediately
		if(ActivationParams.GetActionState(n"bShouldSkipLaunch"))
		{
			AnimationDataComponent.bIsEnteringGroundPerchWithNoFlight = true;
			bShouldSkipLaunch = true;
		}
		else
		{
			// Rotate player to match fly direction as capability charges
			// FRotator fix: eliminate shit roll in case we're directly below platform
			FRotator Rotation = Math::MakeRotFromX(MagnetPerch.Owner.ActorLocation - PlayerOwner.ActorCenterLocation);
			Rotation.Roll = 0.f;
			PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(Rotation, ChargeDuration);
		}

		// Move camera to focus on magnet, blend camera and shake it like it's huel
		if(MagnetPerch.bAffectCamera && !MagnetPerch.bShotByCannon)
		{
			FocusOnMagnetAndApplyCameraSettings();
			ChargeCameraShake = PlayerOwner.PlayCameraShake(ChargeCameraShakeClass, 5.f);
		}

		// Fire charge start event and reset value
		MagneticPlayerComponent.PlayerMagnet.OnLaunchChargeStarted.Broadcast();
		MagneticPlayerComponent.PlayerMagnet.MagnetChargeProgress = 0.f;

		// Turn off player collision
		PlayerOwner.Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		// Reset speed shimmer
		PostProcessingComponent.SpeedShimmer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;
		if(ElapsedTime >= ChargeDuration)
			bChargeComplete = true;

		// Compute progress and update event value
		float ChargeProgress = Math::Saturate(ElapsedTime / ChargeDuration);
		MagneticPlayerComponent.PlayerMagnet.MagnetChargeProgress = ChargeProgress;

		if(MoveComp.CanCalculateMovement())
		{
			// Calculate movement
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(FMagneticTags::PlayerMagnetLaunchChargeCapability);
			MoveData.OverrideStepDownHeight(0.f);
			MoveData.OverrideStepUpHeight(0.f);

			FVector PlayerToMagnet = (MagnetPerch.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();

			if(HasControl())
			{
				// If player started by standing on the magnet, just move him closer
				if(bShouldSkipLaunch)
				{
					PlayerToMagnet = InitialPlayerToMagnet;
					MoveData.ApplyDelta(PlayerToMagnet / ChargeDuration * DeltaTime);
					//MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);

					MoveData.SetMoveWithComponent(UStaticMeshComponent::Get(MagnetPerch.Owner));
				}
				else
				{
					// Levitate player
					float ExpMultiplier = FMath::Square(ChargeProgress * 1.2f);
					MoveData.ApplyVelocity(PlayerOwner.MovementWorldUp * LevitationForce * ExpMultiplier);

					MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
				}

				// Handle rotation
				MoveComp.SetTargetFacingDirection(PlayerToMagnet.GetSafeNormal());
				MoveData.ApplyTargetRotationDelta();

				// Leave that sweet sweet control crumb
				CrumbComp.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized CrumbData;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
				MoveData.ApplyConsumedCrumbData(CrumbData);
			}

			MoveCharacter(MoveData, n"MagnetAttract");

			// Apply FF
			PlayerOwner.SetFrameForceFeedback(0.25f * ChargeProgress, 0.15 * ChargeProgress);

			// Start blurring screen a bit
			PostProcessingComponent.SpeedShimmer = 0.1f * ChargeProgress;
		}	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(bChargeComplete)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!MagneticPlayerComponent.MagnetLockonIsActivatedBy(MagneticPlayerComponent))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UMagneticPerchAndBoostComponent CurrentActiveMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.GetActivatedMagnet());
		if(MagneticPlayerComponent.HasEqualPolarity(CurrentActiveMagnet))
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(MagnetPerch.bIsDisabled)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(bChargeComplete)
			SyncParams.AddActionState(n"ChargeComplete");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Move to launch state if charging was commplete
		if(DeactivationParams.GetActionState(n"ChargeComplete") && DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{
			if(bShouldSkipLaunch)
			{
				PlayerOwner.SetCapabilityActionState(FMagneticTags::PlayerMagnetLaunchPerchState, EHazeActionState::ActiveForOneFrame);
				PlayerOwner.SetCapabilityAttributeObject(n"MagnetPerch", MagnetPerch);

				PlayerOwner.ClearPointOfInterestByInstigator(MagnetPerch);
			}
			else
			{
				PlayerOwner.SetCapabilityActionState(FMagneticTags::PlayerMagnetLaunchState, EHazeActionState::ActiveForOneFrame);
			}

			// Fire charge completion event
			MagneticPlayerComponent.PlayerMagnet.OnLaunchChargeDone.Broadcast();
		}
		else
		{
			// Charging was cancelled, clear everything up
			MagneticPlayerComponent.DeactivateMagnetLockon(MagneticPlayerComponent);
			PlayerOwner.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);

			PlayerOwner.ClearLocomotionAssetByInstigator(AnimationDataComponent);
			AnimationDataComponent.Reset();
			PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();

			// Clear shimmer
			PostProcessingComponent.SpeedShimmer = 0.f;

			// Reset collision
			PlayerOwner.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

			// Fire cancel event
			MagneticPlayerComponent.PlayerMagnet.OnLaunchChargeCancelled.Broadcast();

			// Clear point of interest
			PlayerOwner.ClearPointOfInterestByInstigator(MagnetPerch);
		}

		// Reset charge progress
		MagneticPlayerComponent.PlayerMagnet.MagnetChargeProgress = 0.f;

		// Clear camera stuff
		PlayerOwner.StopCameraShake(ChargeCameraShake);
		PlayerOwner.ClearCameraSettingsByInstigator(this);

		// Clean local variables
		InitialPlayerToMagnet = FVector::ZeroVector;

		ElapsedTime = 0.f;
		InitialDistanceToMagnet = 0.f;

		bShouldSkipLaunch = false;
		bChargeComplete = false;

		// Set deactivated action to avoid spamming
		PlayerOwner.SetCapabilityActionState(FMagneticTags::MagnetAttractionJustDeactivated, EHazeActionState::Active);
	}

	bool ShouldSkipLaunch(UMagneticPerchAndBoostComponent Magnet) const
	{
		if(Magnet == nullptr)
			return false;

		// Only skip if this is ein ground perch
		if(!Magnet.IsGroundPerch())
			return false;

		// Go ahead and skip if player is hovering above magnet
		FVector MagnetToPlayer = (PlayerOwner.ActorLocation - Magnet.Owner.ActorLocation).GetSafeNormal();
		if(Magnet.ForwardVector.DotProduct(MagnetToPlayer) > 0.9f)
			return true;

		// Otherwise skip if magnet is within sane range
		if(Magnet.WorldLocation.Distance(PlayerOwner.ActorLocation) > 600.f)
			return false;

		return true;
	}

	void FocusOnMagnetAndApplyCameraSettings()
	{
		FVector PerchPoint = MagnetPerch.GetPlayerPerchPoint(PlayerOwner);

		FHazePointOfInterest PoISettings;
		PoISettings.Blend = ChargeDuration * 3.f;
		PoISettings.FocusTarget.WorldOffset = PerchPoint;
		PoISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;

		// Launch capability will deactivate POI when it deactivates; unless we skip launch
		PlayerOwner.ApplyPointOfInterest(PoISettings, MagnetPerch);

		// Apply camera settings
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = ChargeDuration * 3.f;
		PlayerOwner.ApplyCameraSettings(ChargeCameraSettings, CamBlend, this, EHazeCameraPriority::High);
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(FMagneticTags::PlayerMagnetLaunchJumpCapability, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::AirJump, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::StickInput, this);

		bCapabilitiesBlocked = true;
	}

	void UnblockCapabilities()
	{
		if(!bCapabilitiesBlocked)
			return;

		PlayerOwner.UnblockCapabilities(FMagneticTags::PlayerMagnetLaunchJumpCapability, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::AirJump, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::StickInput, this);

		bCapabilitiesBlocked = false;
	}
}