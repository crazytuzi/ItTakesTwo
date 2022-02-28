import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;

UCLASS(Abstract)
class UPlayerMagnetLaunchPerchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunch);
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunchPerchCapability);

	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 191;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	UMaterialParameterCollection Collection;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;
	UPlayerPickupComponent PickupComponent;

	AMagnetBasePad MagnetActor;
	UMagneticPerchAndBoostComponent MagnetPerch;

	FHazeAcceleratedVector AcceleratedPivotOffset;

	EMagnetPlatformType PreviousPlatformType = EMagnetPlatformType::None;

	// Used to update perch rotation on every tick
	FVector RelativePerchForward;
	FVector RelativeWallPerchForward;

	const float EnterAnimationDuration = 0.5f;
	float ElapsedTime = 0.f;

	bool bIsPerching = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Player);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::Get(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(FMagneticTags::PlayerMagnetLaunchPerchState))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		UObject PerchObject;
		ConsumeAttribute(n"MagnetPerch", PerchObject);
		SyncParams.AddObject(n"MagnetPerch", PerchObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Set perching action state
		Player.SetCapabilityActionState(n"MagnetPerchStarted", EHazeActionState::Active);

		// Get perch magnet and activate it
		MagnetPerch = Cast<UMagneticPerchAndBoostComponent>(ActivationParams.GetObject(n"MagnetPerch"));
		MagnetActor = Cast<AMagnetBasePad>(MagnetPerch.Owner);
		MagneticPlayerComponent.ActivateMagnetLockon(MagnetPerch, MagneticPlayerComponent);

		// Smooth teleport to perch point
		FVector PerchForward = Player.ActorForwardVector.ConstrainToPlane(MagnetPerch.MagneticVector);
		if(MagnetPerch.CurrentPlatformType == EMagnetPlatformType::Wall)
		{
			FVector BiNormal = MagnetPerch.MagneticVector.CrossProduct(Player.MovementWorldUp);
			PerchForward = -MagnetPerch.MagneticVector.CrossProduct(BiNormal).GetSafeNormal();
		}

		FRotator PerchRotation = Math::MakeRotFromXZ(PerchForward, MagnetPerch.MagneticVector);
		Player.SmoothSetLocationAndRotation(MagnetPerch.GetPlayerPerchPoint(Player, true), PerchRotation);

		// Save player's constrained forward for later perch rotation updating
		RelativePerchForward = MagnetPerch.WorldTransform.InverseTransformVector(PerchForward);

		// Set ABP state
		AnimationDataComponent.bIsEnteringPerch = true;

		if(MagnetPerch.bAffectCamera)
		{
			// Apply camera settings
			Player.ApplyCameraSettings(CamSettings, 0.5f, this, EHazeCameraPriority::High);
			Player.ApplyIdealDistance(CamSettings.SpringArmSettings.IdealDistance * MagnetActor.PerchCameraDistanceMultiplier, 0.5f, this);
		}

		// Attach to magnet!
		Player.AttachToComponent(MagnetPerch.Owner.RootComponent, AttachmentRule = EAttachmentRule::KeepWorld);

		if(!ActivationParams.IsStale())
		{
			// Play FX
			MagnetActor.PlayPerchEffect();
			Player.PlayCameraShake(CamShake);
			Player.PlayForceFeedback(Rumble, false, true, n"MagnetPerch");
		}

		// Set magnet perch usage
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);
		MagnetPerch.StartUsingPad();

		// Fire perch event
		MagneticPlayerComponent.PlayerMagnet.OnMagnetPerchStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;

		FRotator PerchRotation = FRotator::ZeroRotator;
		float MeshOffsetBlendTime = 0.f;
		UpdatePerching(PerchRotation, MeshOffsetBlendTime);
		UpdateCameraPivotOffset(DeltaTime);

		// Go to perching state if player is done entering
		if(ElapsedTime >= EnterAnimationDuration && !bIsPerching)
			PerchOnMagnet();

		SendAnimationRequest();

		// Update actor location and mesh offset rotation
		Player.SetActorTransform(FTransform(PerchRotation, MagnetPerch.GetPlayerPerchPoint(Player, true)));
		Player.MeshOffsetComponent.OffsetRotationWithTime(PerchRotation, MeshOffsetBlendTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		// Don't deactivate if player hasn't finished entering perch state
		if(!bIsPerching && !MagnetPerch.bIsDisabled)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!MagneticPlayerComponent.MagnetLockonIsActivatedBy(MagneticPlayerComponent))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UMagneticPerchAndBoostComponent CurrentActiveMagnet = Cast<UMagneticPerchAndBoostComponent>(MagneticPlayerComponent.GetActivatedMagnet());
		if(MagneticPlayerComponent.HasEqualPolarity(CurrentActiveMagnet))
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(MagnetPerch.bIsDisabled)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		FRotator Rotation = Math::MakeRotFromXZ(Player.MeshOffsetComponent.ForwardVector, Player.MovementWorldUp);
		if(bIsPerching && MagnetPerch.IsWallPerch() && !MagnetPerch.bIsDisabled)
		{
			SyncParams.AddActionState(n"ShouldJumpOffPerch");

			// Face opposite direction when jumping away from perch
			Rotation = (-MagnetPerch.MagneticVector).Rotation();
		}
		else if(MagnetPerch.IsWallPerch())
		{
			// Fix rotation if we're cancelling a wall perch
			Rotation = MagnetPerch.MagneticVector.Rotation();
		}

		Player.SetActorRotation(Rotation);
		SyncParams.EnableTransformSynchronizationWithTime(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Stahp using magnet perch
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
		MagnetPerch.StopUsingPad();

		// Clear settings and deactivate magnet perch camera
		Player.ClearCameraSettingsByInstigator(this, MagnetPerch.IsWallPerch() ? 2.f : 1.f);
		Player.DeactivateCameraByInstigator(MagnetPerch, MagnetPerch.IsWallPerch() ? 2.f : 1.f);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MagneticPlayerComponent.DeactivateMagnetLockon(MagneticPlayerComponent);

		// Turn off perch effect
		MagnetActor.StopPerchEffect();

		// Set ABP state
		AnimationDataComponent.bIsEnteringPerch = false;
		AnimationDataComponent.bIsPerching = false;

		// Fire perch dettach event
		MagneticPlayerComponent.PlayerMagnet.OnMagnetPerchDone.Broadcast();

		// Snap rotation back to normal if player was perching ceiling
		Player.MeshOffsetComponent.ResetLocationWithTime();
		Player.MeshOffsetComponent.ResetRotationWithTime(AnimationDataComponent.bPerchIsCeiling || MagnetPerch.IsWallPerch() ? 0.f : -1.f);

		// Jump from perch only if player is perching wall magnet
		if(DeactivationParams.GetActionState(n"ShouldJumpOffPerch"))
		{
			Player.SetCapabilityActionState(FMagneticTags::PlayerMagnetLaunchJumpFromPerchState, EHazeActionState::ActiveForOneFrame);
			Player.SetCapabilityAttributeObject(n"MagnetPerch", MagnetPerch);

			// Consume trigger action if player used jump button instead of releasing trigger
			if(WasActionStarted(ActionNames::MovementJump))
				ConsumeAction(ActionNames::PrimaryLevelAbility);
		}
		else
		{
			// Re-enable player interaction with this magnet perch if not jumping away from it
			MagnetPerch.DisabledForObjects.Remove(Owner);

			if(MagnetPerch.IsWallPerch())
				MoveComp.SetVelocity(MagnetPerch.GetMagneticVector() * ActiveMovementSettings.AirControlLerpSpeed * 0.05f);

			// Don't allow ground pound nor en till perching to start as we cancel
			ConsumeAction(ActionNames::MovementGroundPound);
			ConsumeAction(ActionNames::PrimaryLevelAbility);
		}

		MagnetActor = nullptr;
		MagnetPerch = nullptr;
		PreviousPlatformType = EMagnetPlatformType::None;
		ElapsedTime = 0.f;
		bIsPerching = false;
	}

	void UpdatePerching(FRotator& PerchRotation, float& MeshOffsetBlendTime)
	{
		MeshOffsetBlendTime = 0.f;
		EMagnetPlatformType MagnetPlatformType = MagnetPerch.GetCurrentPlatformType();
		switch(MagnetPlatformType)
		{
			case EMagnetPlatformType::Ground:
			{
				AnimationDataComponent.bPerchIsGround = true;
				AnimationDataComponent.bPerchIsCeiling = false;
				MeshOffsetBlendTime = 0.1f;

				// Just take initial forward vector (from when actor started perching)
				PerchRotation = Math::MakeRotFromXZ(MagnetPerch.WorldTransform.TransformVector(RelativePerchForward), MagnetPerch.MagneticVector);

				break;
			}

			case EMagnetPlatformType::Wall:
			{
				AnimationDataComponent.bPerchIsGround = false;
				AnimationDataComponent.bPerchIsCeiling = false;

				// Do basolute rotation if the magnet perch rotated and became wall type
				if(PreviousPlatformType > EMagnetPlatformType::None && PreviousPlatformType != EMagnetPlatformType::Wall)
				{
					PerchRotation = MagnetPerch.GetMagneticVector().Rotation() + FRotator(90.f, 0, 180.f);
					break;
				}

				// Line up player's rotation with platform's inclination
				FVector BiNormal = MagnetPerch.MagneticVector.CrossProduct(Player.MovementWorldUp);
				FVector PerchForward = -MagnetPerch.MagneticVector.CrossProduct(BiNormal).GetSafeNormal();
				PerchRotation = Math::MakeRotFromXZ(PerchForward, MagnetPerch.MagneticVector);

				// Do instant rotation if this was a ceiling perch last frame
				if(PreviousPlatformType != EMagnetPlatformType::Ceiling)
					MeshOffsetBlendTime = 0.1f;

				// Update relative wall forward to be used by 
				RelativePerchForward = RelativeWallPerchForward = MagnetPerch.WorldTransform.InverseTransformVector(PerchForward);

				break;
			}

			case EMagnetPlatformType::Ceiling:
			{
				AnimationDataComponent.bPerchIsGround = false;
				AnimationDataComponent.bPerchIsCeiling = true;

				FVector PerchForward;
				if(RelativeWallPerchForward != FVector::ZeroVector)
					PerchForward = MagnetPerch.WorldTransform.TransformVector(-RelativeWallPerchForward);
				else
					PerchForward = MagnetPerch.WorldTransform.TransformVector(RelativePerchForward);

				PerchRotation = Math::MakeRotFromXZ(PerchForward, Player.MovementWorldUp);
				PerchRotation.Roll = PerchRotation.Pitch = 0.f;
			}
		}

		// Update player's perch state whenever perch type changes
		// fire event while we're at it
		if(MagnetPlatformType != PreviousPlatformType)
		{
			if(PreviousPlatformType != EMagnetPlatformType::None)
				MagneticPlayerComponent.PlayerMagnet.OnMagnetPerchPositionChange.Broadcast();

			PreviousPlatformType = MagnetPlatformType;
		}
	}

	void SendAnimationRequest()
	{
		FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"MagnetAttract";
		Player.RequestLocomotion(AnimationRequest);
	}

	void PerchOnMagnet()
	{
		// Set ABP state
		AnimationDataComponent.bIsEnteringPerch = false;
		AnimationDataComponent.bIsPerching = true;
		bIsPerching = true;

		// Disable interaction with this magnet perch
		MagnetPerch.DisabledForObjects.AddUnique(Owner);
	}

	// Moves pivot offset a bit towards camera location so that it doesn't rotate around whole spring arm
	void UpdateCameraPivotOffset(float DeltaTime)
	{
		if(!MagnetPerch.bAffectCamera)
			return;

		// We want to offset pivot only if player is perching on wall magnet
		FVector PivotOffset = CamSettings.SpringArmSettings.PivotOffset;
		switch(MagnetPerch.CurrentPlatformType)
		{
			case EMagnetPlatformType::Ground:
				PivotOffset.X = 50.f;
				break;

			case EMagnetPlatformType::Wall:
				PivotOffset.X = CamSettings.SpringArmSettings.IdealDistance * 0.4f;
				break;

			case EMagnetPlatformType::Ceiling:
				PivotOffset.X = 30.f;
				break;
		}

		AcceleratedPivotOffset.AccelerateTo(PivotOffset, 1.f, DeltaTime);
		MagnetActor.SpringArmComponent.OverrideSettings.bUsePivotOffset = true;
		MagnetActor.SpringArmComponent.OverrideSettings.PivotOffset = AcceleratedPivotOffset.Value;
	}

	void BlockCapabilities()
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.BlockCapabilities(FMagneticTags::MagneticEffect, this);
	}

	void UnblockCapabilities()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.UnblockCapabilities(FMagneticTags::MagneticEffect, this);
	}
}