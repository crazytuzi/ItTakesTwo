class USnowfolkFetchQuestNPCFeature : UHazeLocomotionFeatureBase
{
    USnowfolkFetchQuestNPCFeature()
    {
        Tag = n"FetchQuest";
    }

	UPROPERTY()
    FHazePlaySequenceData IdleMH;

	UPROPERTY()
    FHazePlaySequenceData SignMH;

	UPROPERTY()
    FHazePlaySequenceData BasketMH;

	UPROPERTY()
	FHazePlaySequenceData ItemMH;

	UPROPERTY()
	FHazePlaySequenceData CelebrateStart;

	UPROPERTY()
    FHazePlaySequenceData CelebrateMH;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData IdleToSign;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData IdleToItem;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData IdleToBasket;
	
	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData SignToIdle;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData SignToBasket;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData SignToItem;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData ItemToIdle;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData ItemToSign;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData ItemToBasket;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData BasketToIdle;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData BasketToSign;

	UPROPERTY(Category = "Transitions")
	FHazePlaySequenceData BasketToItem;

	UPROPERTY(Category = "Extra")
	FHazePlaySequenceData SnowBallHit;

	UPROPERTY(Category = "Extra")
	FHazePlaySequenceData AdditiveSquash;
}