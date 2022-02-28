import Peanuts.Animation.Features.LocomotionFeatureGrind;

class ULocomotionFeatureGrindWeapon : ULocomotionFeatureGrindShared
{

	UPROPERTY(Category=Shoot)
	FHazePlaySequenceData Shoot;

	UPROPERTY(Category=Aim)
	FHazePlayBlendSpaceData AimBlendSpace;

	UPROPERTY(Category=Jump)
	FHazePlayBlendSpaceData AimJump;

	UPROPERTY(Category=Jump)
	FHazePlayBlendSpaceData AimJumpAimSpace;


}
