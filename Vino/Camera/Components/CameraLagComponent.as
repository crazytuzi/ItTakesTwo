class UCameraLagComponent : UHazeCameraParentComponent
{
	UPROPERTY(Category = "Lag", meta = (InlineEditConditionToggle))
	bool bUseRotationLag = true;
	UPROPERTY(Category = "Lag", meta = (EditCondition = "bUseRotationLag"))
	FRotator RotationLagDuration = FRotator(5.f, 5.f, 5.f);

	UPROPERTY(Category = "Lag", meta = (InlineEditConditionToggle))
	bool bUseLocationLag = true;
	UPROPERTY(Category = "Lag", meta = (EditCondition = "bUseLocationLag"))
	FVector LocationLagDuration = FVector(5.f, 5.f, 5.f);

	FHazeAcceleratedFloat LocX;
	FHazeAcceleratedFloat LocY;
	FHazeAcceleratedFloat LocZ;

	FHazeAcceleratedFloat RotYaw;
	FHazeAcceleratedFloat RotPitch;
	FHazeAcceleratedFloat RotRoll;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		if (bUseLocationLag)
		{
			FVector TargetLoc = GetTargetLocation();
			LocX.SnapTo(TargetLoc.X);
			LocY.SnapTo(TargetLoc.Y);
			LocZ.SnapTo(TargetLoc.Z);
			SetWorldLocation(TargetLoc);
		}

		if (bUseRotationLag)
		{		
			FRotator TargetRot = GetTargetRotation();
			RotYaw.SnapTo(TargetRot.Yaw);
			RotPitch.SnapTo(TargetRot.Pitch);
			RotRoll.SnapTo(TargetRot.Roll);
			SetWorldRotation(TargetRot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if (Camera == nullptr)
			return;

		FTransform ParentTransform = AttachParent.GetWorldTransform();

		if (bUseLocationLag)
		{
			FVector TargetLoc = GetTargetLocation();
			FVector Duration = ParentTransform.TransformVector(LocationLagDuration);
			FVector LaggedLoc;
			LaggedLoc.X = LocX.AccelerateTo(TargetLoc.X, Duration.X, DeltaSeconds);
			LaggedLoc.Y = LocY.AccelerateTo(TargetLoc.Y, Duration.Y, DeltaSeconds);
			LaggedLoc.Z = LocZ.AccelerateTo(TargetLoc.Z, Duration.Z, DeltaSeconds);
			SetWorldLocation(LaggedLoc);
		}

		if (bUseRotationLag)
		{		
			FRotator TargetRot = GetTargetRotation();
			FRotator LaggedRot;
			LaggedRot.Yaw = RotYaw.AccelerateTo(TargetRot.Yaw, RotationLagDuration.Yaw, DeltaSeconds);
			LaggedRot.Pitch = RotPitch.AccelerateTo(TargetRot.Pitch, RotationLagDuration.Pitch, DeltaSeconds);
			LaggedRot.Roll = RotRoll.AccelerateTo(TargetRot.Roll, RotationLagDuration.Roll, DeltaSeconds);
			SetWorldRotation(TargetRot);
		}
	}

	FVector GetTargetLocation()
	{
		return GetAttachParent().GetWorldLocation();
	}
	FRotator GetTargetRotation()
	{
		return GetAttachParent().GetWorldRotation();
	}
}