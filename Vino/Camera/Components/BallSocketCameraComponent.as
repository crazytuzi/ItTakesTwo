import Vino.Camera.Components.CameraUserComponent;

class UBallSocketCameraComponent : UHazeCameraParentComponent
{
	default bWantsCameraInput = true;

	UPROPERTY()
	float RotationSpeed = 1080.f;

	UPROPERTY(meta = (InlineEditConditionToggle))
	bool bBlendToParentWithNoInput = false;

	UPROPERTY(meta = (EditCondition = "bBlendToParentWithNoInput", ClampMin = "0.0"))
	float BlendToParentWithNoInputDuration = 5.f;

	FRotator PreviousWorldRotation;
	FHazeAcceleratedFloat BlendBackDuration;
	FHazeAcceleratedRotator BlendBackRotation; 
	UCameraUserComponent User;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousWorldRotation = GetWorldRotation();
		BlendBackDuration.SnapTo(BlendToParentWithNoInputDuration * 5.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent InUser, EHazeCameraState PreviousState)
	{
        PreviousWorldRotation = GetWorldRotation();
		User = Cast<UCameraUserComponent>(InUser);

		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if ((Camera == nullptr) || (User == nullptr))
			return;

		FRotator DesiredRot = User.GetDesiredRotation();
		FRotator TargetRot = DesiredRot;
		if (!CameraClampsAllowInput())
		{
			BlendBackRotation.Velocity = 0.f;
			TargetRot = GetParentRotation();
			BlendBackRotation.SnapTo(TargetRot);
		}
		else if (User.bRegisteredInput)
		{
			BlendBackRotation.SnapTo(BlendToParentWithNoInputDuration * 5.f);
			BlendBackRotation.SnapTo(DesiredRot);
			TargetRot = DesiredRot;
		}
		else if (bBlendToParentWithNoInput)
		{
			BlendBackRotation.Value = DesiredRot;
			BlendBackDuration.AccelerateTo(BlendToParentWithNoInputDuration * 0.5f, BlendToParentWithNoInputDuration, DeltaSeconds);
			TargetRot = BlendBackRotation.AccelerateTo(GetParentRotation(), BlendBackDuration.Value, DeltaSeconds);
		}	

		FRotator NewRot = FMath::RInterpTo(PreviousWorldRotation, TargetRot, DeltaSeconds, RotationSpeed);
		FHazeCameraClampSettings Clamps; 
		User.GetClampSettings(Clamps);
		if (Clamps.IsUsed())
		{
			FRotator LocalRot = User.WorldToLocalRotation(NewRot);
			LocalRot = User.ClampLocalRotation(LocalRot);
			NewRot = User.LocalToWorldRotation(LocalRot);
		}
		SetWorldRotation(NewRot);
		PreviousWorldRotation = NewRot;
	}

	bool CameraClampsAllowInput()
	{
		// Note that we do not use user clamps, since these may be blending in or set from other system.
		// Only the clamps set on the actual camera will affect if we can control this camera or not.
		FHazeCameraClampSettings Clamps = Camera.ClampSettings;
		if (!Clamps.bUseClampPitchDown || !Clamps.bUseClampPitchUp || !Clamps.bUseClampYawLeft || !Clamps.bUseClampYawRight)
			return true;
		if ((Clamps.ClampYawRight > 1.f) || (Clamps.ClampYawLeft > 1.f) || (Clamps.ClampPitchDown > 1.f) || (Clamps.ClampPitchUp > 1.f))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr))
			return;
		PreviousWorldRotation = Camera.GetUser().GetDesiredRotation();
		Update(0.f);
	}

	FRotator GetParentRotation()
	{
		USceneComponent Parent = GetAttachParent();
		if (Parent == nullptr)
			Parent = Owner.RootComponent;	
		return Parent.WorldRotation;
	}
};
