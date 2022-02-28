import Rice.Settings.GameSettingsRadioOptionWidget;


class UGameSettingsRadioOptionsAudioGroup : UGameSettingsRadioOptionsGroup
{
	private TArray<UGameSettingsRadioOptionWidget> Widgets;

	UFUNCTION()
	void SetWidgets(TArray<UGameSettingsRadioOptionWidget> ConnectedWidgets)
	{
		//Reset
		if (Widgets.Num() > 0)
		{
			for (UGameSettingsRadioOptionWidget& Widget: Widgets)
			{
				Widget.SetOptionsGroup(nullptr);
			}
		}

		Widgets = ConnectedWidgets;

		if (Widgets.Num() > 0)
		{
			for (UGameSettingsRadioOptionWidget& Widget: Widgets)
			{
				Widget.SetOptionsGroup(this);
			}
		}
	}

	UFUNCTION()
	bool IsOptionValid(FName Setting, FString Value, int Index)
	{ 
		if (Setting == n"AudioDynamicRange")
		{
			//Find speaker type
			int CurrentSpeakerTypeIndex = 0;
			for (UGameSettingsRadioOptionWidget& Widget: Widgets)
			{
				if (Widget.Setting != n"AudioSpeakerType")
					continue;

					CurrentSpeakerTypeIndex = Widget.CurrentIndex;
					break;
			}
			
			EHazeAudioSpeakerType SpeakerType = EHazeAudioSpeakerType(CurrentSpeakerTypeIndex);
			// It's inverted
			EHazeAudioDynamicRange EnumValue = EHazeAudioDynamicRange(EHazeAudioDynamicRange::EHazeAudioDynamicRange_MAX - 1 - Index);
			return EnumValue == GetAudioManager().GetValidDynamicRangeBasedOnSpeakerType(SpeakerType, EnumValue);
		}

		return true; 
	}

	UFUNCTION()
	void ApplyChanges(UGameSettingsRadioOptionWidget ChangedWidget) 
	{ 
		if (ChangedWidget.Setting != n"AudioSpeakerType")
			return;

		for (UGameSettingsRadioOptionWidget& Widget: Widgets)
		{
			if (Widget.Setting != n"AudioDynamicRange")
				continue;

			if (!Widget.IsOptionValid(Widget.GetSelectedValue(), Widget.CurrentIndex))
			{
				if (Widget.CanSwitchRight())
					Widget.SwitchOptionsRight();
				else
					Widget.SwitchOptionsLeft();

				Widget.UpdateFields();
			}

			break;
		}
	}
}