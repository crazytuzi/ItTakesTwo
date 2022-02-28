import Peanuts.Animation.Features.LocomotionFeatureMiniGamePostState;

enum EPlayerMinigameReactionState
{
	Inactive,
	Active
}

enum EMinigameAnimationPlayerState
{
	WinnerAnim,
	LoserAnim
}

event void FOnMinigameReactionAnimationComplete(AHazePlayerCharacter Player);

class UPlayerMinigameComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	EPlayerMinigameReactionState PlayerMinigameReactionState;

	EMinigameAnimationPlayerState MinigameAnimationPlayerState;

	FHazeRequestLocomotionData AnimRequest;
	default AnimRequest.AnimationTag = n"MiniGame";
	
	UPROPERTY(Category = "Events")
	FOnMinigameReactionAnimationComplete OnMinigameReactionAnimationComplete; 

	UPROPERTY(Category = "Setup")
	TPerPlayer<ULocomotionFeatureMiniGamePostState> LocoReaction;
	
	ULocomotionFeatureMiniGamePostState LocoData;
	
	int PlayIndex;

	bool bMinigameActive;

	UFUNCTION()
	void SetReactionState(EPlayerMinigameReactionState State)
	{
		PlayerMinigameReactionState = State;
	}

	UFUNCTION()
	void SetAnimationWinnerState(EMinigameAnimationPlayerState State)
	{
		MinigameAnimationPlayerState = State;
	}

	UFUNCTION()
	int GetIndex()
	{
		return PlayIndex;
	}

	UFUNCTION()
	void SetAnimIndex(int InputPlayerIndex)
	{
		PlayIndex = InputPlayerIndex;
	}
}