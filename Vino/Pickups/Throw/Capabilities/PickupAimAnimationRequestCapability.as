import Vino.Pickups.PickupTags;
import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Pickups.PlayerPickupComponent;

class UPickupAimAnimationRequestCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupAimAnimationRequestCapability);

	default TickGroup = ECapabilityTickGroups::ActionMovement;	

	default CapabilityDebugCategory = PickupTags::PickupSystem;

	AHazePlayerCharacter PlayerOwner;

	UHazeCrumbComponent CrumbComponent;
	UHazeMovementComponent MovementComponent;
	UPlayerPickupComponent PlayerPickupComponent;
	UMovementSettings ActiveMovementSettings;

	FHazeAcceleratedFloat AcceleratedRotationSpeed;
	float MinAimSpacePitch, MaxAimSpacePitch;

	// Constrained aiming stuff
	FVector StartForward;
	float ForwardRotationSpeed;
	bool bIsRotatingToStart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupAimCapability))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerPickupComponent.CurrentPickup == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		if(IsActioning(PickupTags::StartPickupConstrainedAim))
		{
			SyncParams.AddActionState(PickupTags::StartPickupConstrainedAim);
			SyncParams.AddVector(PickupTags::PickupConstrainedAimStartForward, GetAttributeVector(PickupTags::PickupConstrainedAimStartForward));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Setup aimspace clamps
		MinAimSpacePitch = -PlayerPickupComponent.CurrentPickup.AimCameraSpringArmSettings.ClampSettings.ClampPitchDown;
		MaxAimSpacePitch = PlayerPickupComponent.CurrentPickup.AimCameraSpringArmSettings.ClampSettings.ClampPitchUp;

		// Add aim locomotion asset
		PlayerOwner.AddLocomotionAsset(PlayerPickupComponent.CurrentPickupDataAsset.AimStrafeLocomotion, this);

		// This should be set on the player by the pickup actor
		if(IsActioning(PickupTags::StartPickupConstrainedAim))
		{
			// Get forward and calculate time to lerp to it
			bIsRotatingToStart = true;
			StartForward = GetAttributeVector(PickupTags::PickupConstrainedAimStartForward);
			ForwardRotationSpeed = FMath::Sqrt(FMath::RadiansToDegrees(PlayerOwner.ActorForwardVector.AngularDistance(StartForward)) * 2.f);

			// Start focusing camera on start forward vector
			FHazePointOfInterest PointOfInterest;
			PointOfInterest.Blend = 0.5f;
			PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
			PointOfInterest.FocusTarget.WorldOffset = (PlayerOwner.ActorCenterLocation + StartForward * 1000.f + PlayerOwner.MovementWorldUp * 200.f);
			PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

			// Apply camera clamps in relation to the start forward vector
			FHazeCameraClampSettings ClampSettings = PlayerPickupComponent.CurrentPickup.AimCameraSpringArmSettings.ClampSettings;
			ClampSettings.bUseCenterOffset = true;
			ClampSettings.CenterType = EHazeCameraClampsCenterRotation::WorldSpace;
			ClampSettings.CenterOffset = StartForward.Rotation();
			PlayerOwner.ApplyCameraClampSettings(ClampSettings, CameraBlend::Normal(), this, EHazeCameraPriority::Script);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bIsRotatingToStart && MovementComponent.CanCalculateMovement())
		{
			FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(PickupTags::PickupConstrainedAimCapability);
			MoveData.FlagToMoveWithDownImpact();

			if(HasControl())
			{
				MovementComponent.SetTargetFacingDirection(StartForward, ForwardRotationSpeed);
				MoveData.ApplyTargetRotationDelta();

				MovementComponent.Move(MoveData);
				CrumbComponent.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized CrumbData;
				CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
				MoveData.ApplyConsumedCrumbData(CrumbData);

				MovementComponent.Move(MoveData);
			}

			 // Check if player is already facing the desired rotation
        	float TargetDotForward = StartForward.DotProduct(PlayerOwner.ActorForwardVector);
			if(FMath::IsNearlyEqual(TargetDotForward, 1.0f, 0.01f))
			{
				bIsRotatingToStart = false;
				PlayerOwner.ClearPointOfInterestByInstigator(this);
			}
		}
		else
		{
			// Face camera forward
			MovementComponent.SetTargetFacingRotation(PlayerOwner.GetViewRotation(), ActiveMovementSettings.GroundRotationSpeed);

			// Update aimspace pitch
			float AimSpacePitch = ConvertToAimSpace(PlayerOwner.GetViewRotation().Pitch);
			PlayerOwner.SetAnimFloatParam(n"AimPitch", AimSpacePitch);

			// Update standing rotation aimspace 
			float NormalRotationSpeed = (MovementComponent.RotationDelta / DeltaTime) / MovementComponent.RotationSpeed;
			float RotationDelta = Math::NormalizedDeltaRotator(PlayerOwner.ActorRotation, MovementComponent.PreviousOwnerRotation.Rotator()).Yaw;
			NormalRotationSpeed *= FMath::Sign(RotationDelta);
			NormalRotationSpeed = FMath::Clamp(NormalRotationSpeed, -0.5f, 0.5f) * 100.f;
			PlayerOwner.SetAnimFloatParam(n"AimRotationSpeed", AcceleratedRotationSpeed.AccelerateTo(NormalRotationSpeed, 0.5f, DeltaTime));

			// Request animation
			if(PlayerOwner.Mesh.CanRequestLocomotion())
			{
				FHazeRequestLocomotionData AnimationRequest;
				AnimationRequest.AnimationTag = n"PickUpSmallStrafe";
				AnimationRequest.WantedVelocity = MovementComponent.Velocity;
				AnimationRequest.WantedWorldTargetDirection = MovementComponent.Velocity;
				PlayerOwner.RequestLocomotion(AnimationRequest);
			}

			// Update throw force blend space
			float ChargeProgress = 0.f;
			ConsumeAttribute(n"NormalThrowCharge", ChargeProgress);
			PlayerOwner.SetAnimFloatParam(n"NormalThrowCharge", ChargeProgress);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupAimCapability))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.ClearLocomotionAssetByInstigator(this);
		PlayerOwner.ClearCameraClampSettingsByInstigator(this);
	}

	float ConvertToAimSpace(float Value)
	{
		float AbsMin = FMath::Abs(MinAimSpacePitch);
		float AdjustedMax = MaxAimSpacePitch + AbsMin;

		return ((Value + AbsMin) / AdjustedMax) * 100.f;
	}
}