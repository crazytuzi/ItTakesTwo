import Rice.Settings.GameSettingsBaseWidget;

class UBootOptionsPage : UHazeUserWidget
{
	UPROPERTY()
	bool bIsPrivacyOptions = false;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeUserWidget SplashWidget;

	TArray<UGameSettingsBaseWidget> AllSettings;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TArray<UWidget> ChildWidgets;
		GetAllChildWidgetsOfClass(UGameSettingsBaseWidget::StaticClass(), ChildWidgets);

		for (UWidget Child : ChildWidgets)
		{
			auto Setting = Cast<UGameSettingsBaseWidget>(Child);
			if (Setting != nullptr)
				AllSettings.Add(Setting);
		}

		for (auto Setting : AllSettings)
			Setting.ConstructSettingsWidget();
	}

	UFUNCTION(BlueprintEvent)
	UWidget BP_GetInitialFocus()
	{
		for (auto Setting : AllSettings)
		{
			if (Setting.GetVisibility() == ESlateVisibility::Collapsed)
				continue;
			return Setting;
		}
		return this;
	}

	void Apply()
	{
		for (auto Setting : AllSettings)
			Setting.ApplyGameSetting();
	}

	UFUNCTION(BlueprintEvent)
	FText GetPageDisplayName()
	{
		return FText();
	}
};