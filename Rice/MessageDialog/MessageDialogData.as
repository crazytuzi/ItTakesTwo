
delegate void FOnMessageClosed(EMessageDialogResponse Response);

enum EMessageDialogResponse
{
	None,
	Yes,
	No,
};

enum EMessageDialogType
{
	Message,
	YesNo,
};

struct FMessageDialog
{
	UPROPERTY()
	FText Title;
	UPROPERTY()
	FText Message;
	UPROPERTY()
	FOnMessageClosed OnClosed;
	UPROPERTY()
	EMessageDialogType Type = EMessageDialogType::Message;
	UPROPERTY(AdvancedDisplay)
	FText ConfirmText = NSLOCTEXT("MessageDialog", "ConfirmResponse", "OK");
	UPROPERTY(AdvancedDisplay)
	FText CancelText = NSLOCTEXT("MessageDialog", "CancelResponse", "Cancel");
	UPROPERTY()
	bool bPlaySoundOnClosed = false;

	int MessageId = -1;
};