enum EHazeLandingAnimationType
{
	Landing,
	LandingFwd,
	LandingHigh,
	LandingHighFwd,
	StartFromStill,
	DelayedStart,
	StartFromStillHigh,
	DelayedStartHigh,
	CancelLandingHighFwd,
	DashLanding,
	DashLandingFwd,
	PerfectDashLanding,
	PerfectDashLandingFwd,
	SkyDiveLanding,
	SkyDiveLandingFwd,
};

class ULocomotionFeatureLanding : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureLanding()
    {
        Tag = FeatureName::Landing;
    }
	// If this is true, only 'Landing','LandingFwd' and 'StartFromStill' is used.
	UPROPERTY(Category = "Use Only Basic Landing")
	
	bool UseOnlyBasicLanding = true;

	// If this is true, blendspaces are used for landing and going into forwards motion.
	UPROPERTY(Category = "Use Blendspaces to Movement")
	
	bool UseBlendspacesToMovement = false;
    //Landing animation while not giving input
    UPROPERTY(Category = "Landing Still")
    FHazePlaySequenceData Landing;
    //Landing animation while giving input
    UPROPERTY(Category = "Landing Fwd")
    FHazePlaySequenceData LandingFwd;
    //Landing animation while not giving input and has been in jump/inAir for longer than "FallTime"
    UPROPERTY(Category = "Landing Still")
    FHazePlaySequenceData LandingHigh;
    //Landing animation while giving input and has been in jump/inAir for longer than "FallTime"
    UPROPERTY(Category = "Landing Fwd")
    FHazePlaySequenceData LandingHighFwd;
    //Animation for when LandingHighFwd is playing and you stop giving input
    UPROPERTY(Category = "Landing Fwd")
    FHazePlaySequenceData CancelLandingHighFwd;

	//Animation when Landing during a "Jump_FromDash", while the Notify State "GoToDashLanding" is true 
	UPROPERTY(Category = "Landing Still")
    FHazePlaySequenceData DashLanding;
	//Animation when Landing during a "Jump_FromPerfectDash", while the Notify State "GoToDashLanding" is true, and giving input
	UPROPERTY(Category = "Landing Fwd")
    FHazePlaySequenceData DashLandingFwd;

	//Animation when Landing during a "Jump_FromPerfectDash", while the Notify State "GoToPerfectDashLanding" is true 
	UPROPERTY(Category = "Landing Still")
    FHazePlaySequenceData PerfectDashLanding;
	//Animation when Landing during a "JumpFromPerfectDash", while the Notify State "GoToPerfectDashLanding" is true, and giving input 
	UPROPERTY(Category = "Landing Fwd")
    FHazePlaySequenceData PerfectDashLandingFwd;

    //If "Landing" or "CancelLandingHighFwd" is playing and you give input, this animation will play.
    UPROPERTY(Category = "Start from Still")
    FHazePlaySequenceData StartFromStill;
    //Will trigger instead of"StartFromStill" if time since landing is greater than "DelayTime"
    UPROPERTY(Category = "Start from Still")
    FHazePlaySequenceData DelayedStart;
    //If "LandingHigh" is playing and you give input, this animation will play.
    UPROPERTY(Category = "Start from Still")
    FHazePlaySequenceData StartFromStillHigh;
    //Will trigger instead of"StartFromStillHigh" if time since landing is greater than "DelayTimeHigh"
    UPROPERTY(Category = "Start from Still")
    FHazePlaySequenceData DelayedStartHigh;

	UPROPERTY(Category = "SkyDive Landing")
    FHazePlaySequenceData SkyDiveLanding;

	UPROPERTY(Category = "SkyDive Landing")
    FHazePlaySequenceData SkyDiveLandingFwd;

	//Landing animation while giving input
    UPROPERTY(Category = "Blendspace Landing Fwd")
    FHazePlayBlendSpaceData LandingFwdBS;

	//Landing animation while giving input and has been in jump/inAir for longer than "FallTime"
    UPROPERTY(Category = "Blendspace Landing Fwd")
    FHazePlayBlendSpaceData LandingHighFwdBS;

	//Animation when Landing during a "Jump_FromPerfectDash", while the Notify State "GoToDashLanding" is true, and giving input
	UPROPERTY(Category = "Blendspace Landing Fwd")
    FHazePlayBlendSpaceData DashLandingFwdBS;

	//Animation when Landing during a "JumpFromPerfectDash", while the Notify State "GoToPerfectDashLanding" is true, and giving input 
	UPROPERTY(Category = "Blendspace Landing Fwd")
    FHazePlayBlendSpaceData PerfectDashLandingFwdBS;

	UPROPERTY(Category = "Blendspace Landing Fwd")
    FHazePlayBlendSpaceData SkyDiveLandingFwdBS;

	//If "Landing" or "CancelLandingHighFwd" is playing and you give input, this animation will play.
    UPROPERTY(Category = "Blendspace Start from Still")
    FHazePlayBlendSpaceData StartFromStillBS;
    //Will trigger instead of"StartFromStill" if time since landing is greater than "DelayTime"
    UPROPERTY(Category = "Blendspace Start from Still")
    FHazePlayBlendSpaceData DelayedStartBS;
    //If "LandingHigh" is playing and you give input, this animation will play.
    UPROPERTY(Category = "Blendspace Start from Still")
    FHazePlayBlendSpaceData StartFromStillHighBS;
    //Will trigger instead of"StartFromStillHigh" if time since landing is greater than "DelayTimeHigh"
    UPROPERTY(Category = "Blendspace Start from Still")
    FHazePlayBlendSpaceData DelayedStartHighBS;

    //Timewindow since "Landing". If you give input before this time has passed: "StartFromStill". After: "DelayedStart".
    UPROPERTY(Category = "Start from Still")
    float DelayTime = 0.5f;
    //Timewindow since "LandingHigh". If you give input before this time has passed: "StartFromStillHigh". After: "DelayedStartHigh".
    UPROPERTY(Category = "Start from Still")
    float DelayTimeHigh = 0.5f;
    //Blend between "Landing" & "StartFromStill"
    UPROPERTY(Category = "BlendTimes")
    float blend_StartFromStill = 0.0f;
    //Blend between "Landing" & "DelayedStart"
    UPROPERTY(Category = "BlendTimes")
    float blend_DelayedStart = 0.0f;
    //Blend between "LandingHigh" & "StartFromStillHigh"
    UPROPERTY(Category = "BlendTimes")
    float blend_StartFromStillHigh = 0.0f;
    //Blend between "LandingHigh" & "DelayedStartHigh"
    UPROPERTY(Category = "BlendTimes")
    float blend_DelayedStartHigh = 0.0f;
    //Blend between "LandingHighFwd" & "CancelLandingHighFwd"
    UPROPERTY(Category = "BlendTimes")
    float blend_CancelLandingHighFwd = 0.0f;

    //The added time of previous SubAnimInstances "Jump" & "InAir". More can be added to this in blueprint like "Dash" or "Wallrun"
    UPROPERTY(Category = "TriggerHighFallTime")
    float FallTime = 0.8f;

    //Not used intentionally here
    UPROPERTY(Category = "useless?")
    float BlendTime = 0.0f;

    //Not used intentionally here
    UPROPERTY(Category = "useless?")
    EHazeBoneFilterTemplate BoneFilter;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;


};