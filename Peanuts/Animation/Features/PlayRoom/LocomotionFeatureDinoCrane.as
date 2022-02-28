enum EHazeOverrideAnim {
	Idle,
	EatPlayer,
	EatPlayerAndSlammer
}

class ULocomotionFeatureDinoCrane : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureDinoCrane()
    {
        Tag = n"DinoCrane";
    }

	// General movement

    // Additive MH animation
    UPROPERTY(Category = "DinoCrane")
    FHazePlaySequenceData MH;

	// Movement blendspce
	UPROPERTY(Category = "DinoCrane")
    FHazePlayBlendSpaceData Movement;

	// Additive Rotation BS
	UPROPERTY(Category = "DinoCrane")
    FHazePlayBlendSpaceData Rotation;

	// Additive BS for crane up/down movement
	UPROPERTY(Category = "DinoCrane")
    FHazePlayBlendSpaceData CraneLift;

	// Additive Wheels rotation BS
	UPROPERTY(Category = "DinoCrane")
    FHazePlayBlendSpaceData WheelsRotation;

	// Grab

	// Play when you press Y without beeing close to a point to grab
	UPROPERTY(Category = "DinoCraneGrab")
	FHazePlaySequenceData GrabInAir;

	// Grab a platform
	UPROPERTY(Category = "DinoCraneGrab")
	FHazePlaySequenceData Grab;

	// Release a grabbed object
	UPROPERTY(Category = "DinoCraneGrab")
	FHazePlaySequenceData GrabRelease;

	// Grab MH
    UPROPERTY(Category = "DinoCraneGrab")
    FHazePlayBlendSpaceData GrabMoveset;

	// MH animation that'll play wile grabing onto a platform. Should not include any head movement.
    UPROPERTY(Category = "DinoCraneGrab")
    FHazePlaySequenceData MHBodyOnly;

	// Override

	// Idle animation to play when the players first discover the crane
	UPROPERTY(Category = "Override")
	FHazePlaySequenceData Idle;

	// Eat the other player
	UPROPERTY(Category = "Override")
	FHazePlaySequenceData EatPlayer;

	// Eat the other player while riding on the DinoSlammer
	UPROPERTY(Category = "Override")
	FHazePlaySequenceData EatPlayerAndDinoSlammer;

};