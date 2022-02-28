class ULocomotionFeaturePlasmaCube : UHazeLocomotionFeatureBase
{
    ULocomotionFeaturePlasmaCube()
    {
        Tag = n"PlasmaCube";
    }

    // The animation when May grab the cube
    UPROPERTY(Category = "Locomotion PlasmaCube")
    FHazePlaySequenceData PlasmaCubeEnter;

    // MH and movement BlendSpace
    UPROPERTY(Category = "Locomotion PlasmaCube")
    FHazePlayBlendSpaceData PlasmaCubeBS;

    // The animation when May lets go of the cube
    UPROPERTY(Category = "Locomotion PlasmaCube")
    FHazePlaySequenceData PlasmaCubeExit;

    // The BlendSpace when May struggles to move the cube
    UPROPERTY(Category = "Locomotion PlasmaCube")
    FHazePlayBlendSpaceData PlasmaCubeStruggleBS;

	// The Enter when May loses her grip
	UPROPERTY(Category = "Locomotion PlasmaCube")
	FHazePlaySequenceData PlasmaCubeFallEnter;

	// The MH when May is falling
	UPROPERTY(Category = "Locomotion PlasmaCube")
	FHazePlaySequenceData PlasmaCubeFallMH;

	// The Exit when May regains her grip
	UPROPERTY(Category = "Locomotion PlasmaCube")
	FHazePlaySequenceData PlasmaCubeFallExit;

	// IK Reference
	UPROPERTY(Category = "Locomotion PlasmaCube")
	FHazePlaySequenceData IKReference;
	


};