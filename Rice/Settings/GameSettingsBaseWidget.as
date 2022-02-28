import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

class UGameSettingsBaseWidget: UHazeUserWidget
{
	private bool bFocused = false;
	private bool bFocusedByMouse = false;
	bool bTickForSoundReset = false;
	float PlaySoundTimer = 0.f;

	UFUNCTION(BlueprintPure)
	bool IsHighlighted()
	{
		return bFocused;
	}

	UFUNCTION(BlueprintPure)
	bool IsFocusedByMouse()
	{
		return bFocusedByMouse;
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent FocusEvent)
	{
		bFocused = true;
		NarrateFull();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent FocusEvent)
	{
		bFocused = false;
		bFocusedByMouse = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bFocusedByMouse = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bFocused && !MouseEvent.CursorDelta.IsZero())
		{
			bFocusedByMouse = true;
			Widget::SetAllPlayerUIFocus(this);
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bTickForSoundReset)
		{
			if(Time::GetRealTimeSince(PlaySoundTimer) >= 0.25f)
			{
				ResetMouseOverRTPC();
			}
		}
	}
	
	void ResetMouseOverRTPC()
	{
		GetAudioManager().MenuWidgetMouseHoverSoundCount --;
		bTickForSoundReset = false;
	}

	// We need to use our own construct functions since we create the widget before loading the profile data
	UFUNCTION()
	void ConstructSettingsWidget() { /* Virutal */ }

	UFUNCTION()
	void ApplyGameSetting() { /* Virutal */ }

	UFUNCTION()
	void ResetGameSetting() { /* Virutal */ }

	UFUNCTION()
	bool HasPendingChanges() { /* Virutal */  return false;}

	UFUNCTION(BlueprintPure)
	FName GetSettingName() { /* Virutal */  return NAME_None;}

	void SetSettingsValue(FString Value) { /* Virtual */}

	FString GetFullNarrationText() { /* Virutal */ return FString();}

	UFUNCTION()
	void NarrateFull() { /* Virutal */ }

	UFUNCTION()
	void NarrateValue() { /* Virutal */ }


}