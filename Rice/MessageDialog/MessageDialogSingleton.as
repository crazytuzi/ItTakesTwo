import Rice.MessageDialog.MessageDialogWidget;
import Rice.MessageDialog.MessageDialogData;

class UMessageDialogSingleton : UObjectTickable
{
	default WorldContext = Outer;

	UPROPERTY()
	TSubclassOf<UMessageDialogWidget> DialogWidgetClass;

	int NextMessageId = 1;
	TArray<FMessageDialog> Messages;
	UMessageDialogWidget Widget;

	private bool bNarrateNextTick = false;

	void AddMessage(FMessageDialog Message)
	{
		Messages.Add(Message);
		Messages[Messages.Num() - 1].MessageId = NextMessageId++;
		Update();
	}

	UFUNCTION()
	void ConfirmMessage(EMessageDialogResponse Response)
	{
		Messages[0].OnClosed.ExecuteIfBound(Response);
		Messages.RemoveAt(0);
		Update();
		

		if (Messages.Num() > 0)
			bNarrateNextTick = true;
	}

	void ForceClose(FOnMessageClosed Delegate)
	{
		for (int i = 0, Count = Messages.Num(); i < Count; ++i)
		{
			if (Messages[i].OnClosed.UObject == Delegate.UObject
				&& Messages[i].OnClosed.FunctionName == Delegate.FunctionName)
			{
				Messages.RemoveAt(i);
				Update();
				break;
			}
		}
	}

	void UpdateText(FOnMessageClosed Delegate, FText NewText)
	{
		for (int i = 0, Count = Messages.Num(); i < Count; ++i)
		{
			if (Messages[i].OnClosed.UObject == Delegate.UObject
				&& Messages[i].OnClosed.FunctionName == Delegate.FunctionName)
			{
				Messages[i].MessageId = NextMessageId++;
				Messages[i].Message = NewText;
				Update();
				break;
			}
		}
	}

	void Update()
	{
		if (Messages.Num() == 0)
		{
			// No more messages, remove widget
			if (Widget != nullptr)
			{
				if (Widget.HasFocusedDescendants())
					Widget::ClearAllPlayerUIFocus();
				Widget.bClosed = true;
				Widget::RemoveFullscreenWidget(Widget);
				Widget = nullptr;
			}
		}
		else
		{
			// Create widget to show messages
			if (Widget == nullptr)
			{
				Widget = Cast<UMessageDialogWidget>(Widget::AddFullscreenWidget(DialogWidgetClass, EHazeWidgetLayer::Menu));
				Widget.OnClosed.BindUFunction(this, n"ConfirmMessage");
				Widget.SetWidgetPersistent(true);
				Widget.SetWidgetZOrderInLayer(1000);

				Widget::SetAllPlayerUIFocus(Widget);

				bNarrateNextTick = true;
			}

			// Update message shown by widget
			if (Widget.Message.MessageId != Messages[0].MessageId)
			{
				Widget.Message = Messages[0];
				Widget.OnMessageUpdated();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Poll for errors from the online subsystem
		FText OnlineError;
		if (Online::ConsumeLastError(OnlineError))
		{
			FMessageDialog Message;
			Message.Message = OnlineError;
			Message.bPlaySoundOnClosed = true;
			AddMessage(Message);
			GetAudioManager().UI_PopupMessageOpen();
		}

		// Poll for questions from the online subsystem
		FHazeOnlineQuestion Question;
		if (Online::ConsumeQuestion(Question))
		{
			FMessageDialog Dialog;
			Dialog.Message = Question.Message;
			Dialog.Type = EMessageDialogType::YesNo;
			Dialog.OnClosed.BindUFunction(this, n"OnOnlineQuestionAnswered");
			Dialog.ConfirmText = Question.YesText;
			Dialog.CancelText = Question.NoText;
			AddMessage(Dialog);
			GetAudioManager().UI_PopupMessageOpen();			
		}

		// If a message widget is up it will *always* have focus
		if (Widget != nullptr && Widget.bIsAdded)
			Widget::SetAllPlayerUIFocusBeneathParent(Widget);

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			if (Messages.Num() > 0 && Widget != nullptr && Game::IsNarrationEnabled())
			{
				FString NarrateString = Messages[0].Title.ToString() + ", " + Messages[0].Message.ToString() + ", ";

				FMessageDialogButtons Buttons = Widget.GetButtonsForNarration();

				FString ButtonNarration;
				if (Buttons.CancelButton.MakeNarrationString(ButtonNarration))
					NarrateString += ButtonNarration + ", ";

				if (Buttons.ConfirmButton.MakeNarrationString(ButtonNarration))
					NarrateString += ButtonNarration + ", ";

				Game::NarrateString(NarrateString);
			}
		}
	}

	UFUNCTION()
	private void OnOnlineQuestionAnswered(EMessageDialogResponse Response)
	{
		Online::AnswerQuestion(Response == EMessageDialogResponse::Yes);
	}
};

namespace UMessageDialogSingleton
{
	UMessageDialogSingleton Get()
	{
		return Cast<UMessageDialogSingleton>(Game::GetSingleton(UMessageDialogSingleton::StaticClass()));
	}
};