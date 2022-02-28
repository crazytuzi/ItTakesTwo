class ULocomotionFeatureMinigameChessPlayer : UHazeLocomotionFeatureBase
{
	default Tag = n"Chess";

	UPROPERTY(EditDefaultsOnly)
    FHazePlaySequenceData Idle;
	default Idle.bLoop = true;
	
	UPROPERTY(EditDefaultsOnly)
    FHazePlaySequenceData MakeAction;

	UPROPERTY(EditDefaultsOnly)
    FHazePlaySequenceData TookeAPiece;
	default TookeAPiece.bLoop = true;
};

