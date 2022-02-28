import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;

UCLASS(Abstract)
class UMinigameChessPieceAnimInstance : UHazeCharacterAnimInstance
{
	AMinigameChessPieceBase ChessPieceOwner;

	UPROPERTY(BlueprintReadOnly)
	FHazePlaySequenceData CurrentAnimation;

	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
	    ChessPieceOwner = Cast<AMinigameChessPieceBase>(OwningActor);
		if(ChessPieceOwner == nullptr)
			return;	
    }
    
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (ChessPieceOwner == nullptr)
            return;

		const EMinigameChessPieceState State = ChessPieceOwner.GetAnimationState();
		if(State == EMinigameChessPieceState::Preview
			|| State == EMinigameChessPieceState::PreviewAttack)
		{
			CurrentAnimation = ChessPieceOwner.PreviewMoveMH;
		}
		else if(State == EMinigameChessPieceState::PieceMovingToTile
			|| State == EMinigameChessPieceState::PieceLandOnEmptyTile
			|| State == EMinigameChessPieceState::PieceLandOnOtherPiece)
		{
			CurrentAnimation = ChessPieceOwner.MoveToTarget;
		}
		else
		{
			CurrentAnimation = ChessPieceOwner.IdleMH;
		}
    }
}
