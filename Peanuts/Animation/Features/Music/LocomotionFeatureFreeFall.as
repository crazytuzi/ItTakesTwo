class ULocomotionFeatureFreeFall : UHazeLocomotionFeatureBase
{
    default Tag = n"FreeFall";

	UPROPERTY(Category = "FreeFall")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "FreeFall")
    FHazePlaySequenceData Collide;

	UPROPERTY(Category = "RotationValues")
	float SideRotationSpeed = 200.f;

	UPROPERTY(Category = "RotationValues")
	float FwdRotationSpeed = 500.f;

	// Rage -1.f - 1.f
	UPROPERTY(Category = "RotationValues")
	float InitialFwdRotation = 0.5f;

	// Rage -1.f - 1.f
	UPROPERTY(Category = "RotationValues")
	float InitialSideRotation = 0.5f;
	
};