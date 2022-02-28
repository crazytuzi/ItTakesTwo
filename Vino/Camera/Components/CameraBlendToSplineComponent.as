import Vino.Camera.Components.CameraSpringArmComponent;

// This will handle blends from current camera location to within set distance of a spline
class UCameraBlendToSplineComponent : UHazeCameraParentComponent
{
	UPROPERTY()
	UHazeSplineComponentBase CameraSpline;

	UPROPERTY()
	float CaptureDistance = 70.f;

	UPROPERTY()
	float InterpDistance = 20.f;

	AHazePlayerCharacter PlayerUser;
	FHazeAcceleratedVector BlendLoc;
	FHazeAcceleratedVector RelativeLoc;
	FVector SplineLocation;
	float BlendTime = 2.f;
	bool bCaptured = false;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		PlayerUser = Cast<AHazePlayerCharacter>(_User.Owner);

		// Note: Never snap this into place when activating!
		FVector ViewLocation = PlayerUser.ViewLocation;
		BlendLoc.SnapTo(ViewLocation);
		SetWorldLocation(ViewLocation);

		FHazeSplineSystemPosition SplinePos = CameraSpline.GetPositionClosestToWorldLocation(ViewLocation);
		SplineLocation = SplinePos.WorldLocation;
		BlendTime = Camera.LastActivationBlend.BlendTime;
		bCaptured = false;

		// TODO: Reevaluate the below hack after Nuts 
		// We do not want default camera to collide with geometry near the spline during blend in
		FHazeCameraSpringArmSettings IgnoreCollisionSettings;
		IgnoreCollisionSettings.bUseMinDistance = true;
		IgnoreCollisionSettings.MinDistance = 400.f;
		UCameraSpringArmComponent SpringArm = UCameraSpringArmComponent::Get(PlayerUser);
		if (SpringArm != nullptr) 
			IgnoreCollisionSettings.MinDistance = FMath::Min(SpringArm.TraceBlockedRange.Value, IgnoreCollisionSettings.MinDistance);
		PlayerUser.ApplyCameraSpringArmSettings(IgnoreCollisionSettings, CameraBlend::Normal(0.f), this, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		PlayerUser.ClearCameraSettingsByInstigator(this, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		// Place this at parent location and stop updating
		SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaTime)
	{
		if (AttachParent == nullptr)
			return;

		if (RelativeLocation.IsNearlyZero(0.5f))
			return; // Almost there, just go with attach parent

		if (Camera.CameraState != EHazeCameraState::Active)
			return; // Just maintain position when blending out

		if (!bCaptured && BlendLoc.Value.IsNear(SplineLocation, CaptureDistance))
		{
			// We're close enough, set up captured acceleration
			bCaptured = true;
			FTransform WorldToParentSpace = AttachParent.WorldTransform.Inverse();
			FVector RelativeWorldVelocity = BlendLoc.Velocity - AttachParent.ComponentVelocity;
			RelativeLoc.SnapTo(WorldToParentSpace.TransformPosition(BlendLoc.Value), WorldToParentSpace.TransformVector(RelativeWorldVelocity)); 
		}

		if (bCaptured)
		{
			// We're close to spline, accelerate relative location down to zero
			RelativeLoc.AccelerateTo(FVector::ZeroVector, BlendTime, DeltaTime);
			SetRelativeLocation(RelativeLoc.Value);
		}
		else if (DeltaTime > 0.f)
		{
			// Accelerate to spline
			BlendLoc.AccelerateTo(SplineLocation, BlendTime, DeltaTime);
			SetWorldLocation(BlendLoc.Value);
		}
	}
}

