

class UValveTurnInteractionLocomotionFeature : UHazeLocomotionFeatureBase
{
	UValveTurnInteractionLocomotionFeature()
    {
        Tag = n"ValveTurn";
    }

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData IdleAnimation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData TurnAnimation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData TurnAnimationBwd;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleEnterLeft;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleEnterRight;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleLeft;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleRight;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleLeftMh;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FHazePlaySequenceData StruggleRightMh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    FHazePlaySequenceData ValveAdditive;

}