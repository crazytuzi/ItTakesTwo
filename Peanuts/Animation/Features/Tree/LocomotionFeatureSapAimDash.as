import Cake.Weapons.Sap.SapWeaponWielderComponent;
class ULocomotionFeatureSapAimDash : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSapAimDash()
    {
        Tag = FeatureName::Dash;
    }

	UFUNCTION(BlueprintOverride)
	bool CanActivate(UHazeCharacterSkeletalMeshComponent InOwningMesh) const
	{
		auto SapWielder = USapWeaponWielderComponent::Get(InOwningMesh.GetOwner());
		if (SapWielder == nullptr)
			return true;

		// Only activate this feature if we're currently aiming, since this is an aim-specific feature
		// However, aiming will also be blocked this frame, which is why we need to have two separate dashes in
		// 	the same state asset.

		// This relies on the fact that bIsAiming gets reset _after_ animation has updated, so it will still be "valid" this frame
		return SapWielder.bAimingWasBlocked;
	}


    // The animation when you dash from velocity
    UPROPERTY(Category = "Locomotion Dash")
    FHazePlayBlendSpaceData DashStart;

	// The animation when you hit another character
    UPROPERTY(Category = "Locomotion Dash")
    FHazePlayBlendSpaceData DashStop;

    // The animation when the dash is ending on the ground
    UPROPERTY(Category = "Locomotion Dash")
    FHazePlayBlendSpaceData DashToJog;

	// The animation when the dash is ending in the air
	UPROPERTY(Category = "Locomotion Dash")
    FHazePlayBlendSpaceData DashToAir;

	//UPROPERTY(Category = "Locomotion Dash")
    //UAnimSequence DashFromGroundPound;

	// How long time you will stand still until the dash starts
	UPROPERTY(Category = "Dash")
	float StandingStillStartDelay = 0.3f;

    //VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
};