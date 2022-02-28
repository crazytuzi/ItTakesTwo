UCLASS(Meta = (ComposeSettingsOnto = "UCameraImpulseSettings"))
class UCameraImpulseSettings : UHazeComposableSettings
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse")
	bool bClampTranslation = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse", meta = (EditCondition = "bClampTranslation"))
	FVector TranslationalClamps = FVector(200.f, 200.f, 200.f);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse")
	bool bClampRotation = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraImpulse", meta = (EditCondition = "bClampRotation"))
	FRotator RotationalClamps = FRotator(30.f, 30.f, 30.f);

	void ApplyClamps(FVector& InOutTranslation, FRotator& InOutRotation)
	{
		if (bClampTranslation)
		{
			InOutTranslation.X = FMath::Clamp(InOutTranslation.X, -TranslationalClamps.X, TranslationalClamps.X);
			InOutTranslation.Y = FMath::Clamp(InOutTranslation.Y, -TranslationalClamps.Y, TranslationalClamps.Y);
			InOutTranslation.Z = FMath::Clamp(InOutTranslation.Z, -TranslationalClamps.Z, TranslationalClamps.Z);
		}
		if (bClampRotation)
		{
			InOutRotation.Yaw = FMath::Clamp(FRotator::NormalizeAxis(InOutRotation.Yaw), -RotationalClamps.Yaw, RotationalClamps.Yaw);
			InOutRotation.Pitch = FMath::Clamp(FRotator::NormalizeAxis(InOutRotation.Pitch), -RotationalClamps.Pitch, RotationalClamps.Pitch);
			InOutRotation.Roll = FMath::Clamp(FRotator::NormalizeAxis(InOutRotation.Roll), -RotationalClamps.Roll, RotationalClamps.Roll);
		}
	}
}