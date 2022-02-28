import Rice.Math.MathStatics;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraLazyChaseSettings;

class UIceSkatingChaseCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent CameraComp;
	UCameraUserComponent CameraUser;
	UHazeMovementComponent MoveComp;

	FVector PreviousVelocity;
	FHazeAcceleratedFloat ChaseSpeed;
	FHazeAcceleratedFloat CamOffset;

	FHazeAcceleratedFloat UphillZoomFraction;
	FVector DesiredGroundNormal = FVector::UpVector;

	FVector LastDesiredNormal;
	FIceSkatingCameraSettings Settings;
	UCameraLazyChaseSettings ChaseSettings;

	float InputPauseTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		CameraComp = UIceSkatingCameraComponent::GetOrCreate(Player);

		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);

		ChaseSettings = UCameraLazyChaseSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

        if (Player.IsAnyCapabilityActive(GrindingCapabilityTags::Camera))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

        if (Player.IsAnyCapabilityActive(GrindingCapabilityTags::Camera))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);

		ChaseSpeed.SnapTo(0.f, 0.f);
		CamOffset.SnapTo(0.f, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateInputPausing(DeltaTime);

		FQuat DesiredRotation = CameraUser.DesiredRotation.Quaternion();

		// If we're grounded, update the desired normal. If we're airborne we want to keep it as is!
		if (MoveComp.IsGrounded())
			LastDesiredNormal = MoveComp.DownHit.Normal;

		// Scale the camera speed based on speed!
		float Speed = MoveComp.Velocity.Size();
		float CameraSpeedScale = Math::GetPercentageBetweenClamped(Settings.ChaseSpeedMin, Settings.ChaseSpeedMax, Speed);

		// We want the ground-normal to always be forward-aligned, and not pointing to the side of the camera
		LastDesiredNormal = LastDesiredNormal.ConstrainToPlane(DesiredRotation.RightVector);
		LastDesiredNormal.Normalize();

		// Also we dont want normals that point outward when going uphill, flatten them!
		// (we check if the normal points 180deg away from our horizontal velocity)
		if (LastDesiredNormal.DotProduct(MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp)) < 0.f)
			LastDesiredNormal = MoveComp.WorldUp;

		// Get if we're moving up-slope
		FVector SlopeDownwards = SkateComp.GetSlopeDownwards();
		float UphillCoefficient = Math::Saturate(-SlopeDownwards.DotProduct(MoveComp.Velocity));

		// Split current rotation into horizontal/vertical
		FQuat HorizontalCurrent;
		FQuat VerticalCurrent;
		DesiredRotation.ToSwingTwist(LastDesiredNormal, VerticalCurrent, HorizontalCurrent);

		// Calculate target rotation
		FVector TargetForward = MoveComp.Velocity;

		// If we're moving upwards from the groundnormal, constrain it (we dont want to look upwards when jumping). Downwards is fine though.
		if (TargetForward.DotProduct(LastDesiredNormal) > 0.f)
			TargetForward = Math::ConstrainVectorToSlope(TargetForward, LastDesiredNormal, MoveComp.WorldUp);

		TargetForward.Normalize();

		UphillZoomFraction.AccelerateTo(UphillCoefficient, Settings.UphillZoomAccelerateDuration, DeltaTime);

		// Add a little bit of pitch downwards...
		FQuat TargetRotation = Math::MakeQuatFromX(TargetForward);
		TargetRotation = TargetRotation * FQuat(FVector::RightVector, FMath::DegreesToRadians(Settings.BaseExtraPitch));

		// Split target rotation into horizontal and vertical based on the ground normal
		FQuat HorizontalTarget;
		FQuat VerticalTarget;
		TargetRotation.ToSwingTwist(LastDesiredNormal, VerticalTarget, HorizontalTarget);

		// Update chase speed based on how far off from the current forward is
		float TargetAngleDot = HorizontalCurrent.ForwardVector.DotProduct(HorizontalTarget.ForwardVector);
		// Make it less relevant towards 0 :) So you have a bit of wiggle-room if you turn back-and-forth
		TargetAngleDot = FMath::Pow(TargetAngleDot, 4.f);

		float TargetAngleDelta = Math::DotToDegrees(TargetAngleDot);
		if (InputPauseTimer < 0.f)
			ChaseSpeed.AccelerateTo((TargetAngleDelta / 90.f) * Settings.ChaseSpeed * CameraSpeedScale, Settings.ChaseSpeedAccelerateDuration, DeltaTime);
		else
			ChaseSpeed.AccelerateTo(0.f, Settings.ChaseSpeedAccelerateDuration, DeltaTime);

		// Offset the camera based on how much we're turning!
		if (InputPauseTimer < 0.f)
			CamOffset.AccelerateTo(CalculateTurnFactor(MoveComp.Velocity, PreviousVelocity, DeltaTime) * CameraSpeedScale, 2.4f, DeltaTime);
		else
			CamOffset.AccelerateTo(0.f, 2.4f, DeltaTime);

		Player.ApplyCameraOffset(FVector(0.f, CamOffset.Value * Settings.TurnOffsetAmount, 0.f), FHazeCameraBlendSettings(2.f), this);

		// Lerp both individually
		HorizontalCurrent = FQuat::Slerp(HorizontalCurrent, HorizontalTarget, ChaseSpeed.Value * DeltaTime);
		VerticalCurrent = FQuat::Slerp(VerticalCurrent, VerticalTarget, Settings.VerticalChaseSpeed * CameraSpeedScale * DeltaTime);

		if (InputPauseTimer < 0.f && HasControl())
		{
			DesiredRotation = VerticalCurrent * HorizontalCurrent;
			CameraUser.DesiredRotation = DesiredRotation.Rotator();
		}

		PreviousVelocity = MoveComp.Velocity;

		// Zoom out the camera if we're going uphill (additive yo)
		FHazeCameraSpringArmSettings UphillZoomSettings;
		UphillZoomSettings.bUseIdealDistance = true;
		UphillZoomSettings.IdealDistance = Settings.UphillZoomDistance * UphillZoomFraction.Value;
		UphillZoomSettings.bUsePivotOffset = true;
		UphillZoomSettings.PivotOffset = MoveComp.WorldUp * Settings.UphillZoomPivotOffset * UphillZoomFraction.Value;

		FHazeCameraBlendSettings Blend = CameraBlend::Additive(0.5f);
		Player.ApplyCameraSpringArmSettings(UphillZoomSettings, Blend, this);

		if (IsDebugActive())
		{
			FQuat CircleQuat = Math::MakeQuatFromZ(LastDesiredNormal);
			System::DrawDebugCircle(Player.ActorLocation, 100.f, 32, FLinearColor::Blue, 0.f, 10.f, CircleQuat.RightVector, CircleQuat.ForwardVector);
			System::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + TargetForward * 200.f, FLinearColor::Blue, 0.f, 10.f);
		}
	}

	FHitResult QueryPredictedForwardGround()
	{
		FVector ForwardOffset = Player.ActorForwardVector * MoveComp.Velocity.Size() * 0.4f;
		FVector TraceUpOffset = MoveComp.WorldUp * 200.f;
		FVector TraceDownOffset = MoveComp.WorldUp * -3800.f;

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		Trace.From = Player.ActorLocation + ForwardOffset + TraceUpOffset;
		Trace.To = Player.ActorLocation + ForwardOffset + TraceDownOffset;

		FHazeHitResult Hit;
		Trace.Trace(Hit);

		if (Hit.FHitResult.bBlockingHit && IsDebugActive())
		{
			System::DrawDebugLine(Trace.From, Hit.FHitResult.Location, FLinearColor::Blue);
			System::DrawDebugPoint(Hit.FHitResult.Location, 32, FLinearColor::Red);
			System::DrawDebugLine(Hit.FHitResult.Location, Hit.FHitResult.Location + Hit.FHitResult.Normal * 500.f, FLinearColor::Red);
		}

		return Hit.FHitResult;
	}

	void UpdateInputPausing(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (!AxisInput.IsNearlyZero())
			InputPauseTimer = ChaseSettings.CameraInputDelay;

		InputPauseTimer -= DeltaTime;
	}

	float CalculateTurnFactor(FVector From, FVector To, float DeltaTime)
	{
		return SkateComp.GetScaledPlayerInput_VelocityRelative().Y;
	}
}