import Vino.MinigameScore.MinigameStatics;

class UMinigameHighscore : UHazeUserWidget
{
	UPROPERTY()
	TMap<EHighScoreType, FText> HighscoreText;

	EHighScoreType HighScoreType;

	private UFUNCTION(BlueprintEvent)
	void BP_ShowHighScoreVisuals(bool ShouldShow){}

	private UFUNCTION(BlueprintEvent)
	void BP_SetCodyHighScore(FText Text){}

	private UFUNCTION(BlueprintEvent)
	void BP_SetMayHighScore(FText Text){}

	private UFUNCTION(BlueprintEvent)
	void BP_SetHighScoreText(FText String){}

	UFUNCTION()
	void ShowHighScoreVisuals(bool ShouldShow)
	{
		BP_ShowHighScoreVisuals(ShouldShow);
	}

	// void SetCodyHighScore(int Score)
	// {
	// 	FText Text = Text::Conv_IntToText(Score);
	// 	BP_SetCodyHighScore(Text);
	// }

	// void SetMayHighScore(int Score)
	// {
	// 	FText Text = Text::Conv_IntToText(Score);
	// 	BP_SetMayHighScore(Text);
	// }

	void SetCodyHighScore(float Value)
	{	
		// int Minutes = 0.f;
		// int Seconds = 0.f;
		// float Milliseconds = 0.f;

		// float MinutesWithDecimals = Value / 60.f;
		// Minutes = FMath::TruncToInt(MinutesWithDecimals);

		// if (Minutes > 0.f)
		// {
		// 	float Remainder = MinutesWithDecimals - Minutes;
		// 	float GetSecondsMultiplier = Remainder / MinutesWithDecimals;
		// 	Seconds = Value * GetSecondsMultiplier;
		// }
		// else
		// {
		// 	Seconds = FMath::Abs(Value);
		// }
		
		// Milliseconds = Value - FMath::FloorToInt(Value);
		// Milliseconds *= 100;
		// int RoundedMilliseconds = FMath::RoundToInt(Milliseconds);

		// FString StringMilliseconds("" + RoundedMilliseconds / 10);

		// Text::Conv_FloatToText
		// if (HighScoreType == EHighScoreType::TimeElapsed)
		// {

		// }

		// FText::FromString()

		FText Text = Text::Conv_IntToText(Value);
		BP_SetCodyHighScore(Text);
	}

	void SetMayHighScore(float Score)
	{
		FText Text = Text::Conv_IntToText(Score);
		BP_SetMayHighScore(Text);
	}

	// void SetCodyHighScore(FString Score)
	// {
	// 	FText Text = Text::Conv_StringToText(Score);
	// 	BP_SetCodyHighScore(Text);
	// }

	// void SetMayHighScore(FString Score)
	// {
	// 	FText Text = Text::Conv_StringToText(Score);
	// 	BP_SetMayHighScore(Text);
	// }

	UFUNCTION()
	void SetHighScoreText(EHighScoreType ScoreType)
	{
		HighScoreType = ScoreType;
		BP_SetHighScoreText(HighscoreText.FindOrAdd(ScoreType));
	}
}