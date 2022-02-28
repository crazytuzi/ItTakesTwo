class ULocomotionFeaturePlasmaBall : UHazeLocomotionFeatureBase
{
    ULocomotionFeaturePlasmaBall()
    {
        Tag = n"PlasmaBall";
    }

    // The animation when you grab the ball
    UPROPERTY(Category = "Locomotion PlasmaBall")
    UAnimSequence PlasmaBallEnter;

    // MH and movement
    UPROPERTY(Category = "Locomotion PlasmaBall")
    UBlendSpaceBase PlasmaBallBS;

    // The animation when you let go of the ball
    UPROPERTY(Category = "Locomotion PlasmaBall")
    UAnimSequence PlasmaBallExit;

    // The animation when small Cody interacts with the ball
    UPROPERTY(Category = "Locomotion PlasmaBall")
    UAnimSequence PlasmaBallSmall;

	// The animation when medium Cody interacts with the ball
	UPROPERTY(Category = "Locomotion PlasmaBall")
	UAnimSequence PlasmaBallMedium;

};