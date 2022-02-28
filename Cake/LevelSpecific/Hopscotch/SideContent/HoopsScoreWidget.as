import Cake.LevelSpecific.Hopscotch.SideContent.HoopsSettings;

class UHoopsScoreWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	int Score;

	UPROPERTY(BlueprintReadOnly)
	EHoopsScoreType ScoreType;

	UFUNCTION(BlueprintEvent)
	void PlayShowAnimation() {}
}