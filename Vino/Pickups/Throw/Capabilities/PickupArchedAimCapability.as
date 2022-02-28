import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Pickups.PlayerPickupComponent;

import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// Since this capability relies on raw controller input (not camera movement), this information
// needs to be relayed to the remote somehow. A periodic message is sent to remote, this
// information will then be lerped to smoothen aiming
class UPickupArchedAimCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
    default CapabilityTags.Add(PickupTags::PickupArchedAimCapability);

    default TickGroup = ECapabilityTickGroups::BeforeGamePlay;

	AHazePlayerCharacter PlayerOwner;
    UPlayerPickupComponent PickupComponent;
	UPickupThrowComponent ThrowComponent;
    UHazeMovementComponent MovementComponent;
	UCameraUserComponent CameraUserComponent;

	UMovementSettings ActiveMovementSettings;
	UAimOffsetBlendSpace AimSpace;

	UCurveFloat PitchAccelerationCurve;
	UCurveFloat YawAccelerationCurve;

	FVector LastTrackedImpactPoint;
	FVector HighestPathPoint;

	// Used for networking purposes
	FVector PitchVector;

	// Rotation used for aiming, network-synched
	FQuat CurrentRotation;

	const float VerticalAimSpeed = 60.f;
	const float HorizontalAimSpeed = 70.f;
	const float MaxPitch = 60.f;
	const float MinPitch = -20.f;

	// Camera stuff
	const float CameraBlendEnterTime = 0.5f;
	const float CameraBlendExitTime = 1.0f;

	// Movement
	const float MovementSpeedMultiplier = 0.5f;

	// Network - control side
	const float NetSynchPeriod = 0.1f;
	float NetTimeToNextSynch;

	// Nerwork - remote side: stuff for aiming synch-lerping
	private FQuat RemoteLerpStart;
	private FQuat RemoteLerpTarget;
	private FQuat RemoteRotation;
	private float RemoteLerpAlpha = 1.0f;
	private float RemoteLerpSpeed = NetSynchPeriod * 100.f;

	bool bCurrentPathIsValid;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        PickupComponent = UPlayerPickupComponent::Get(Owner);
		ThrowComponent = UPickupThrowComponent::GetOrCreate(Owner);
        MovementComponent = UHazeMovementComponent::Get(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
		CameraUserComponent = UCameraUserComponent::Get(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		return EHazeNetworkActivation::DontActivate;

		// if(!WasActionStarted(ActionNames::WeaponAim))
        //     return EHazeNetworkActivation::DontActivate;

		// if(!PickupComponent.IsHoldingThrowableObject())
		// 	return EHazeNetworkActivation::DontActivate;

		// if(!MovementComponent.IsGrounded())
		// 	return EHazeNetworkActivation::DontActivate;

		// if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Dash))
		// 	return EHazeNetworkActivation::DontActivate;

		// if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
		// 	return EHazeNetworkActivation::DontActivate;

        // return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams SyncParams)
	{
		NetTimeToNextSynch = NetSynchPeriod;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		BlockCapabilities();

		// Start aiming at camera's forward vector
		CurrentRotation = PlayerOwner.CurrentlyUsedCamera.GetWorldRotation().Quaternion();
		RemoteSetLerpTarget(CurrentRotation);

		// Set up aim pickupable camera
		UHazeCameraSpringArmSettingsDataAsset SprimgArmSettings = Cast<APickupActor>(PickupComponent.CurrentPickup).AimCameraSpringArmSettings;
		PlayerOwner.ApplyCameraSettings(SprimgArmSettings, FHazeCameraBlendSettings(CameraBlendEnterTime), this, EHazeCameraPriority::Script);
		PitchAccelerationCurve = SprimgArmSettings.CameraSettings.InputAccelerationCurvePitch;
		YawAccelerationCurve = SprimgArmSettings.CameraSettings.InputAccelerationCurveYaw;

		// Set locomotion asset
		PlayerOwner.AddLocomotionAsset(PickupComponent.CurrentPickupDataAsset.AimStrafeLocomotion, PickupComponent);

		// Set aim space
		AimSpace = PickupComponent.CurrentPickupDataAsset.AimSpace;
		PlayerOwner.PlayAimSpace(AimSpace);
		SetAimSpacePitch();

		// Snap pickupable to LeftAttach socket
		PickupComponent.CurrentPickup.AttachToComponent(PlayerOwner.Mesh, n"LeftAttach");

		// Reduce walking speed by 50% when aiming
		UMovementSettings::SetMoveSpeed(Owner, ActiveMovementSettings.MoveSpeed * MovementSpeedMultiplier, Instigator = this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Face camera
		MovementComponent.SetTargetFacingRotation(PlayerOwner.GetViewRotation(), ActiveMovementSettings.GroundRotationSpeed);

		if(HasControl())
		{
			// Synch 'CurrentPitch' every x seconds
			NetTimeToNextSynch -= DeltaTime;
			if(NetTimeToNextSynch <= 0)
			{
				NetTimeToNextSynch = NetSynchPeriod;
				NetSetCurrentRotation(CurrentRotation);
			}
		}
		else
		{
			// Step remote pitch lerping
			if(RemoteLerpAlpha < 1.f)
			{
				RemoteLerpAlpha += DeltaTime * RemoteLerpSpeed;
				RemoteRotation = FQuat::FastLerp(RemoteLerpStart, RemoteLerpTarget, RemoteLerpAlpha);
			}
		}

		SetAimSpacePitch();

		// Calculate projectile path
		PitchVector = CalculatePitchVector();
		CalculateThrowPath();

		// Update camera to focus on landing spot
		UpdateCamera(GetUndilatedDeltaTime());
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if((IsActioning(ActionNames::WeaponFire) && bCurrentPathIsValid)  ||
		   !IsActioning(ActionNames::WeaponAim) && HasControl()  		  || 
		   !MovementComponent.IsGrounded()         						  ||
		    WasActionStarted(ActionNames::Cancel)  						  ||
	        PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Dash))
		{
			return HasControl() ? EHazeNetworkDeactivation::DeactivateUsingCrumb : EHazeNetworkDeactivation::DontDeactivate;
		}

        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		// Gotta synchronize pitch vector!
		PitchVector = CalculatePitchVector();
		OutParams.AddVector(n"PitchVector", PitchVector);

		// Notify of deactivation by throw
		if(IsActioning(ActionNames::WeaponFire))
			OutParams.AddActionState(n"DeactivationByThrow");
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		PlayerOwner.ClearSettingsByInstigator(Instigator = this);
		PlayerOwner.ClearCameraSettingsByInstigator(this, CameraBlendExitTime);

		float BlendTime = 0.2f;
		PlayerOwner.StopAimSpace(AimSpace, BlendTime);

		// Set impact point attribute in case we deactivated by throw;
		// this will be used by ThrowPickupableCapability to calculate throw path
		if(DeactivationParams.GetActionState(n"DeactivationByThrow"))
		{
			PlayerOwner.SetCapabilityAttributeVector(n"AimPickupableImpactPoint", LastTrackedImpactPoint);
			PlayerOwner.SetCapabilityAttributeVector(n"AimPickupableHighestPathPoint", HighestPathPoint);
		}
		else
		{
			// Fall back to normal pickup locomotion
			PlayerOwner.AddLocomotionAsset(PickupComponent.CurrentPickupDataAsset.CarryLocomotion, this);

			// We still need to snap pickupable back to the original align bone,
			// wait until blending has stopped to do so
			System::SetTimer(this, n"OnAimSpaceBlendStopped", BlendTime, false);
		}

		UnblockCapabilities();
		bCurrentPathIsValid = false;
    }

	UFUNCTION(NotBlueprintCallable)
	void OnAimSpaceBlendStopped()
	{
		// Snap pickupable actor back to align bone
		if(!IsActive() && PickupComponent.CurrentPickup != nullptr)
		{
			APickupActor PickupActor = Cast<APickupActor>(PickupComponent.CurrentPickup);
			PickupActor.RootComponent.AttachToComponent(PlayerOwner.Mesh, PickupActor.AttachmentBoneName);
		}
	}

	void UpdateCamera(float DeltaTime)
	{
		// Get delta between camera forward and pitchvector
		FVector PlayerToCollision = (LastTrackedImpactPoint - PlayerOwner.GetActorLocation()).GetSafeNormal();
		FRotator DeltaRotation = CameraUserComponent.WorldToLocalRotation(PlayerToCollision.Rotation() - CameraUserComponent.GetCurrentCamera().GetWorldRotation());

		// Add a couple of arbitrary multipliers to speed up camera rotation
		DeltaRotation.Yaw *= 3.f * DeltaTime;
		DeltaRotation.Pitch *= 2.f * DeltaTime;

		CameraUserComponent.AddDesiredRotation(DeltaRotation);
	}

	void CalculateThrowPath()
	{
		if(PickupComponent.CurrentPickup == nullptr)
			return;

		APickupActor PickupActor = Cast<APickupActor>(PickupComponent.CurrentPickup);

		// Calculate and update throw path in component
		// Eman TODO: Using debug function to draw aim curve; fix proper FX!
		FPredictProjectilePathResult ThrowPath;
		bCurrentPathIsValid = ThrowComponent.CalculateThrowPath(PickupActor, PickupActor.GetActorLocation(), PitchVector * PickupActor.BaseThrowForce, PickupActor.MeshMass, ThrowPath, DebugDrawType = EDrawDebugTrace::ForOneFrame);
		LastTrackedImpactPoint = ThrowPath.HitResult.ImpactPoint;

		// Report path validity; ThrowPickupableCapability uses this to activate!
		if(!bCurrentPathIsValid)
			PlayerOwner.SetCapabilityActionState(n"PickupAimPathIsNotValid", EHazeActionState::ActiveForOneFrame);

		// Get highest point in path; this will be used by ThrowPickupableCapability
		HighestPathPoint = PickupComponent.CurrentPickup.GetActorLocation();
		for(auto PathPoint : ThrowPath.PathData)
		{
			if(PathPoint.Location.Z > HighestPathPoint.Z)
				HighestPathPoint = PathPoint.Location;
			else if(PathPoint.Location.Z < HighestPathPoint.Z)
				break;
		}
	}

	FVector CalculatePitchVector()
	{
		const float DeltaTime = GetUndilatedDeltaTime();

		// Control side: Get current input
		FVector2D StickInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);

		float Pitch = GetLocalNetRotation().Rotator().Pitch;
		float Yaw = GetLocalNetRotation().Rotator().Yaw;

		Pitch += StickInput.Y * DeltaTime * VerticalAimSpeed;
		Pitch = FMath::Clamp(Pitch, MinPitch, MaxPitch);

		Yaw += StickInput.X * DeltaTime * HorizontalAimSpeed;

		CurrentRotation = FQuat(FRotator(Pitch, Yaw, 0));
		return GetLocalNetRotation().ForwardVector;
	}

	void SetAimSpacePitch()
	{
		PlayerOwner.SetAimSpaceValues(AimSpace, 0.f, ConvertToAimSpace(GetLocalNetRotation().Rotator().Pitch));
	}

	float ConvertToAimSpace(float Value)
	{
		float AbsMin = FMath::Abs(MinPitch);
		float AdjustedMax = MaxPitch + AbsMin;

		return ((Value + AbsMin) / AdjustedMax) * 100.f;
	}

	FQuat GetLocalNetRotation()
	{
		if(HasControl())
			return CurrentRotation;
		else
			return RemoteRotation;
	}

	float GetUndilatedDeltaTime()
	{
		const float TimeDilation = Owner.GetActorTimeDilation();
		return TimeDilation > 0.f ? PlayerOwner.GetActorDeltaSeconds() / TimeDilation : PlayerOwner.GetActorDeltaSeconds();
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSetCurrentRotation(FQuat NetRotation)
	{
		if(!HasControl())
			RemoteSetLerpTarget(NetRotation);
	}

	void RemoteSetLerpTarget(FQuat NetLerpTarget)
	{
		RemoteLerpStart = RemoteLerpTarget;
		RemoteLerpTarget = NetLerpTarget;
		RemoteLerpAlpha = 0.f;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		PlayerOwner.BlockCapabilities(CameraTags::Control, this);
		PlayerOwner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		PlayerOwner.BlockCapabilities(CameraTags::NonControlled, this);
	}
	
	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		PlayerOwner.UnblockCapabilities(CameraTags::Control, this);
		PlayerOwner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		PlayerOwner.UnblockCapabilities(CameraTags::NonControlled, this);
	}
}