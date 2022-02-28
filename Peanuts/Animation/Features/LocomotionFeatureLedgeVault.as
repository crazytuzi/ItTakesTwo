class ULocomotionFeatureLedgeVault : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureLedgeVault()
    {
        Tag = n"CharacterLedgeVault";
    }
	UPROPERTY(Category = "LedgeVault")
    FHazePlaySequenceData LedgeVaultStart;

    // Ledge vault 
    UPROPERTY(Category = "LedgeVault")
    FHazePlaySequenceData LedgeVault;
	
	// Ledge vault from a dash
    UPROPERTY(Category = "LedgeVault")
    FHazePlaySequenceData LedgeVaultFromDash;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
};