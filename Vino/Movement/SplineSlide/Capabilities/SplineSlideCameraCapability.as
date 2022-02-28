import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Camera.Settings.CameraLazyChaseSettings;

class USplineSlideCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);

	default CapabilityDebugCategory = n"Camera";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USplineSlideComponent SplineSlideComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

	float DistanceAlongSpline;
	FVector SplineForward;
	FVector SplineRight;
	FVector SplineUp;

	FAcceleratedCameraDesiredRotation AcceleratedCameraDesiredRotation;

	default AcceleratedCameraDesiredRotation.CooldownPostInput = 0;
	default AcceleratedCameraDesiredRotation.AcceleratedRotationDuration = 0.5;

	UCameraLazyChaseSettings Settings;
	FHazeAcceleratedRotator AcceleratedDesiredRotation;
	FVector DefaultPivotOffset;

	FHazeAcceleratedFloat DesiredAccelerationDuration;
	float ValidJumpDestinationTime = 0.f;

	ASplineSlideSpline PreviousSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		Settings = UCameraLazyChaseSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!CameraUser.HasControl() && !Player.CameraSyncronizationIsBlocked())
			return EHazeNetworkActivation::DontActivate;

		if (!Player.IsAnyCapabilityActive(SplineSlideTags::Movement))
        	return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (!SplineSlideComp.ActiveSplineSlideSpline.bActivateCamera)
        	return EHazeNetworkActivation::DontActivate;

		if (!SplineSlideComp.IsWithinSplineBounds(SplineSlideComp.ActiveSplineSlideSpline, true))
        	return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!CameraUser.HasControl() && !Player.CameraSyncronizationIsBlocked())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Player.IsAnyCapabilityActive(SplineSlideTags::Jump))
		{
			if (Time::RealTimeSeconds > ValidJumpDestinationTime + 0.5f)
				return EHazeNetworkDeactivation::DontDeactivate;
		}
		else 
		{
			if (!Player.IsAnyCapabilityActive(SplineSlideTags::Movement))
 	        	return EHazeNetworkDeactivation::DeactivateLocal;

			if (!SplineSlideComp.IsWithinSplineBounds(SplineSlideComp.ActiveSplineSlideSpline, false))
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraUser.RegisterDesiredRotationReplication(this);
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Player.ApplyCameraSettings(SplineSlideComp.CameraSettings, FHazeCameraBlendSettings(1.f), SplineSlideComp, EHazeCameraPriority::High);
		AcceleratedCameraDesiredRotation.Reset(CameraComp.WorldRotation);
		ValidJumpDestinationTime = Time::RealTimeSeconds;
		DesiredAccelerationDuration.SnapTo(0.5f);
		ChangeSpline(SplineSlideComp.ActiveSplineSlideSpline);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraUser.UnregisterDesiredRotationReplication(this);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Player.ClearCameraSettingsByInstigator(SplineSlideComp);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		SplineForward = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		SplineRight = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();

		UpdateCameraClamps();
		UpdateDesiredRotation(DeltaTime);

		// When jumping we need to check that we have a possible landing spline.
		// If not jumping we always count as having one.
		if (!Player.IsAnyCapabilityActive(SplineSlideTags::Jump) || (SplineSlideComp.JumpDestination != nullptr))
			ValidJumpDestinationTime = Time::RealTimeSeconds;

		if (SplineSlideComp.ActiveSplineSlideSpline != PreviousSpline)
			ChangeSpline(SplineSlideComp.ActiveSplineSlideSpline);
	}

	void ChangeSpline(ASplineSlideSpline NewSpline)
	{
		PreviousSpline = NewSpline;
		Player.ClearCameraSettingsByInstigator(this);
		if (NewSpline.CameraSettings != nullptr)
			Player.ApplyCameraSettings(NewSpline.CameraSettings, CameraBlend::Normal(1.f), this, EHazeCameraPriority::High);
		Player.ClearSettingsByInstigator(this);
		if (NewSpline.CameraChaseSettings != nullptr)
			Player.ApplySettings(NewSpline.CameraChaseSettings, this, EHazeSettingsPriority::Gameplay);
	}

	void UpdateCameraClamps()
	{
		FHazeCameraClampSettings ClampSettings;

		ClampSettings.CenterOffset = FRotator::MakeFromX(SplineForward);
		ClampSettings.bUseCenterOffset = true;
		ClampSettings.CenterType = EHazeCameraClampsCenterRotation::WorldSpace;

		FVector FlattenedForward = SplineForward.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float Angle = FlattenedForward.AngularDistance(SplineForward) * RAD_TO_DEG * 0.5f;
		ClampSettings.ClampPitchUp = 70.f - Angle;
		ClampSettings.ClampPitchDown = 70.f - Angle;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.bUseClampPitchDown = true;

		Player.ApplyCameraClampSettings(ClampSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		// Look towards some location some ways down the spline
		float LookAheadDistance = DistanceAlongSpline + 8000.f;
		UHazeSplineComponent LookAheadSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline;
		if (Player.IsAnyCapabilityActive(SplineSlideTags::Jump))
		{
			// Slower acceleration when jumping
			DesiredAccelerationDuration.SnapTo(2.f);

			// When jumping we look towards forward position of spline we land on instead of current spline
			if ((SplineSlideComp.JumpDestination != nullptr) && (SplineSlideComp.JumpDistanceAlongSplines.Contains(SplineSlideComp.JumpDestination)))
			{
				// Tweak how far ahead of estimated landing location we look
				float LookAheadOffset = FMath::Max(0.f, 8000.f - Owner.ActorLocation.Distance(SplineSlideComp.JumpDestinationEstimatedLandingLocation));
				LookAheadSpline = SplineSlideComp.JumpDestination.Spline;
				LookAheadDistance = SplineSlideComp.JumpDistanceAlongSplines[SplineSlideComp.JumpDestination] + LookAheadOffset;
			}
		}
		else
		{
			// Fast acceleration when not jumping
			DesiredAccelerationDuration.AccelerateTo(0.5f, 1.f, DeltaTime);
		}
		AcceleratedCameraDesiredRotation.AcceleratedRotationDuration = DesiredAccelerationDuration.Value;

		FVector LookAheadLocation = LookAheadSpline.GetLocationAtDistanceAlongSpline(LookAheadDistance, ESplineCoordinateSpace::World);

		float Overflow = LookAheadDistance - LookAheadSpline.GetSplineLength();
		if (Overflow > 0.f)
		{
			FVector EndTangent = LookAheadSpline.GetTangentAtDistanceAlongSpline(LookAheadDistance, ESplineCoordinateSpace::World).GetSafeNormal();
			LookAheadLocation += EndTangent * Overflow;
		}

		FVector ToLookAheadLocation = LookAheadLocation - Player.ViewLocation;

		bool bDebug = IsDebugActive();
#if EDITOR
		//Player.bHazeEditorOnlyDebugBool = true;
		bDebug = bDebug || Player.bHazeEditorOnlyDebugBool;
#endif
		if (bDebug)
		{
			System::DrawDebugLine(Owner.FocusLocation, LookAheadLocation, FLinearColor::Red, 0.f, 5.f);
			System::DrawDebugSphere(LookAheadLocation, 400, 4, FLinearColor::Red, 0.f, 10);
		}

		FVector DesiredDirection = ToLookAheadLocation.SafeNormal;
		DesiredDirection.Z *= 0.5f;

		FRotator DesiredRotation = FRotator::MakeFromXY(DesiredDirection, SplineRight);
		DesiredRotation.Roll = 0.f;
		DesiredRotation = Settings.ChaseOffset.Compose(DesiredRotation);

		FVector Input = GetAttributeVector(AttributeVectorNames::RightStickRaw);
		CameraUser.DesiredRotation = AcceleratedCameraDesiredRotation.Update(CameraUser.DesiredRotation, DesiredRotation, Input, DeltaTime);
	}
}
