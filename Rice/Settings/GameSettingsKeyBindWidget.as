import Rice.Settings.GameSettingsBaseWidget;
import Rice.Settings.GameSettingsKeyBindOverlayWidget;

class UGameSettingsKeyBindWidget : UGameSettingsBaseWidget
{
	UPROPERTY()
	TSubclassOf<UGameSettingsKeyBindOverlayWidget> OverlayWidgetClass;

	UPROPERTY(BlueprintReadOnly)
	TArray<FName> Settings;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDisplayName;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText SettingDescription;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText KeyValueDisplay;

	FKey CurrentKey;
	FKey StartingKey;
	bool bIsHardwareKey;

	UGameSettingsKeyBindOverlayWidget OverlayWidget;

	// Hack fix for focus handling when setting value
	bool bBlockNextFullNarration = false;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		// Default settings for the editor so we have visible text when editing
		if (IsDesignTime)
		{
			if (Settings.Num() > 0)
				SettingDisplayName = FText::FromName(Settings[0]);
			else
				SettingDisplayName = FText::FromString("NOT SET!");
			
			KeyValueDisplay = FText::FromString("Key");
			UpdateFields();
		}
	}

	private void SetAsError()
	{
		SettingDisplayName = FText::FromString("Error");
		SettingDescription = FText::FromString("Error");
		KeyValueDisplay = FText::FromString("Error");
		UpdateFields();
	}

	UFUNCTION()
	void ConstructSettingsWidget()
	{
		if (Settings.Num() < 1)
		{
			PrintError("No settings to set!");
			SetAsError();
			return;
		}

		FString Value;
		UHazeGameSettingBase SettingsDescription;
		bool Success = GameSettings::GetGameSettingsDescriptionAndValue(Settings[0], SettingsDescription, Value);
		if (!Success)
		{
			PrintError("Failed to get setting for " + Settings[0].ToString());
			SetAsError();
			return;
		}

		UHazeKeyBindSetting KeyBindDescription = Cast<UHazeKeyBindSetting>(SettingsDescription);
		SettingDisplayName = KeyBindDescription.DisplayName;
		SettingDescription = KeyBindDescription.Description;
		bIsHardwareKey = KeyBindDescription.bIsHardwareKey;

		CurrentKey = KeyBindDescription.GetKeyFromSettingsValue(Value);
		StartingKey = CurrentKey;

		KeyValueDisplay = GameSettings::GetKeyBindingDisplayValue(CurrentKey);

		UpdateFields();
	}

	UFUNCTION()
	void OpenKeyBindOverlay()
	{
		KeyValueDisplay = FText::FromString("");
		UpdateFields();

		OverlayWidget = Cast<UGameSettingsKeyBindOverlayWidget>(Widget::AddFullscreenWidget(OverlayWidgetClass.Get(), EHazeWidgetLayer::Menu));
		OverlayWidget.OnInputSelected.AddUFunction(this, n"OnOverlayFinished");
		Widget::SetAllPlayerUIFocus(OverlayWidget);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{	
		if (Event.Key == EKeys::Enter)
		{
			OpenKeyBindOverlay();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	bool IsKeyOK(FKey Key)
	{
		if (Key.IsGamepadKey())
			return false;
		return Key != EKeys::Escape;
	}

	UFUNCTION()
	void OnOverlayFinished(FKey NewKey)
	{
		Widget::RemoveFullscreenWidget(OverlayWidget);
		OverlayWidget = nullptr;

		if (NewKey.IsValid() && IsKeyOK(NewKey))
		{
			// Check if new key is already in use on another setting
			UGameSettingsKeyBindWidget UsingWidget = nullptr;
			for (auto Sibling : GetParent().GetAllChildren())
			{
				// Skip self
				if (Sibling == this)
					continue;

				auto KeyBindWidget = Cast<UGameSettingsKeyBindWidget>(Sibling);
				if (KeyBindWidget != nullptr)
				{
					if (KeyBindWidget.CurrentKey == NewKey)
					{
						UsingWidget = KeyBindWidget;
						break;
					}
				}
			}

			if (UsingWidget != nullptr)
			{
				// TODO: Show warning and clear other? Just swap them for now as a placeholder
				Log("KEY ALREADY USED!");
				UsingWidget.CurrentKey = CurrentKey;
				UsingWidget.KeyValueDisplay = GameSettings::GetKeyBindingDisplayValue(CurrentKey);
				UsingWidget.UpdateFields();
				CurrentKey = NewKey;
			}
			else
			{
				CurrentKey = NewKey;
			}
		}

		KeyValueDisplay = GameSettings::GetKeyBindingDisplayValue(CurrentKey);
		UpdateFields();

		bBlockNextFullNarration = true;
		NarrateValue();

		// Set focus back to this
		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION(BlueprintEvent)
	void UpdateFields()
	{
		
	}

	FString ScanCodeSetting(FKey Key)
	{
		uint8 ScanCode = GameSettings::KeyBindingScanCodeFromKey(Key);
		return ScanCode != 0x00 ? String::Conv_IntToString(ScanCode) : Key.ToString();
	}

	UFUNCTION()
	void ApplyGameSetting()
	{
		for (FName Setting : Settings)
		{
			FString NewValue = bIsHardwareKey ? ScanCodeSetting(CurrentKey) : CurrentKey.ToString();
			bool Success = GameSettings::SetGameSettingsValue(Setting, NewValue);
			if (!Success)
			{
				PrintError("Failed to apply setting for " + Setting.ToString());
				return;
			}
		}

		StartingKey = CurrentKey;
	}

	UFUNCTION()
	void ResetGameSetting()
	{
		if (Settings.Num() < 1)
		{
			PrintError("No settings to set!");
			SetAsError();
			return;
		}

		for (FName Setting : Settings)
		{
			GameSettings::ResetGameSettingsValue(Setting);
		}

		FString Value;
		bool Success = GameSettings::GetGameSettingsValue(Settings[0], Value);
		if (!Success) {
			PrintError("Failed to get setting for " + Settings[0].ToString());
			return;
		}

		CurrentKey = FKey(FName(Value));
		StartingKey = CurrentKey;
		KeyValueDisplay = GameSettings::GetKeyBindingDisplayValue(CurrentKey);
		UpdateFields();
	}
	
	UFUNCTION()
	bool HasPendingChanges()
	{
		 return StartingKey != CurrentKey;
	}

	FName GetSettingName() override
	{
		return Settings[0];
	}

	FString GetFullNarrationText() override
	{
		return SettingDisplayName.ToString() + ", " + KeyValueDisplay.ToString() + ", " + SettingDescription.ToString();		
	}

	UFUNCTION()
	void NarrateFull()
	{
		if (bBlockNextFullNarration)
		{
			bBlockNextFullNarration = false;
			return;
		}
		Game::NarrateString(GetFullNarrationText());
	}

	UFUNCTION()
	void NarrateValue()
	{
		Game::NarrateText(KeyValueDisplay);
	}

};