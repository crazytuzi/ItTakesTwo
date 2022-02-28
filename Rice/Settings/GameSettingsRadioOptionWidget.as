import Rice.Settings.GameSettingsBaseWidget;
import Rice.PauseMenu.PauseMenuSingleton;

class UGameSettingsRadioOptionsGroup : UObject
{
	UFUNCTION()
	bool IsOptionValid(FName Setting, FString Value, int Index) { /* VIRTUAL */  return true; }
	UFUNCTION()
	void ApplyChanges(UGameSettingsRadioOptionWidget Widget) { /* VIRTUAL */  }
}

class UGameSettingsRadioOptionWidget : UGameSettingsBaseWidget
{
	default bCustomNavigation = true;

	UPROPERTY(BlueprintReadOnly)
	FName Setting;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDisplayName;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDescription;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingCurrentOption;

	TArray<FHazeGameSettingOption> Options;
	int32 CurrentIndex = 0;
	int32 StartingIndex = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bShowTutorialIndication = false;
	bool bInvalidSetting = false;
	
	private UGameSettingsRadioOptionsGroup RadioOptionsGroup;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		// Default settings for the editor so we have visible text when editing
		if (IsDesignTime)
		{
			SettingDisplayName = FText::FromName(Setting);
			SettingCurrentOption = FText::FromString("Default");
			UpdateFields();
		}
	}

	UFUNCTION(BlueprintPure)
	FString GetSelectedValue()
	{
		if (Options.IsValidIndex(CurrentIndex))
			return Options[CurrentIndex].Value;
		return "";
	}

	UFUNCTION(BlueprintCallable)
	void SetSettingsValue(FString Value) override
	{
		for (int i = 0 ; i < Options.Num() ; i++)
		{
			if (Options[i].Value == Value)
			{
				CurrentIndex = i;
				SettingCurrentOption = Options[CurrentIndex].Name;
				UpdateFields();
				break;
			}
		}
	}

	UFUNCTION()
	void ConstructSettingsWidget()
	{
		FString Value;
		UHazeGameSettingBase SettingsDescription;
		bool Success = GameSettings::GetGameSettingsDescriptionAndValue(Setting, SettingsDescription, Value);
		if (!Success)
		{
			SettingDisplayName = FText::FromString("Error");
			SettingDescription = FText::FromString("Error");
			SettingCurrentOption = FText::FromString("Error");
			UpdateFields();
			SetVisibility(ESlateVisibility::Collapsed);
			bInvalidSetting = true;
			return;
		}

		SettingDisplayName = SettingsDescription.DisplayName;
		SettingDescription = SettingsDescription.Description;

		Options = SettingsDescription.Options;
		CurrentIndex = -1;
		for (int i = 0 ; i < Options.Num() ; i++)
		{
			if (Options[i].Value == Value)
			{
				CurrentIndex = i;
				break;
			}
		}

		if (!Options.IsValidIndex(CurrentIndex))
		{
			Log("Bad initial setting");
			CurrentIndex = 0;
		}

		StartingIndex = CurrentIndex;

		SettingCurrentOption = Options[CurrentIndex].Name;

		UPauseMenuSingleton PauseMenuSingleton = UPauseMenuSingleton::Get();
		if (PauseMenuSingleton.OptionsMenuSelectedSlot == Setting)
			bShowTutorialIndication = true;

		UpdateFields();
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
				SwitchOptionsLeft();

				OutRule = EUINavigationRule::Stop;
				return nullptr;
			}
			else if (Event.NavigationType == EUINavigation::Right)
			{
				SwitchOptionsRight();

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
	void UpdateFields()
	{
		
	}

	int GetVisualIndex() const
	{
		if (Options.IsValidIndex(CurrentIndex))
		{
			if (Options[CurrentIndex].DisplayType == EHazeGameSettingsDisplayType::HiddenReplacesLeft)
				return CurrentIndex - 1;
			if (Options[CurrentIndex].DisplayType == EHazeGameSettingsDisplayType::HiddenReplacesRight)
				return CurrentIndex + 1;
		}
		return CurrentIndex;
	}

	void ApplyChangeToGroup()
	{
		if (RadioOptionsGroup == nullptr)
			return;

		RadioOptionsGroup.ApplyChanges(this);
	}

	UFUNCTION()
	void SetOptionsGroup(UGameSettingsRadioOptionsGroup OptionsGroup)
	{
		RadioOptionsGroup = OptionsGroup;
	}

	UFUNCTION(BlueprintEvent)
	bool IsOptionValid(FString Value, int Index)
	{
		bool bValid = true;
		if (RadioOptionsGroup != nullptr)
			bValid = RadioOptionsGroup.IsOptionValid(Setting, Value, Index);

		return bValid;
	}

	UFUNCTION(BlueprintPure)
	bool CanSwitchLeft()
	{
		int CheckIndex = GetVisualIndex();
		if (CheckIndex <= 0)
			return false;

		// Find first non-hidden option
		for (int i = CheckIndex - 1; i >= 0; i--)
		{
			if (Options[i].DisplayType != EHazeGameSettingsDisplayType::Default)
				continue;
			if (!IsOptionValid(Options[i].Value, i))
				continue;

			return true;
		}

		return false;
	}

	UFUNCTION()
	void SwitchOptionsLeft()
	{
		if (Options.Num() == 0)
			return;

		if(!CanSwitchLeft())
			return;

		GetAudioManager().UI_OptionsMenuRadioButtonUpdate();			

		// Find first non-hidden option
		for (int i = CurrentIndex - 1; i >= 0; i--)
		{
			if (Options[i].DisplayType != EHazeGameSettingsDisplayType::Default)
				continue;
			if (!IsOptionValid(Options[i].Value, i))
				continue;
			CurrentIndex = i;
			break;
		}
		SettingCurrentOption = Options[CurrentIndex].Name;

		UpdateFields();
		ApplyChangeToGroup();
		NarrateValue();
	}

	UFUNCTION(BlueprintPure)
	bool CanSwitchRight()
	{
		int CheckIndex = GetVisualIndex();
		if (Options.Num() == 0)
			return false;
		if (CheckIndex >= Options.Num() - 1)
			return false;

		// Find first non-hidden option
		for (int i = CheckIndex + 1; i < Options.Num(); i++)
		{
			if (Options[i].DisplayType != EHazeGameSettingsDisplayType::Default)
				continue;
			if (!IsOptionValid(Options[i].Value, i))
				continue;
				
			return true;
		}

		return false;
	}

	UFUNCTION()
	void SwitchOptionsRight()
	{
		if (Options.Num() == 0)
			return;

		if(!CanSwitchRight())
			return;
		
		GetAudioManager().UI_OptionsMenuRadioButtonUpdate();

		// Find first non-hidden option
		for (int i = CurrentIndex + 1; i < Options.Num(); i++)
		{
			if (Options[i].DisplayType != EHazeGameSettingsDisplayType::Default)
				continue;
			if (!IsOptionValid(Options[i].Value, i))
				continue;

			CurrentIndex = i;
			break;
		}
		SettingCurrentOption = Options[CurrentIndex].Name;

		UpdateFields();
		ApplyChangeToGroup();
		NarrateValue();
	}

	UFUNCTION()
	void ApplyGameSetting()
	{
		if (bInvalidSetting)
			return;

		if (Options.IsValidIndex(CurrentIndex) && Options[CurrentIndex].DisplayType == EHazeGameSettingsDisplayType::Default)
			bShowTutorialIndication = false;

		bool Success = Options.IsValidIndex(CurrentIndex) && GameSettings::SetGameSettingsValue(Setting, Options[CurrentIndex].Value);
		if (!Success)
		{
			PrintError("Failed to apply setting for " + Setting.ToString());
			return;
		}
		StartingIndex = CurrentIndex;
	}

	UFUNCTION()
	void ResetGameSetting()
	{
		if (bInvalidSetting)
			return;

		GameSettings::ResetGameSettingsValue(Setting);

		FString Value;
		bool Success = GameSettings::GetGameSettingsValue(Setting, Value);
		if (!Success) {
			PrintError("Failed to get setting for " + Setting.ToString());
			return;
		}

		CurrentIndex = -1;
		for (int i = 0 ; i < Options.Num() ; i++)
		{
			if (Options[i].Value == Value)
			{
				CurrentIndex = i;
				break;
			}
		}
		StartingIndex = CurrentIndex;
		SettingCurrentOption = Options[CurrentIndex].Name;
		UpdateFields();
	}

	UFUNCTION()
	bool HasPendingChanges()
	{
		return CurrentIndex != StartingIndex;
	}

	FName GetSettingName() override
	{
		return Setting;
	}

	FString GetFullNarrationText() override
	{
		return SettingDisplayName.ToString() + ", " + SettingCurrentOption.ToString() + ", " + SettingDescription.ToString();
	}

	UFUNCTION()
	void NarrateFull()
	{
		Game::NarrateString(GetFullNarrationText());
	}

	UFUNCTION()
	void NarrateValue()
	{
		Game::NarrateText(SettingCurrentOption);
	}
	
};