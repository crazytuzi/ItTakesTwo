import Rice.Settings.GameSettingsBaseWidget;

struct FOptionsTabNarrationText
{
	UPROPERTY()
	FText LeftStick;

	UPROPERTY()
	FText LeftStickButton;

	UPROPERTY()
	FText RightStick;

	UPROPERTY()
	FText RightStickButton;

	UPROPERTY()
	FText FaceUp;

	UPROPERTY()
	FText FaceRight;

	UPROPERTY()
	FText FaceDown;

	UPROPERTY()
	FText FaceLeft;

	UPROPERTY()
	FText RightShoulder;

	UPROPERTY()
	FText Triggers;
}

class UOptionsTabWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	FText TabDisplayName;

	bool bIsBlacklisted = false;

	UFUNCTION(BlueprintEvent)
	UScrollBox GetSettingsScrollBox() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	FOptionsTabNarrationText GetTextsForNarration()
	{
		return FOptionsTabNarrationText();
	}

	UFUNCTION()
	TArray<UGameSettingsBaseWidget> GetTabSettings()
	{
		if (bIsBlacklisted)
			return TArray<UGameSettingsBaseWidget>();

		UScrollBox ScrollBox = SettingsScrollBox;
		if (ScrollBox == nullptr)
			return TArray<UGameSettingsBaseWidget>();

		TArray<UGameSettingsBaseWidget> Result;
		for (UWidget ScrollBoxWidget : ScrollBox.GetAllChildren())
		{
			if (ScrollBoxWidget.IsA(UGameSettingsBaseWidget::StaticClass())
				&& ScrollBoxWidget.IsVisible())
			{
				Result.Add(Cast<UGameSettingsBaseWidget>(ScrollBoxWidget));
			}
		}
		
		return Result;
	}
}