import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;

class ULocomotionFeatureShedVacuumLaunch : ULocomotionFeatureZeroGravity
{

    default Tag = n"ZeroGravity";

    UPROPERTY(Category = "VacuumLaunch")
    FHazePlaySequenceData Enter;

	UPROPERTY(Category = "VacuumLaunch")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "VacuumLaunch")
    float FwdRotationOffset;

}