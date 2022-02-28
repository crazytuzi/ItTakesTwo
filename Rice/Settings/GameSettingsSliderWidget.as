import Rice.Settings.GameSettingsBaseWidget;

class UGameSettingsSliderWidget : UGameSettingsBaseWidget
{
	default bCustomNavigation = true;

	UPROPERTY(BlueprintReadOnly)
	FName Setting;

	UPROPERTY(BlueprintReadOnly)
	bool bAutoApply = false;

	UPROPERTY(BlueprintReadOnly)
	float StepSize = 1.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDisplayName;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDescription;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	float SettingSliderValue;
	float StartSliderValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SettingSliderMinValue;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SettingSliderMaxValue;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	FText SettingSliderValueText;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (IsDesignTime)
		{
			SettingDisplayName = FText::FromName(Setting);
			
			SettingSliderValue = 50;
			SettingSliderMinValue = 0;
			SettingSliderMaxValue = 100;

			UpdateSliderDefaults();
			UpdateFields();
		}
	}

	UFUNCTION()
	void ConstructSettingsWidget()
	{
		float Value = 0;
		UHazeGameSettingBase SettingsDescription;
		bool DescriptionSuccess = GameSettings::GetGameSettingsDescription(Setting, SettingsDescription);
		bool ValueSuccess = GameSettings::GetGameSettingsValueAsNumber(Setting, Value);
		if (!DescriptionSuccess  || !ValueSuccess)
		{
			PrintError("Failed to get setting for " + Setting.ToString());
			SettingDisplayName = FText::FromString("Error");
			SettingDescription = FText::FromString("Error");
			UpdateSliderDefaults();
			UpdateFields();
			return;
		}

		if (ValueSuccess && DescriptionSuccess)
		{
			UHazeNumberSetting NumberDescription = Cast<UHazeNumberSetting>(SettingsDescription);

			SettingSliderValue = Value;
			StartSliderValue = Value;
			SettingSliderMinValue = NumberDescription.MinValue;
			SettingSliderMaxValue = NumberDescription.MaxValue;

			SettingDisplayName = SettingsDescription.DisplayName;
			SettingDescription = SettingsDescription.Description;

			UpdateSliderDefaults();
			UpdateFields();
		}
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		// We respond to navigation here,
		// so analog stick can be used as well as dpad or keyboard.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.

		if (IsHighlighted())
		{
			if (Event.NavigationType == EUINavigation::Left)
			{
				float NewValue = SettingSliderValue - StepSize;
				if (SettingSliderValue > SettingSliderMinValue)
					GetAudioManager().UI_OptionsMenuSliderUpdate();

				SettingSliderValue = FMath::Max(NewValue, SettingSliderMinValue);
				UpdateFields();

				OutRule = EUINavigationRule::Stop;
				return nullptr;
			}
			else if (Event.NavigationType == EUINavigation::Right)
			{
				float NewValue = SettingSliderValue + StepSize;
				if(SettingSliderValue < SettingSliderMaxValue)
					GetAudioManager().UI_OptionsMenuSliderUpdate();

				SettingSliderValue = FMath::Min(NewValue, SettingSliderMaxValue);
				UpdateFields();

				OutRule = EUINavigationRule::Stop;
				return nullptr;
			}
		}

		OutRule = EUINavigationRule::Escape;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{	
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{	
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintEvent)
	void UpdateSliderDefaults()
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void UpdateFields()
	{
		
	}

	UFUNCTION()
	void ApplyGameSetting()
	{
		FString StringValue = "" + SettingSliderValue;
		bool Success = GameSettings::SetGameSettingsValue(Setting, StringValue);
		if (!Success)
		{
			Log("ApplySliderValue Failed");
		}
		StartSliderValue = SettingSliderValue;
	}

	UFUNCTION()
	void ResetGameSetting()
	{
		GameSettings::ResetGameSettingsValue(Setting);

		float Value = 0;
		bool Success = GameSettings::GetGameSettingsValueAsNumber(Setting, Value);
		if (!Success)
		{
			PrintError("Failed to get setting for " + Setting.ToString());
			return;
		}

		SettingSliderValue = Value;
		StartSliderValue = SettingSliderValue;

		UpdateFields();
	}

	UFUNCTION()
	bool HasPendingChanges()
	{
		 return StartSliderValue != SettingSliderValue;
	}

	FName GetSettingName() override
	{
		return Setting;
	}

	FString GetFullNarrationText() override
	{
		return SettingDisplayName.ToString() + ", " + SettingSliderValueText.ToString() + ", " + SettingDescription.ToString();
	}

	UFUNCTION()
	void NarrateFull()
	{
		Game::NarrateString(GetFullNarrationText());
	}

	UFUNCTION()
	void NarrateValue()
	{
		Game::NarrateText(SettingSliderValueText);
	}

	UFUNCTION(BlueprintPure)
	bool IsSmallRange()
	{
		return false;
	}

	UFUNCTION(BlueprintCallable)
	void PlayOnSliderArrowClicked()
	{
		GetAudioManager().UI_OptionsMenuSliderUpdate();
	}

};