import Cake.DebugMenus.Audio.AudioDebugStatics;

event void FDebugButtonClicked(UAudioDebugMenuButton Button);

class UAudioDebugMenuButton : UHazeUserWidget
{
	UPROPERTY()
	EAudioDebugMode DebugMode;
	private bool bIsDebugEnabled = false;

	FDebugButtonClicked ClickedEvent;

	void Setup(FDebugButtonClicked ParentClickedEvent) 
	{
		ClickedEvent = ParentClickedEvent;
		Button.OnPressed.AddUFunction(this, n"OnButtonClicked");
		bIsDebugEnabled = true;
		SetDebugEnabled(false);
	}

	UFUNCTION()
	void OnButtonClicked()
	{
		if (ClickedEvent.IsBound())
			ClickedEvent.Broadcast(this);
	}

	void SetDebugEnabled(bool Enabled)
	{
		if (bIsDebugEnabled == Enabled)
			return;

		bIsDebugEnabled = Enabled;

		FSlateColor SlateColor;
		SlateColor.SpecifiedColor = Enabled ? FLinearColor::Green : FLinearColor::Red;
		SlateColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		Text.SetColorAndOpacity(SlateColor);
	}

	bool IsDebugEnabled()
	{
		return bIsDebugEnabled;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeo, FFocusEvent InFocusEvent)
	{
		SetFocus();
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintEvent)
	UHazeDevButton GetButton() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetText() property
	{
		return nullptr;
	}
}	