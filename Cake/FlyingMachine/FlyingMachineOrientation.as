struct FFlyingMachineOrientation
{
	UPROPERTY()
	FVector Forward(1.f, 0.f, 0.f);

	UPROPERTY()
	float Roll = 0.f;

	void AddYaw(float YawDelta)
	{
		FQuat YawQuat(FVector::UpVector, YawDelta * DEG_TO_RAD);
		Forward = YawQuat.RotateVector(Forward);
	}

	void AddPitch(float PitchDelta)
	{
		FQuat PitchQuat(GetRightVector(), -PitchDelta * DEG_TO_RAD);
		Forward = PitchQuat.RotateVector(Forward);
	}

	void AddRoll(float RollDelta)
	{
		Roll += RollDelta;
	}

	void ApplyOrientation(FFlyingMachineOrientation Other)
	{
		Roll += Other.Roll;
		Forward = Other.PitchYawQuat().RotateVector(Forward);
	}

	void SetFromQuat(FQuat Quat)
	{
		SetFromRotator(Quat.Rotator());
	}

	void SetFromRotator(FRotator Rotator)
	{
		Forward = Rotator.ForwardVector;
		Roll = Rotator.Roll;
	}

	FVector GetForwardVector() const
	{
		return Forward;
	}

	FVector GetRightVector() const
	{
		return Quat().RightVector;
	}

	FVector GetUpVector() const
	{
		return Quat().UpVector;
	}

	FQuat PitchYawQuat() const
	{
		return Math::MakeQuatFromX(Forward);
	}

	FQuat RollQuat() const
	{
		return FQuat(FVector::ForwardVector, -Roll * DEG_TO_RAD);
	}

	FQuat Quat() const
	{
		return PitchYawQuat() * RollQuat();
	}

	FRotator Rotator() const
	{
		return Quat().Rotator();
	}
}

namespace FFlyingMachineOrientation
{
	FFlyingMachineOrientation Lerp(FFlyingMachineOrientation A, FFlyingMachineOrientation B, float Alpha)
	{
		FQuat LerpQuat = FQuat::FindBetween(A.Forward, B.Forward);
		LerpQuat = FQuat(LerpQuat.GetRotationAxis(), LerpQuat.GetAngle() * Alpha);

		FFlyingMachineOrientation Result;

		Result.Forward = LerpQuat.RotateVector(A.Forward);
		Result.Roll = FMath::Lerp(A.Roll, B.Roll, Alpha);
		return Result;
	}
}