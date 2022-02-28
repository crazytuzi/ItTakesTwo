import Peanuts.Animation.Features.LocomotionFeatureGrindWeapon;
class ULocomotionFeatureTreeGrindSniper : UHazeLocomotionFeatureBase
{
	default Tag = n"Grind";
	
	UPROPERTY(Category=Aim)
	FHazePlayBlendSpaceData AimBlendSpace;
	
	UPROPERTY(Category=Shoot)
	FHazePlaySequenceData Shoot;

	UPROPERTY(Category=Shoot)
	FHazePlaySequenceData FinalShot;

	UPROPERTY(Category=Shoot)
	FHazePlayBlendSpaceData JumpAim;


    
    // Example of BlendSpace data
    // UPROPERTY(Category = "GrindSniper")
	// FHazePlayBlendSpaceData Blendspace;

}