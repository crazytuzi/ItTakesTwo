class ULocomotionFeatureMoonBaboonOnMoon : UHazeLocomotionFeatureBase 
{

    ULocomotionFeatureMoonBaboonOnMoon()
    {
        Tag = n"MoonBaboonOnMoon";
    }

    // Run cycle
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData Run;

    // Hit Reaction
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData HitReaction;

    // Hit Reaction
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData JetpackHoveringMh;

    // Enter Flying
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData HoveringToFlying;

    // MH while flying to a new location on the moon
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData JetpackFlyingMH;

	UPROPERTY(Category = "MoonBaboon")
	FHazePlaySequenceData JetpackFlyingToLanding;

	UPROPERTY(Category = "MoonBaboon")
	FHazePlaySequenceData JetpackLandingMH;

    // Start landing
    UPROPERTY(Category = "MoonBaboon")
    FHazePlaySequenceData JetpackLanding;
}