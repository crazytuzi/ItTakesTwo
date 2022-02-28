import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Pickups.Throw.PickupAimCrosshairWidget;
import Vino.Trajectory.TrajectoryDrawer;

class UPickupAimCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupAimCapability);

	default TickGroup = ECapabilityTickGroups::LastDemotable;

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	UTrajectoryDrawer TrajectoryDrawer;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PickupComponent;
	UPickupThrowComponent ThrowComponent;
	UHazeMovementComponent MovementComponent;

	UMovementSettings ActiveMovementSettings;

	UPickupAimCrosshairWidget CrosshairWidget;

	USceneComponent PreviousAttachParent;
	FName PreviousAttachSocket;
	FTransform PreviousAttachRelativeTransform;

	UHazeSmoothSyncFloatComponent ThrowForceMagnitude;

	APickupActor PickupActor = nullptr;

	FVector AimTarget;

	float MinThrowForce;
	float MaxThrowForce;

	const float ChargeRumbleCap = 0.2f;

	float MinFov;
	float MaxFov;

	const float MaxDrawDistance = 500;
	const float DrawDistanceThreshold = 50.f;

	float ElapsedChargeTime;

	float AimTrajectoryPeak;

	bool bIsChargingThrow;
	bool bObjectWasPutdown;
	bool bCanBeThrown;
	bool bAutomatedAim;

	bool bDrawAimTrajectory;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ThrowComponent = UPickupThrowComponent::Get(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
		ThrowForceMagnitude = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"ThrowForceMagnitude");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PickupComponent.CurrentPickup == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if player threw the previous frame
		if(IsActioning(n"ThrowPickup"))
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComponent.CurrentPickup.bStartAimingWhenPickedUp)
		{
			if(!IsActioning(ActionNames::WeaponAim))
				return EHazeNetworkActivation::DontActivate;
		}

		if(!PickupComponent.IsHoldingThrowableObject())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability))
			return EHazeNetworkActivation::DontActivate;

		if(!MovementComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			return EHazeNetworkActivation::DontActivate;

		if(PickupComponent.IsPickingUpObject())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddObject(n"PickupActor", PickupComponent.CurrentPickup);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementAction, this);

		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::WeaponFire);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		PickupActor = Cast<APickupActor>(ActivationParams.GetObject(n"PickupActor"));
		bAutomatedAim = PickupActor.bStartAimingWhenPickedUp;

		// Create crosshair and display aiming mesh
		if(bDrawAimTrajectory = PickupActor.bDrawAimTrajectory)
			CrosshairWidget = Cast<UPickupAimCrosshairWidget>(PlayerOwner.AddWidget(PickupComponent.CurrentPickupDataAsset.AimCrosshairWidgetClass));

		// Save previous attach information
		PreviousAttachParent = PickupActor.RootComponent.AttachParent;
		PreviousAttachSocket = PickupActor.RootComponent.AttachSocketName;
		PreviousAttachRelativeTransform = PickupActor.RootComponent.RelativeTransform;

		// Attach to aim bone (because ofc it's a different one...)
		PickupActor.AttachToComponent(PlayerOwner.Mesh, n"LeftAttach");
		PickupActor.RootComponent.SetRelativeTransform(PreviousAttachRelativeTransform);

		// Apply camera settings
		PlayerOwner.ApplyCameraSettings(PickupActor.AimCameraSpringArmSettings, 0.5f, this, EHazeCameraPriority::High);

		// Reduce walking speed by 50% when aiming
		UMovementSettings::SetMoveSpeed(Owner, ActiveMovementSettings.MoveSpeed * 0.5f, Instigator = this);

		// Setup trajectory component reference
		TrajectoryDrawer = PickupActor.TrajectoryDrawer;
		TrajectoryDrawer.SetComponentTickEnabled(true);

		// Start with lower force
		MinThrowForce = PickupActor.BaseThrowForce;
		ThrowForceMagnitude.SetValue(MinThrowForce);
		MaxThrowForce = PickupActor.MaxChargedThrowForce;

		// Setup fov lerp values
		MaxFov = PickupActor.AimCameraSpringArmSettings.CameraSettings.FOV;
		MinFov = MaxFov - 8.f;

		// Initialize flags
		bObjectWasPutdown = false;

		// Bind putdown event
		PickupComponent.OnPutDownEvent.AddUFunction(this, n"OnPutdown");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Sometimes this reference can be wiped on remote side before we've deactivated
		if(PickupActor == nullptr)
			return;

		// Build up force
		if(IsActioning(ActionNames::WeaponFire))
		{
			bIsChargingThrow = true;
			ElapsedChargeTime += DeltaTime * GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis);

			float ChargeProgress = Math::Saturate(ElapsedChargeTime / PickupActor.ChargeDuration);
			float CurvedChargeProgress = PickupComponent.CurrentPickupDataAsset.AimChargeCurve.GetFloatValueNormalized(ChargeProgress);

			// Update throw force
			ThrowForceMagnitude.SetValue(FMath::Lerp(MinThrowForce, MaxThrowForce, ChargeProgress));

			// Apply force feedback
			float ChargeRumble = CurvedChargeProgress * ChargeRumbleCap;
			PlayerOwner.SetFrameForceFeedback(ChargeRumble, ChargeRumble);

			// Aply fov change
			float Fov = FMath::Lerp(MaxFov, MinFov, CurvedChargeProgress);
			PlayerOwner.ApplyFieldOfView(Fov, 0.5f, this);

			// Set blackboard value for PickupAimAnimationRequestCapability to use next frame
			PlayerOwner.SetCapabilityAttributeValue(n"NormalThrowCharge", ChargeProgress);
		}
		// Clear charge stuff if throw trigger was released but couldn't throw
		else if(WasActionStopped(ActionNames::WeaponFire) && !bCanBeThrown)
		{
			bIsChargingThrow = false;
			ElapsedChargeTime = 0.f;
			ThrowForceMagnitude.SetValue(MinThrowForce);
			PlayerOwner.ClearFieldOfViewByInstigator(this);
		}

		// Calculate throw vector and get trajectory
		FPredictProjectilePathResult ThrowPath;
		FVector AimVector = ((PlayerOwner.ViewLocation + PlayerOwner.ViewRotation.ForwardVector * MaxThrowForce * 0.3f) - PickupActor.ActorLocation).GetSafeNormal();
		FVector ThrowVector = (AimVector * ThrowForceMagnitude.Value).RotateAngleAxis(-2.f, PlayerOwner.ViewRotation.RightVector);

		// Start trajectory from throw animation's bone location instead of pickup origin
		FTransform BoneTransform;
		Animation::GetAnimAlignBoneTransform(BoneTransform, PickupComponent.CurrentPickupDataAsset.ThrowAnimation, 0.0f);
		FVector AimStartLocation = PlayerOwner.ActorTransform.TransformPosition(BoneTransform.Location); // Formerly: PickupComponent.CurrentPickup.ActorLocation

		// Calculate throw path and store its peak in case player is about to throw
		bCanBeThrown = ThrowComponent.CalculateThrowPath(PickupActor, AimStartLocation, ThrowVector, 1.f, ThrowPath, DebugDrawType = EDrawDebugTrace::None);
		AimTarget = ThrowPath.LastTraceDestination.Location;
		AimTrajectoryPeak = GetTrajectoryPeak(ThrowPath);

		if(bDrawAimTrajectory)
		{
			UpdateCrosshairWidget(ThrowPath.HitResult.Location);

			float TrajectoryLength = ThrowPath.HitResult.Location.Distance(AimStartLocation);
			TrajectoryDrawer.DrawTrajectory(AimStartLocation, TrajectoryLength, ThrowVector, PlayerOwner.MovementComponent.GravityMagnitude, 7.f, FLinearColor::White, PlayerOwner, TrajectoryLength * 0.01f, bTrajectoryIsValid = bCanBeThrown);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(PickupActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bObjectWasPutdown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!bAutomatedAim)
		{
			if(!IsActioning(ActionNames::WeaponAim))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(!PickupActor.bHoldToChargeThrow)
		{
			if(IsActioning(ActionNames::WeaponFire))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(!IsActioning(ActionNames::WeaponFire) && bIsChargingThrow && bCanBeThrown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		// Don't throw if path was invalid (too short)
		if(!bCanBeThrown)
			return;

		// Don't throw if aiming was cancelled
		if(WasActionStarted(ActionNames::Cancel))
			return;

		if(!bAutomatedAim)
		{
			if(!IsActioning(ActionNames::WeaponAim))
				return;
		}

		if(bObjectWasPutdown)
			return;

		SyncParams.AddActionState(n"CastThatShit!");
		SyncParams.AddVector(n"AimTarget", AimTarget);
		SyncParams.AddValue(n"AimTrajectoryPeak", AimTrajectoryPeak);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementAction, this);

		// PickupComponent's currentPickup will be null if the system
		// is being reset; e.g. we're loading a checkpoint
		if(PickupActor != nullptr)
		{
			// Check if pickup was thrown
			if(DeactivationParams.GetActionState(n"CastThatShit!"))
			{
				PlayerOwner.SetCapabilityActionState(n"ThrowPickup", EHazeActionState::ActiveForOneFrame);
				PlayerOwner.SetCapabilityAttributeVector(n"AimTarget", DeactivationParams.GetVector(n"AimTarget"));
				PlayerOwner.SetCapabilityAttributeValue(n"AimTrajectoryPeak", DeactivationParams.GetValue(n"AimTrajectoryPeak"));
			}
			// Reattach pickup actor to player if pickup wasn't thrown
			else if(!bObjectWasPutdown && !WasActionStarted(ActionNames::Cancel))
			{
				// Reattach to normal pickup component
				PickupActor.RootComponent.AttachToComponent(PreviousAttachParent, PreviousAttachSocket);
				PickupActor.RootComponent.SetRelativeTransform(PreviousAttachRelativeTransform);
			}
		}

		// Kill crosshair
		PlayerOwner.RemoveWidget(CrosshairWidget);
		CrosshairWidget = nullptr;

		// Clear shit
		PlayerOwner.ClearFieldOfViewByInstigator(this, 0.5f);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearSettingsByInstigator(this);

		// Restore normal movement speed
		UMovementSettings::ClearMoveSpeed(Owner, Instigator = this);

		// Clear trajectory drawer
		if(TrajectoryDrawer != nullptr)
		{
			TrajectoryDrawer.SetComponentTickEnabled(false);
			TrajectoryDrawer.Tick(0.f); // Poopy hack to proper clear component
		}

		// Clean up poopies
		PickupActor = nullptr;
		TrajectoryDrawer = nullptr;
		ElapsedChargeTime = 0.f;
		bIsChargingThrow = false;
		bDrawAimTrajectory = false;
		bAutomatedAim = false;
	}

	// Optimize this'n
	float GetTrajectoryPeak(const FPredictProjectilePathResult& ThrowPath)
	{
		float Peak = PickupActor.ActorLocation.Z;
		for(auto PathPoint : ThrowPath.PathData)
		{
			if(PathPoint.Location.Z > Peak)
				Peak = PathPoint.Location.Z;
			else
				break;
		}

		return FMath::Abs(Peak - PickupActor.ActorLocation.Z);
	}

	void UpdateCrosshairWidget(FVector AimLocation)
	{
		CrosshairWidget.AimLocation = AimLocation;
		CrosshairWidget.CircleRadius = 20.f;

		float CrosshairAlpha = 1.f;
		CrosshairWidget.LineColor = FLinearColor(1.f, 1.f, 1.f, CrosshairAlpha);
		CrosshairWidget.LineThicknessMultiplier = 0.2f;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPutdown(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		bObjectWasPutdown = true;
	}
}