class ULocomotionFeatureSwinging : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureSwinging()
    {
        Tag = n"Swinging";
    }

	// Swinging forwards
	UPROPERTY(Category = "Swinging|Forward")
	FHazePlayBlendSpaceData Swing;

	UPROPERTY(Category = "Swinging|Backwards")
	FHazePlayBlendSpaceData SwingBck;

	// Swinging Enter
	UPROPERTY(Category = "Enter")
	FHazePlayBlendSpaceData Enter;

	UPROPERTY(Category = "Enter")
	float BlendTime = 0.07f;
	
	// Swinging jump off forward
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitJumpForward;

	// Swinging jump off backwards
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitJumpBackward;

	// Swinging jump off backwards
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitJumpBackwardLeft;

	// Swinging jump off backwards
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitJumpBackwardRight;

	// Swinging drop down
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitFwd;

	// Swinging drop down
	UPROPERTY(Category = "Exits")
	FHazePlaySequenceData ExitBck;

	// Should the turn animation play on every apex point? if not the turn will only trigger if the player is facing the camera
	UPROPERTY(Category = "SwingingTurns")
	bool bPlayTurnOnEveryApex;

	// 0 = bottom & 1 = the apex of the swing
	UPROPERTY(Category = "SwingingTurns")
	float TriggerTurnAfter = .65f;

	// If turns are out of sync with the swinging they'll be playrated to try and catch up as fast as possible.
	UPROPERTY(Category = "SwingingTurns")
	bool bAllowPlayratedTurns;

	// 0 = bottom & 1 = the apex of the swing
	UPROPERTY(Category = "SwingingTurns")
	float TriggerJumpBackAfter = .8f;

	UPROPERTY(Category = "SwingingTurns|Forward")
	FHazePlaySequenceData TurnAroundLeft;

	UPROPERTY(Category = "SwingingTurns|Forward")
	FHazePlaySequenceData TurnAroundRight;

	UPROPERTY(Category = "SwingingTurns|Backwards")
	FHazePlaySequenceData TurnAroundLeftBck;

	UPROPERTY(Category = "SwingingTurns|Backwards")
	FHazePlaySequenceData TurnAroundRightBck;


	UPROPERTY(Category = "Inverse Kinematics")
	bool bEnableIK;

	UPROPERTY(Category = "Inverse Kinematics|Forward")
	FHazePlaySequenceData IKReference;

	UPROPERTY(Category = "Inverse Kinematics|Backwards")
	FHazePlaySequenceData IKReferenceBck;


}

