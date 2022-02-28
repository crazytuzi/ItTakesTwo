enum EMagnetHatRemovalType
{
	Water,
	FallOff,
	Stolen
}

enum EMagnetHatType
{
	WorkerHelm,
	OldLadyHat,
	LighthouseKeeperHat,
	FishermanHat,
	PirateHat,
	TopHat,
	FemaleCylindricalHat,
	FemaleFlatHat
}

struct FMagnetHatSettings
{
	UPROPERTY()
	EMagnetHatType Type;

	UPROPERTY()
	FVector OffsetLoc = FVector(0.f);

	UPROPERTY()
	FVector AddedScale = FVector(0.f);
	
	UPROPERTY()
	FRotator OffsetRot = FRotator(0.f);
}