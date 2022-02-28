enum EHazeStartAnimationType
{
	StartAnimation,
	StartInMotionAnimation,
	StartInMotionVar2Animation,
	ActionStartAnimation,
	ExhaustedStartAnimation,
	StartInMotionDefault,
};

enum EHazeStopAnimationType
{
	StopAnimation,
	ActionStopAnimation,
	ExhaustedStopAnimation,
	EasyStop,
	GoToStopAnimation,
};

enum EHazeIdleAnimationType
{
	MH,
	ActionMH,
	ExhaustedMH,
};

class ULocomotionFeatureMovementAdvanced : UHazeLocomotionFeatureBase
{
   default Tag = n"Movement";
    



    UPROPERTY(Category = "Information")
    FString info = " Use the bool 'UseActionIdle' to enable or disable all 'Action' and 'Exhausted' logic.



	Animations that ends in 'Movement', 'Action' or 'Exhaust' pose,
	needs the notify 'GoTo/Action/Exhausted/Movement' in the end";

	UPROPERTY(Category = "Information")
	bool Use180 = false;
  
    UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData IdleAnimations;

    //Enables Idle gestures when player has been standing still without input
    UPROPERTY(Category = "IdleAnimations")
    bool UseIdleGestures = false;

	UPROPERTY(Category = "IdleAnimations")
    float IdleGestureTriggerTime = 10.0f;

	UPROPERTY(Category = "IdleAnimations")
    float BigGestureTriggerTime = 30.0f;

	UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData IdleGestures;

	UPROPERTY(Category = "IdleAnimations")
    FHazePlaySequenceData BigGesturesStart;

	UPROPERTY(Category = "IdleAnimations")
    FHazePlaySequenceData BigGesturesMH;

	//Enables both "Action" and "Exhausted" Idles
    UPROPERTY(Category = "IdleAnimations")
    bool UseActionIdle = false;
    
    UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData ActionIdleAnimations;
    
    UPROPERTY(Category = "TransitionAnimations")
    FHazePlaySequenceData IdleToAction;
    
    UPROPERTY(Category = "TransitionAnimations")
    FHazePlaySequenceData ActionToIdle;
    
    UPROPERTY(Category = "IdleAnimations")
    FHazePlayRndSequenceData ExhaustedIdleAnimations;
    
    UPROPERTY(Category = "TransitionAnimations")
    FHazePlaySequenceData IdleToExhausted;
    
    UPROPERTY(Category = "TransitionAnimations")
    FHazePlaySequenceData ExhaustedToIdle;

    //Moving adds "ActionTime" ≈ seconds, Jumping etc. adds twice the amount of "ActionTime". "ActionIdle" will trigger if player has collected more than this "ActionTime"
    UPROPERTY(Category = "IdleAnimations")
    float ActionIdleTriggerTime = 10.0f;

    //Moving adds "ActionTime" ≈ seconds, Jumping etc. adds twice the amount of "ActionTime". "ExhaustedIdle" will trigger if player has collected more than this "ActionTime"
    UPROPERTY(Category = "IdleAnimations")
    float ExhaustedIdleTriggerTime = 50.0f;
    
    UPROPERTY(Category = "StartAnimations")
    FHazePlayBlendSpaceData StartAnimation;

    //This animation should be a movement loop.
    UPROPERTY(Category = "StartAnimations")
    FHazePlayBlendSpaceData StartInMotionAnimation;

	UPROPERTY(Category = "StartAnimations")
    FHazePlayBlendSpaceData StartInMotionVar2Animation;
    
    UPROPERTY(Category = "StartAnimations")
    FHazePlayBlendSpaceData ActionStartAnimation;
    
    UPROPERTY(Category = "StartAnimations")
    FHazePlayBlendSpaceData ExhaustedStartAnimation;
	
    UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData StopAnimation;

	UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData GoToStopAnimation;

    // Needs notifies: 'GoToActionMh' in the end.
    UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData ActionStopAnimation;
    // Needs notifies: 'GoToExhaustMh' in the end.
    UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData ExhaustedStopAnimation;

	UPROPERTY(Category = "StopAnimations")
    FHazePlaySequenceData EasyStopAnimation;

    UPROPERTY(Category = "MovementAnimations")
    bool bUseMovementBlendSpace = false;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlaySequenceByValueData MovementAnimation;

    UPROPERTY(Category = "MovementAnimations")
    FHazePlayBlendSpaceData MovementBlendSpace;

	//VO Efforts for Action Animation
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortAction;

	//VO Efforts for Exhausted Animation
	UPROPERTY(Category = "VO")
	UFoghornBarkDataAsset VOEffortExhausted;

};