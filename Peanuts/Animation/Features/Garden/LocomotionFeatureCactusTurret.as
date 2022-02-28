class ULocomotionFeatureCactusTurret : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureCactusTurret()
    {
        Tag = n"CactusTurret";
    }

	UPROPERTY()
	FHazePlaySequenceData Start;

	UPROPERTY()
	FHazePlayBlendSpaceData MH;

	UPROPERTY()
	FHazePlayBlendSpaceData AimAdjust;

	UPROPERTY()
	FHazePlaySequenceData Reload;

	UPROPERTY()
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "Firing")
	FHazePlayBlendSpaceData FiringMH;

	UPROPERTY(Category = "Firing")
	FHazePlaySequenceData FiringArms;

	UPROPERTY(Category = "Firing")
	FHazePlaySequenceData NeedleAmmo;

	
};