import Rice.MessageDialog.MessageDialogData;
import Rice.Mainmenu.MenuPromptOrButton;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

struct FMessageDialogButtons
{
	UPROPERTY()
	UMenuPromptOrButton CancelButton;

	UPROPERTY()
	UMenuPromptOrButton ConfirmButton;
}

class UMessageDialogWidget : UHazeUserWidget
{
	default bIsFocusable = true;

	FOnMessageClosed OnClosed;

	UPROPERTY()
	FMessageDialog Message;

	double AcceptInputTime = 0.0;
	bool bClosed = false;

	void OnMessageUpdated()
	{
		AcceptInputTime = Time::RealTimeSeconds + 0.2;
		Update();
	}

	UFUNCTION(BlueprintEvent)
	void Update() {}

	UFUNCTION()
	void CloseMessage(EMessageDialogResponse Response)
	{
		OnClosed.ExecuteIfBound(Response);	

		if(Message.bPlaySoundOnClosed)
		{
			if(Response == EMessageDialogResponse::Yes || Response == EMessageDialogResponse::None)
				GetAudioManager().UI_OnSelectionConfirmed();
			else if(Response == EMessageDialogResponse::No)
				GetAudioManager().UI_OnSelectionCancel();
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (Time::RealTimeSeconds >= AcceptInputTime)
		{
			if (Event.Key == EKeys::Virtual_Accept
				|| Event.Key == EKeys::Enter)
			{
				if (Message.Type == EMessageDialogType::YesNo)
					CloseMessage(EMessageDialogResponse::Yes);
				else
					CloseMessage(EMessageDialogResponse::None);
				return FEventReply::Handled();
			}
			else if (Event.Key == EKeys::Virtual_Back
				|| Event.Key == EKeys::Escape)
			{
				if (Message.Type == EMessageDialogType::YesNo)
				{
						CloseMessage(EMessageDialogResponse::No);
					return FEventReply::Handled();
				}
			}
		}

		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintEvent)
	FMessageDialogButtons GetButtonsForNarration()
	{
		return FMessageDialogButtons();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		// Make sure everyone is focusing this widget
		if (!bClosed)
			Widget::SetAllPlayerUIFocusBeneathParent(this);
	}
};