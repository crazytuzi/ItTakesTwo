
enum EHazeJumpAnimationType
{
	Jump,
	JumpSpeedBoost,
	JumpFwd,
	JumpFwdSpeedBoost,
	JumpFromLanding,
	JumpFwdFromLanding,
	JumpFromLandingHigh,
	JumpFwdFromLandingHigh,
	Jump180L,
	Jump180R,
	JumpFromDash,
	JumpFromDashStop,
	JumpFromPerfectDash,
	JumpFromPerfectDashStop,
};

class ULocomotionFeatureJump : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureJump()
    {
        Tag = FeatureName::Jump;
    }
	
	//If this is true only the animation in 'Jump' slot will be used (except for speedboost, it has its own bool).
	UPROPERTY(Category = "Use Special Jumps?")
	bool UseBasicJumpOnly = true;
	//If this is true, speedboost jumps is enabled.
	UPROPERTY(Category = "Use Special Jumps?")
	bool CanSpeedBoostJump = true;

    //Jump while not giving input
    UPROPERTY(Category = "Jump Still")
    FHazePlaySequenceData Jump;

	//Jump while not giving input
    UPROPERTY(Category = "Jump Still")
    FHazePlaySequenceData JumpWithSpeedBoost;

    //Jump while not giving input and is in landing
    UPROPERTY(Category = "Jump Still")
    FHazePlaySequenceData JumpFromLanding;

    //Jump while not giving input and is in landing high
    UPROPERTY(Category = "Jump Still")
    FHazePlaySequenceData JumpFromLandingHigh;

    //Jump while giving input
    UPROPERTY(Category = "Jump Fwd")
    FHazePlaySequenceData JumpFwd;

	
    UPROPERTY(Category = "Jump Fwd")
    FHazePlaySequenceData JumpFwdWithSpeedBoost;

    //Jump while giving input and is in landing
    UPROPERTY(Category = "Jump Fwd")
    FHazePlayRndSequenceData JumpFwdFromLanding;

	UPROPERTY(Category = "Jump Fwd")
    FHazePlayRndSequenceData JumpFwdFromLanding_Var2;


    //Jump while giving input and is in landing high
    UPROPERTY(Category = "Jump Fwd")
    FHazePlaySequenceData JumpFwdFromLandingHigh;

	UPROPERTY(Category = "Jump 180")
    FHazePlaySequenceData Jump180L;

	UPROPERTY(Category = "Jump 180")
    FHazePlaySequenceData Jump180R;

	UPROPERTY(Category = "Dashing and Jumping")
	FString Info = "These animation slots can be left empty, and are only called upon if the Notify States 
	'GoToJumpFromDash' and 'GoToJumpFromPerfectDash' are active";

	//Jump while dashing, if the Notify State "GoToJumpFromDash" is set in the Dash animation asset.
    UPROPERTY(Category = "Dashing and Jumping")
    FHazePlaySequenceData DashJump;

	//Jump after dashing, while in the "Roll_Stop" or "Roll_To_Jog" animations if the Notify State "GoToJumpFromDash" is set in the animation asset.
    UPROPERTY(Category = "Dashing and Jumping")
    FHazePlaySequenceData DashStopJump;

	//Jump while PerfectDashing, if the Notify State "GoToJumpFromPerfectDash" is set in the PerfectDash animation asset.
    UPROPERTY(Category = "Dashing and Jumping")
    FHazePlaySequenceData PerfectDashJump;

	//Jump after PerfectDashing, while in "Jog_From_PerfectDash" or "Stop_From_PerfectDash" animations if the Notify State "GoToJumpFromPerfectDash" is set in the animation asset.
    UPROPERTY(Category = "Dashing and Jumping")
    FHazePlaySequenceData PerfectDashStopJump;

    //Time window since landing. Triggers corresponding animation if jump is pressed in that window
    UPROPERTY(Category = "Delays")
    float JumpFromLanding_Delay = 0.3f;

    //Time window since landing. Triggers corresponding animation if jump is pressed in that window
    UPROPERTY(Category = "Delays")
    float JumpFwdFromLanding_Delay = 0.3f;

    //Time window since landing. Triggers corresponding animation if jump is pressed in that window
    UPROPERTY(Category = "Delays")
    float JumpFromLandingHigh_Delay = 0.3f;

    //Time window since landing. Triggers corresponding animation if jump is pressed in that window
    UPROPERTY(Category = "Delays")
    float JumpFwdFromLandingHigh_Delay = 0.3f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float Jump_Blend = 0.0f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float JumpFromLanding_Blend = 0.0f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float JumpFromLandingHigh_Blend = 0.0f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float JumpFwd_Blend = 0.0f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float JumpFwdFromLanding_Blend = 0.0f;

    //Blend in time for this jump
    UPROPERTY(Category = "BlendTimes")
    float JumpFwdFromLandingHigh_Blend = 0.0f;

	UPROPERTY(Category = "BlendTimes")
    float Jump180_Blend = 0.0f;

	//VO Efforts
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort;

	//VO Efforts for Jump 180
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffort180;

};