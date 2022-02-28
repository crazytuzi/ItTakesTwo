import Rice.MessageDialog.MessageDialogSingleton;

UFUNCTION(Category = "Message Dialog")
void ShowPopupMessage(FMessageDialog Message)
{
	auto Dialogs = UMessageDialogSingleton::Get();
	Dialogs.AddMessage(Message);
}

UFUNCTION(Category = "Message Dialog")
bool IsMessageDialogShown()
{
	auto Dialogs = UMessageDialogSingleton::Get();
	return Dialogs.Messages.Num() != 0;
}

UFUNCTION(Category = "Message Dialog")
void ForceClosePopupMessage(FOnMessageClosed Delegate)
{
	auto Dialogs = UMessageDialogSingleton::Get();
	Dialogs.ForceClose(Delegate);
}

UFUNCTION(Category = "Message Dialog")
void UpdatePopupMessageText(FOnMessageClosed Delegate, FText NewMessage)
{
	auto Dialogs = UMessageDialogSingleton::Get();
	Dialogs.UpdateText(Delegate, NewMessage);
}