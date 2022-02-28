class ULocomotionFeatureRideDinocrane : UHazeLocomotionFeatureBase 
{
	
    ULocomotionFeatureRideDinocrane()
    {
        Tag = n"RideDinocrane";
    }

	UPROPERTY(Category = "RideDinoCrane")
    FHazePlaySequenceData Enter;

	// Blendspace
    UPROPERTY(Category = "RideDinoCrane")
    FHazePlayBlendSpaceData MHBlendspace;

}