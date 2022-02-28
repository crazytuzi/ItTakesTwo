class ULocomotionFeatureWindWalkDash : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWindWalkDash()
    {
        Tag = n"WindWalkDash";
    }

    // Dash in headwind
    UPROPERTY(Category = "WindWalkDash")
    FHazePlaySequenceData HeadwindDash;

	// Dash in tailwind
    UPROPERTY(Category = "WindWalkDash")
    FHazePlaySequenceData TailwindDash;
	
};