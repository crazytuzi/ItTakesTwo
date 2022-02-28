class ULocomotionFeatureClockWorkHorseDerby : UHazeLocomotionFeatureBase
{

    default Tag = n"HorseDerby";

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Trot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Run;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData JumpLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData CrouchEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData Crouch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData CrouchExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReaction;

}