enum EHazeDashStopAnimationType
{
	DashStop,
	DashToJog,
	DashToAir,
};

class ULocomotionFeatureDash : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureDash()
    {
        Tag = FeatureName::Dash;
    }

	// If this is true, blendspaces are used for dashing and going into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	
	bool UseBlendspacesToMovement = false;

    // The animation when you dash from velocity
    UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashStart;

    // // The animation when you dash from standing still
    // UPROPERTY(Category = "Locomotion Dash")
    // UAnimSequence AirDash;

	// The animation when you hit another character
    UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashStop;

    // The animation when the dash is ending on the ground
    UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashToJog;

	// The animation when the dash is ending in the air
	UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashToAir;

	UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashFromLongJump;

	UPROPERTY(Category = "Locomotion Dash")
    UAnimSequence DashFromGroundPound;

	    // // The animation when you jump while in a dash
    // UPROPERTY(Category = "Locomotion Dash")
    // UAnimSequence DashJump;

	// // The animation when you perfect jump while in a dash
    // UPROPERTY(Category = "Locomotion Dash")
    // UAnimSequence PerfectDashJump;

	// // The animation when you long jump
    // UPROPERTY(Category = "Locomotion Dash")
    // UAnimSequence LongJump;

	// The animation when the dash is ending on the ground
    UPROPERTY(Category = "Locomotion Dash")
    FHazePlayBlendSpaceData DashToJogBS;

	// How long time you will stand still until the dash starts
	UPROPERTY(Category = "Dash")
	float StandingStillStartDelay = 0.3f;

    //VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;
    
};