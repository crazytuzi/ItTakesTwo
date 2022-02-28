namespace SwimmingStatics
{
	void UpdateControlRotation(AHazePlayerCharacter Player, float DeltaTime, FVector2D Input, FHazeAcceleratedRotator& InOutControlRotation)
	{
		UHazeCameraComponent CurCam = Player.GetCurrentlyUsedCamera();
		if ((CurCam != nullptr) && (CurCam.Owner == Player))
		{
			// Default camera, use normal control rotation
			InOutControlRotation.AccelerateTo(Player.GetControlRotation(), 0.3f, DeltaTime);
		}
		else
		{
			// Non-default camera, we adjust control pitch as if it was free so we can swim upwards more freely
			if (Input.IsNearlyZero(0.1f))
			{	
				// No input, accelerate back to normal control rotation
				InOutControlRotation.AccelerateTo(Player.GetControlRotation(), 0.5f, DeltaTime);
			}
			else
			{
				FRotator TurnRate = FRotator(120.f, 360.f, 0.f);
				if ((CurCam != nullptr) && (CurCam.User != nullptr))
					TurnRate = CurCam.User.GetCameraTargetTurnRate();
				FRotator InputDelta = FRotator(Input.Y, Input.X, 0.f);
				InputDelta.Yaw *= TurnRate.Yaw;
				InputDelta.Pitch *= TurnRate.Pitch;
				if (Player.IsCameraPitchInverted())
					InputDelta.Pitch *= -1.f;
				if (Player.IsCameraYawInverted())
					InputDelta.Yaw *= -1.f;
				InputDelta *= DeltaTime;

				FRotator Delta = (InOutControlRotation.Value + InputDelta - Player.GetControlRotation()).GetNormalized();
				Delta.Yaw = FMath::Clamp(Delta.Yaw, -80.f, 80.f);
				Delta.Pitch = FMath::Clamp(Delta.Pitch, -60.f, 60.f);
				InOutControlRotation.SnapTo(Player.GetControlRotation() + Delta);
				InOutControlRotation.Value.Pitch = FMath::Clamp(InOutControlRotation.Value.Pitch, -89.f, 89.f);
			}
		}
	}
}