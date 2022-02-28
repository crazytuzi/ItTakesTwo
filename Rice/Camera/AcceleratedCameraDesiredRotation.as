struct FAcceleratedCameraDesiredRotation
{
	private FHazeAcceleratedRotator AcceleratedDesiredRotation;

	// How long before the camera acceleration interps back in
	float CooldownPostInput = 2.0f;
	// How long it takes for the acceleration to interp back in once the cooldown has finished
	float InputScaleInterpSpeed = 0.4f;
	// How fast the camera acceleration is
	float AcceleratedRotationDuration = 1.f;
	
	private float CooldownDuration = 0.f;
	private float InputScale = 1.f;

	// Accelerates and returns the new value
	FRotator Update(FRotator CurrentDesiredRotation, FRotator TargetDesiredRotation, FVector Input, float DeltaTime)
	{
		if (Input.IsNearlyZero())
		{
			if (CooldownDuration < CooldownPostInput)
				CooldownDuration += DeltaTime;
			else
				InputScale = FMath::FInterpConstantTo(InputScale, 1.f, DeltaTime, InputScaleInterpSpeed);
		}
		else
		{
			CooldownDuration = 0.f;
			InputScale = 0.f;
		}

		AcceleratedDesiredRotation.Value = CurrentDesiredRotation;
		AcceleratedDesiredRotation.AccelerateTo(TargetDesiredRotation, AcceleratedRotationDuration, DeltaTime * InputScale);
		return AcceleratedDesiredRotation.Value;
	}

	// The rotation of the players camera - UCameraComponent::WorldRotation
	void Reset(FRotator CurrentCameraRotation)
	{
		AcceleratedDesiredRotation.SnapTo(CurrentCameraRotation);
		InputScale = 1.f;
		CooldownDuration = CooldownPostInput;
	}

	FRotator GetDesiredRotation()
	{
		return AcceleratedDesiredRotation.Value;
	}

	FRotator GetValue()
	{
		return AcceleratedDesiredRotation.Value;
	}
}