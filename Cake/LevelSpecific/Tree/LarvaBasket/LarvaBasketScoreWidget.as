import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;

class ULarvaBasketScoreWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	int Score;

	UPROPERTY(BlueprintReadOnly)
	ELarvaBasketScoreType ScoreType;

	UFUNCTION(BlueprintEvent)
	void PlayShowAnimation() {}
}