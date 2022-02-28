enum WeaponType {
	SapGun,
	MatchWeapon
}

class ULocomotionFeatureSlopeSlidingAim : UHazeLocomotionFeatureBase
{
    
    default Tag = FeatureName::SlopeSliding;
    

	// Weapon type
	UPROPERTY(Category = "Slope Sliding")
	WeaponType Weapon;

    // Slow sliding blendspace
    UPROPERTY(Category = "Slope Sliding")
    FHazePlayBlendSpaceData SlopeSliding;

    // Additive animation to play when the player shoots
    UPROPERTY(Category = "Slope Sliding Shoot")
    FHazePlaySequenceData SlopeSlidingShoot;

    UPROPERTY(Category = "Slope Sliding Shoot")
    FHazePlaySequenceData IKReference;

	// Additive HitReaction
    UPROPERTY(Category = "Slope Sliding Shoot")
    FHazePlaySequenceData HitReaction;

};